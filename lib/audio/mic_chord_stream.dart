import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'chord_detector.dart';
import 'chroma.dart';
import 'progression_tracker.dart';

/// Captures the phone's microphone and emits confirmed chord names as they
/// are recognized, mirroring the host-side pipeline in
/// `apps/guitar_tuner/halo_music.py` (rolling chord-length buffer ->
/// `computeChroma` -> `detectChord` -> `ProgressionTracker`).
class MicChordStream {
  static const int sampleRate = 16000;
  // ~0.35s window (sampleRate * 0.35), matching `chord_len` in
  // halo_music.py for low-note frequency resolution.
  static const int _windowSamples = 5600;

  final AudioRecorder _recorder = AudioRecorder();
  final ProgressionTracker _tracker = ProgressionTracker();

  StreamSubscription<Uint8List>? _sub;
  StreamController<String?>? _controller;
  final List<double> _buffer = [];

  /// Confirmed chord names (or `null` while silent/unstable), one event per
  /// analysis window. Mirrors `ProgressionTracker.current` after each
  /// `update()`.
  Stream<String?> get chordStream =>
      _controller?.stream ?? const Stream.empty();

  /// The full confirmed-chord history so far.
  List<String> get history => _tracker.history;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Start capturing audio and analyzing it for chords.
  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission was not granted');
    }

    _tracker.reset();
    _buffer.clear();
    _controller = StreamController<String?>.broadcast();

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
    ));

    _sub = stream.listen(_onAudioChunk);
  }

  void _onAudioChunk(Uint8List chunk) {
    final samples = Int16List.view(
      chunk.buffer,
      chunk.offsetInBytes,
      chunk.length ~/ 2,
    );
    for (final s in samples) {
      _buffer.add(s / 32768.0);
    }

    while (_buffer.length >= _windowSamples) {
      final window = _buffer.sublist(_buffer.length - _windowSamples);
      _analyzeWindow(window);
      // Slide by half a window so chord changes are detected promptly
      // without re-running the FFT on every single sample.
      final drop = _windowSamples ~/ 2;
      _buffer.removeRange(0, drop);
    }
  }

  void _analyzeWindow(List<double> window) {
    final chroma = computeChroma(window, sampleRate.toDouble());
    final reading = chroma == null ? null : detectChord(chroma);
    _tracker.update(reading?.name);
    _controller?.add(_tracker.current);
  }

  /// Stop capturing audio and release the microphone.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _recorder.stop();
    await _controller?.close();
    _controller = null;
  }

  void dispose() {
    _recorder.dispose();
  }
}

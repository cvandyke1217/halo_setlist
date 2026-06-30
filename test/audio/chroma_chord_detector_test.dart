import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:halo_setlist/audio/chord_detector.dart';
import 'package:halo_setlist/audio/chord_templates.dart';
import 'package:halo_setlist/audio/chroma.dart';

const double _sampleRate = 8000;

double _noteFreq(String name, int octave) {
  final midi = noteNames.indexOf(name) + 12 * (octave + 1);
  return 440.0 * math.pow(2, (midi - 69) / 12.0);
}

/// Synthesize a short buffer containing the given notes (each with a few
/// harmonics), mirroring `_synth_chord` in `test_chords.py`.
List<double> _synthChord(List<(String, int)> notes, {double dur = 0.4, int harmonics = 3}) {
  final n = (_sampleRate * dur).round();
  final w = Float64List(n);
  for (final (name, octave) in notes) {
    final f = _noteFreq(name, octave);
    for (var h = 1; h <= harmonics; h++) {
      for (var i = 0; i < n; i++) {
        final t = i / _sampleRate;
        w[i] += (1.0 / h) * math.sin(2 * math.pi * h * f * t);
      }
    }
  }
  final maxAbs = w.map((v) => v.abs()).reduce(math.max);
  return w.map((v) => 0.5 * v / maxAbs).toList();
}

void main() {
  const chords = {
    'C': [('C', 3), ('E', 3), ('G', 3)],
    'G': [('G', 2), ('B', 2), ('D', 3)],
    'Am': [('A', 2), ('C', 3), ('E', 3)],
    'F': [('F', 2), ('A', 2), ('C', 3)],
    'Em': [('E', 2), ('G', 2), ('B', 2)],
    'Dm': [('D', 3), ('F', 3), ('A', 3)],
    'D': [('D', 3), ('F#', 3), ('A', 3)],
  };

  for (final entry in chords.entries) {
    test('detects ${entry.key} from synthesized audio', () {
      final samples = _synthChord(entry.value);
      final chroma = computeChroma(samples, _sampleRate);
      expect(chroma, isNotNull);

      final reading = detectChord(chroma!);
      expect(reading, isNotNull, reason: '${entry.key}: nothing detected');
      expect(reading!.name, entry.key);
      expect(reading.confidence, greaterThan(0.6));
    });
  }

  test('silence returns null', () {
    final samples = List<double>.filled(3200, 0.0);
    expect(computeChroma(samples, _sampleRate), isNull);
  });

  test('major and minor triads are distinguished', () {
    final cMaj = detectChord(computeChroma(_synthChord([('C', 3), ('E', 3), ('G', 3)]), _sampleRate)!);
    final cMin = detectChord(computeChroma(_synthChord([('C', 3), ('D#', 3), ('G', 3)]), _sampleRate)!);
    expect(cMaj!.name, 'C');
    expect(cMin!.name, 'Cm');
  });
}

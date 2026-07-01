import 'dart:async';

import 'package:flutter/material.dart';
import 'package:brilliant_msg/tx/plain_text.dart';
import 'package:simple_brilliant_app/simple_brilliant_app.dart';

import '../audio/chart_cursor.dart';
import '../audio/mic_chord_stream.dart';
import '../models/song.dart';
import '../widgets/chord_chart_view.dart';
import '../widgets/halo_display_preview.dart';

const _setChordFlag = 0x0a;

/// Music Mode: follows [song]'s chord chart as it's played, by listening to
/// the phone's microphone for chord changes and sending
/// `SETCHORD|<current>|<next>` to the Halo glasses on every cursor advance.
class PlayScreen extends StatefulWidget {
  final Song song;

  const PlayScreen({super.key, required this.song});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with SimpleFrameAppState {
  late final ChartCursor? _cursor;
  final MicChordStream _micStream = MicChordStream();
  StreamSubscription<String?>? _chordSub;
  String? _lastDetected;

  @override
  void initState() {
    super.initState();
    final sequence = widget.song.chordSequence;
    _cursor = sequence.isEmpty ? null : ChartCursor(sequence);
  }

  @override
  void dispose() {
    _chordSub?.cancel();
    _micStream.dispose();
    super.dispose();
  }

  Future<void> _sendChordToFrame() async {
    final cursor = _cursor;
    if (cursor == null || frame == null) return;
    final payload = 'SETCHORD|${cursor.currentChord}|${cursor.nextChord ?? ''}';
    await frame!.sendMessage(_setChordFlag, TxPlainText(text: payload).pack());
  }

  @override
  Future<void> run() async {
    currentState = ApplicationState.running;
    if (mounted) setState(() {});

    await _sendChordToFrame();

    try {
      await _micStream.start();
      _chordSub = _micStream.chordStream.listen((chord) {
        setState(() {
          _lastDetected = chord;
        });
        final cursor = _cursor;
        if (cursor != null && cursor.onChordDetected(chord)) {
          _sendChordToFrame();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone error: $e')),
        );
      }
    }
  }

  @override
  Future<void> cancel() async {
    await _chordSub?.cancel();
    _chordSub = null;
    await _micStream.stop();

    currentState = ApplicationState.ready;
    if (mounted) setState(() {});
  }

  void _advance() {
    final cursor = _cursor;
    if (cursor == null) return;
    setState(() => cursor.advance());
    _sendChordToFrame();
  }

  void _back() {
    final cursor = _cursor;
    if (cursor == null) return;
    setState(() => cursor.back());
    _sendChordToFrame();
  }

  @override
  Widget build(BuildContext context) {
    final cursor = _cursor;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.lyrics_outlined),
            tooltip: 'Lyric Mode (coming soon)',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lyric Mode is coming soon.')),
            ),
          ),
          getBatteryWidget(),
        ],
      ),
      body: cursor == null
          ? const Center(child: Text('This song has no chords to follow.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(cursor.currentChord,
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(color: theme.colorScheme.primary)),
                                ),
                                Text('current', style: theme.textTheme.labelMedium),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(cursor.nextChord ?? '--',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(color: theme.colorScheme.secondary)),
                                ),
                                Text('next', style: theme.textTheme.labelMedium),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 110,
                                child: HaloDisplayPreview(
                                  current: cursor.currentChord,
                                  next: cursor.nextChord,
                                ),
                              ),
                              Text('glasses display', style: theme.textTheme.labelMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_lastDetected != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Heard: $_lastDetected',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: ChordChartView(
                    song: widget.song,
                    highlightChordIndex: cursor.currentIndex,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.skip_previous),
                        tooltip: 'Back',
                      ),
                      IconButton(
                        onPressed: _advance,
                        icon: const Icon(Icons.skip_next),
                        tooltip: 'Advance',
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: getFloatingActionButtonWidget(
          const Icon(Icons.mic), const Icon(Icons.stop)),
      persistentFooterButtons: getFooterButtonsWidget(),
    );
  }
}

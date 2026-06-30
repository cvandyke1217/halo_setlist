import 'package:flutter/material.dart';

import '../models/chord_line.dart';
import '../models/song.dart';

/// Renders a song's chord chart: each line shows its chords positioned above
/// the lyric text (monospace, so character offsets line up).
///
/// [highlightChordIndex] is a global index into `song.chordSequence` - the
/// chord at that index is highlighted as "current" and the one immediately
/// after it as "next". Used by the song editor (no highlight), a read-only
/// chart viewer, and the Play screen (tracks `ChartCursor.currentIndex`).
class ChordChartView extends StatelessWidget {
  final Song song;
  final int? highlightChordIndex;
  final ScrollController? scrollController;

  const ChordChartView({
    super.key,
    required this.song,
    this.highlightChordIndex,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (song.lines.isEmpty) {
      return const Center(child: Text('No chart yet'));
    }

    final theme = Theme.of(context);
    final lines = <Widget>[];
    int globalIndex = 0;

    for (final line in song.lines) {
      if (line.lyrics.isEmpty && line.chords.isEmpty) {
        lines.add(const SizedBox(height: 16));
        continue;
      }

      final startIndex = globalIndex;
      globalIndex += line.chords.length;
      lines.add(_ChordLineWidget(
        line: line,
        firstChordIndex: startIndex,
        highlightChordIndex: highlightChordIndex,
        theme: theme,
      ));
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: lines,
    );
  }
}

class _ChordLineWidget extends StatelessWidget {
  final ChordLine line;
  final int firstChordIndex;
  final int? highlightChordIndex;
  final ThemeData theme;

  const _ChordLineWidget({
    required this.line,
    required this.firstChordIndex,
    required this.highlightChordIndex,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: 'monospace', fontSize: 16);

    if (line.chords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(line.lyrics, style: style),
      );
    }

    // Build the chord row as spans so the current/next chord can be
    // highlighted without disturbing the monospace column alignment.
    final sorted = [...line.chords]..sort((a, b) => a.charIndex.compareTo(b.charIndex));
    final spans = <InlineSpan>[];
    int cursor = 0;
    for (var i = 0; i < sorted.length; i++) {
      final chord = sorted[i];
      final index = chord.charIndex;
      if (index > cursor) {
        spans.add(TextSpan(text: ' ' * (index - cursor)));
      }

      final globalChordIndex = firstChordIndex + i;
      Color? color;
      FontWeight? weight;
      if (highlightChordIndex != null) {
        if (globalChordIndex == highlightChordIndex) {
          color = theme.colorScheme.primary;
          weight = FontWeight.bold;
        } else if (globalChordIndex == highlightChordIndex! + 1) {
          color = theme.colorScheme.secondary;
        }
      }

      spans.add(TextSpan(
        text: chord.chord,
        style: TextStyle(color: color, fontWeight: weight),
      ));
      cursor = index + chord.chord.length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(style: style.copyWith(fontWeight: FontWeight.bold), children: spans)),
          Text(line.lyrics, style: style),
        ],
      ),
    );
  }
}

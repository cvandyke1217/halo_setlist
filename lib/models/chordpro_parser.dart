import 'chord_event.dart';
import 'chord_line.dart';

/// Parsed result of a ChordPro-subset document: optional `{title: ...}` /
/// `{artist: ...}` directives followed by lyric lines with inline `[Chord]`
/// markers, e.g.:
///
/// ```
/// {title: Amazing Grace}
/// {artist: Traditional}
///
/// [G]Amazing grace, how [C]sweet the [G]sound
/// ```
class ChordProDocument {
  final String title;
  final String artist;
  final List<ChordLine> lines;

  const ChordProDocument({
    this.title = '',
    this.artist = '',
    this.lines = const [],
  });
}

final RegExp _directivePattern = RegExp(r'^\{\s*(\w+)\s*:\s*(.*?)\s*\}$');
final RegExp _chordTokenPattern = RegExp(r'\[([^\]]*)\]');

/// Parse a ChordPro-subset document into title/artist metadata and chord
/// lines. Unrecognized `{...}` directives and `#` comment lines are dropped;
/// everything else is treated as a lyric line with optional `[Chord]`
/// markers.
ChordProDocument parseChordPro(String text) {
  String title = '';
  String artist = '';
  final lines = <ChordLine>[];

  for (final rawLine in text.split('\n')) {
    final line = rawLine.trimRight();
    final directive = _directivePattern.firstMatch(line.trim());
    if (directive != null) {
      final key = directive.group(1)!.toLowerCase();
      final value = directive.group(2)!;
      if (key == 'title') {
        title = value;
      } else if (key == 'artist' || key == 'subtitle') {
        artist = value;
      }
      continue;
    }
    if (line.trimLeft().startsWith('#')) {
      continue;
    }
    lines.add(_parseChordLine(line));
  }

  return ChordProDocument(title: title, artist: artist, lines: lines);
}

/// Parse a single lyric line containing inline `[Chord]` markers into its
/// plain-text lyrics and the chords positioned at each marker's offset.
ChordLine _parseChordLine(String line) {
  final lyrics = StringBuffer();
  final chords = <ChordEvent>[];

  int last = 0;
  for (final match in _chordTokenPattern.allMatches(line)) {
    lyrics.write(line.substring(last, match.start));
    final chord = match.group(1)!.trim();
    if (chord.isNotEmpty) {
      chords.add(ChordEvent(chord: chord, charIndex: lyrics.length));
    }
    last = match.end;
  }
  lyrics.write(line.substring(last));

  return ChordLine(lyrics: lyrics.toString(), chords: chords);
}

/// Render a [ChordProDocument] back to its ChordPro-subset text form, e.g.
/// for round-tripping through the song editor.
String serializeChordPro(ChordProDocument doc) {
  final buffer = StringBuffer();
  if (doc.title.isNotEmpty) {
    buffer.writeln('{title: ${doc.title}}');
  }
  if (doc.artist.isNotEmpty) {
    buffer.writeln('{artist: ${doc.artist}}');
  }
  if (doc.title.isNotEmpty || doc.artist.isNotEmpty) {
    buffer.writeln();
  }

  for (final line in doc.lines) {
    buffer.writeln(_serializeChordLine(line));
  }

  // Drop the trailing newline writeln() always adds.
  final out = buffer.toString();
  return out.endsWith('\n') ? out.substring(0, out.length - 1) : out;
}

String _serializeChordLine(ChordLine line) {
  if (line.chords.isEmpty) {
    return line.lyrics;
  }

  final sorted = [...line.chords]..sort((a, b) => a.charIndex.compareTo(b.charIndex));
  final out = StringBuffer();
  int last = 0;
  for (final chord in sorted) {
    final index = chord.charIndex.clamp(0, line.lyrics.length);
    out.write(line.lyrics.substring(last, index));
    out.write('[${chord.chord}]');
    last = index;
  }
  out.write(line.lyrics.substring(last));
  return out.toString();
}

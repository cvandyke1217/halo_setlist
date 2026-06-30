import 'package:flutter_test/flutter_test.dart';
import 'package:halo_setlist/models/chord_event.dart';
import 'package:halo_setlist/models/chord_line.dart';
import 'package:halo_setlist/models/chordpro_parser.dart';

void main() {
  group('parseChordPro', () {
    test('parses title and artist directives', () {
      final doc = parseChordPro('{title: Amazing Grace}\n{artist: Traditional}\n\n[G]Amazing grace');
      expect(doc.title, 'Amazing Grace');
      expect(doc.artist, 'Traditional');
      // The blank line separating the directives from the lyrics becomes its
      // own (empty) ChordLine.
      expect(doc.lines, hasLength(2));
      expect(doc.lines.last.lyrics, 'Amazing grace');
    });

    test('parses inline chord markers at correct character offsets', () {
      final doc = parseChordPro('[G]Amazing grace, how [C]sweet the [G]sound');
      expect(doc.lines, hasLength(1));

      final line = doc.lines.single;
      expect(line.lyrics, 'Amazing grace, how sweet the sound');
      expect(line.chords.map((c) => (c.chord, c.charIndex)), [
        ('G', 0),
        ('C', 19),
        ('G', 29),
      ]);
    });

    test('treats lines without chords as plain lyrics', () {
      final doc = parseChordPro('Just some words');
      expect(doc.lines.single.lyrics, 'Just some words');
      expect(doc.lines.single.chords, isEmpty);
    });

    test('drops comment lines', () {
      final doc = parseChordPro('# a comment\n[C]Hello');
      expect(doc.lines, hasLength(1));
      expect(doc.lines.single.lyrics, 'Hello');
    });

    test('preserves blank lines', () {
      final doc = parseChordPro('[C]Hello\n\n[G]World');
      expect(doc.lines, hasLength(3));
      expect(doc.lines[1].lyrics, '');
      expect(doc.lines[1].chords, isEmpty);
    });
  });

  group('serializeChordPro', () {
    test('round-trips a simple chord chart', () {
      const doc = ChordProDocument(
        title: 'Amazing Grace',
        artist: 'Traditional',
        lines: [
          ChordLine(lyrics: 'Amazing grace, how sweet the sound', chords: [
            ChordEvent(chord: 'G', charIndex: 0),
            ChordEvent(chord: 'C', charIndex: 19),
            ChordEvent(chord: 'G', charIndex: 29),
          ]),
        ],
      );

      final text = serializeChordPro(doc);
      expect(text, '{title: Amazing Grace}\n{artist: Traditional}\n\n'
          '[G]Amazing grace, how [C]sweet the [G]sound');

      final reparsed = parseChordPro(text);
      expect(reparsed.title, doc.title);
      expect(reparsed.artist, doc.artist);
      // The blank line separating directives from lyrics round-trips too.
      expect(reparsed.lines.last.lyrics, doc.lines.single.lyrics);
      expect(
        reparsed.lines.last.chords.map((c) => (c.chord, c.charIndex)),
        doc.lines.single.chords.map((c) => (c.chord, c.charIndex)),
      );
    });

    test('serializes a chordless line as plain text', () {
      const doc = ChordProDocument(lines: [ChordLine(lyrics: 'Just words')]);
      expect(serializeChordPro(doc), 'Just words');
    });
  });
}

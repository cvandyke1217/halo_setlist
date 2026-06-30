import 'dart:math' as math;
import 'dart:typed_data';

/// Pitch-class names, index 0 == C.
const List<String> noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

/// Interval sets (semitones from the root) per chord quality, with the
/// suffix shown to the user. Mirrors `CHORD_QUALITIES` in chords.py.
const List<(String, List<int>)> chordQualities = [
  ('', [0, 4, 7]), // major
  ('m', [0, 3, 7]), // minor
];

/// A named 12-bin unit-vector chroma template for one chord.
class ChordTemplate {
  final String name;
  final Float64List vector;

  const ChordTemplate(this.name, this.vector);
}

/// Build the 24 major/minor triad templates (one per root x quality),
/// each a unit-normalized 12-bin chroma vector. Mirrors `_build_templates`
/// in chords.py.
List<ChordTemplate> buildChordTemplates() {
  final templates = <ChordTemplate>[];
  for (var root = 0; root < 12; root++) {
    for (final (suffix, intervals) in chordQualities) {
      final vec = Float64List(12);
      for (final interval in intervals) {
        vec[(root + interval) % 12] = 1.0;
      }
      final norm = math.sqrt(vec.fold<double>(0, (sum, v) => sum + v * v));
      for (var i = 0; i < 12; i++) {
        vec[i] /= norm;
      }
      templates.add(ChordTemplate('${noteNames[root]}$suffix', vec));
    }
  }
  return templates;
}

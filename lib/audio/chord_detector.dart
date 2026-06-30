import 'dart:typed_data';

import 'chord_templates.dart';

/// Default cosine-similarity threshold below which no chord is reported.
const double defaultConfidenceGate = 0.6;

/// The result of matching a chroma vector against the chord templates.
class ChordReading {
  final String name; // e.g. "C", "Am", "G"
  final double confidence; // cosine similarity of the best template match, 0..1

  const ChordReading({required this.name, required this.confidence});
}

final List<ChordTemplate> _templates = buildChordTemplates();

/// Identify the major/minor triad best matching [chroma] (a unit-normalized
/// 12-bin pitch-class vector, as produced by `computeChroma`).
///
/// Returns `null` if no template matches above [confidenceGate]. Mirrors
/// `detect_chord` in chords.py.
ChordReading? detectChord(
  Float64List chroma, {
  double confidenceGate = defaultConfidenceGate,
}) {
  String bestName = '';
  double bestScore = -1.0;

  for (final template in _templates) {
    double score = 0;
    for (var i = 0; i < 12; i++) {
      score += chroma[i] * template.vector[i];
    }
    if (score > bestScore) {
      bestScore = score;
      bestName = template.name;
    }
  }

  if (bestScore < confidenceGate) return null;
  return ChordReading(name: bestName, confidence: bestScore);
}

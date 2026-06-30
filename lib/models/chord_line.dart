import 'chord_event.dart';

/// One line of a chord chart: plain lyric text plus the chords positioned
/// above specific character offsets in that text.
class ChordLine {
  final String lyrics;
  final List<ChordEvent> chords;

  const ChordLine({required this.lyrics, this.chords = const []});

  factory ChordLine.fromJson(Map<String, dynamic> json) => ChordLine(
        lyrics: json['lyrics'] as String,
        chords: (json['chords'] as List<dynamic>? ?? [])
            .map((e) => ChordEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'lyrics': lyrics,
        'chords': chords.map((c) => c.toJson()).toList(),
      };
}

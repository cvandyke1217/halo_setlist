import 'chord_line.dart';

/// A song: title/artist metadata plus its chord chart (lyrics + chords).
class Song {
  final String id;
  String title;
  String artist;
  List<ChordLine> lines;

  Song({
    required this.id,
    required this.title,
    this.artist = '',
    this.lines = const [],
  });

  /// All chords in the chart, in reading order. This is the sequence that
  /// Music Mode follows as the chord chart is played.
  List<String> get chordSequence =>
      lines.expand((line) => line.chords.map((c) => c.chord)).toList();

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String? ?? '',
        lines: (json['lines'] as List<dynamic>? ?? [])
            .map((e) => ChordLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

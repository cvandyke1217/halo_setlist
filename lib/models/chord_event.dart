/// A chord positioned above a character offset in a [ChordLine]'s lyrics.
class ChordEvent {
  final String chord;
  final int charIndex;

  const ChordEvent({required this.chord, required this.charIndex});

  factory ChordEvent.fromJson(Map<String, dynamic> json) => ChordEvent(
        chord: json['chord'] as String,
        charIndex: json['charIndex'] as int,
      );

  Map<String, dynamic> toJson() => {
        'chord': chord,
        'charIndex': charIndex,
      };
}

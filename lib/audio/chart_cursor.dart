/// Tracks a position within a song's [chordSequence] as it's played.
///
/// On each confirmed chord from [ProgressionTracker], if it matches the
/// expected *next* chord in the chart, the cursor advances. Anything else
/// (a passing tone, a repeat of the current chord, or detection noise) is
/// ignored so a single bad reading can't derail the chart. Manual
/// [advance]/[back]/[reset] are provided as a fallback for when detection
/// misses a change.
class ChartCursor {
  final List<String> chordSequence;
  int currentIndex;

  ChartCursor(this.chordSequence, {this.currentIndex = 0})
      : assert(chordSequence.isNotEmpty, 'chordSequence must not be empty');

  /// The chord currently expected to be played.
  String get currentChord => chordSequence[currentIndex];

  /// The next chord in the chart, or `null` if [currentChord] is the last.
  String? get nextChord =>
      currentIndex + 1 < chordSequence.length ? chordSequence[currentIndex + 1] : null;

  bool get isAtEnd => currentIndex == chordSequence.length - 1;

  /// Feed a confirmed chord detection. Advances the cursor if it matches the
  /// expected next chord. Returns true if the cursor advanced.
  bool onChordDetected(String? chord) {
    if (chord == null) return false;
    final next = nextChord;
    if (next != null && chord == next) {
      currentIndex++;
      return true;
    }
    return false;
  }

  /// Manually move to the next chord (ignored at the end of the chart).
  void advance() {
    if (currentIndex + 1 < chordSequence.length) currentIndex++;
  }

  /// Manually move to the previous chord (ignored at the start of the chart).
  void back() {
    if (currentIndex > 0) currentIndex--;
  }

  void reset() {
    currentIndex = 0;
  }
}

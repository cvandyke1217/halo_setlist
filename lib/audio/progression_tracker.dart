/// Debounces a stream of per-window chord guesses into a stable progression.
///
/// A chord must be detected on [minStable] consecutive windows before it's
/// "confirmed". A newly confirmed chord that differs from the last one in the
/// progression is appended. `null` (silence / low confidence) resets the
/// candidate but never erases history.
///
/// Direct port of `ProgressionTracker` in chords.py.
class ProgressionTracker {
  final int minStable;
  final int maxDisplay;

  final List<String> history = [];

  String? _candidate;
  int _count = 0;
  String? _confirmed;

  ProgressionTracker({this.minStable = 3, this.maxDisplay = 8});

  /// Feed one window's chord guess; returns the progression so far.
  List<String> update(String? chord) {
    if (chord == null) {
      _candidate = null;
      _count = 0;
      return history;
    }

    if (chord == _candidate) {
      _count += 1;
    } else {
      _candidate = chord;
      _count = 1;
    }

    if (_count == minStable && chord != _confirmed) {
      _confirmed = chord;
      if (history.isEmpty || history.last != chord) {
        history.add(chord);
      }
    }

    return history;
  }

  /// The most recently confirmed chord.
  String? get current => _confirmed;

  List<String> recent([int? n]) {
    final count = n ?? maxDisplay;
    if (history.length <= count) return List.unmodifiable(history);
    return List.unmodifiable(history.sublist(history.length - count));
  }

  void reset() {
    history.clear();
    _candidate = null;
    _count = 0;
    _confirmed = null;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:halo_setlist/audio/progression_tracker.dart';

void main() {
  test('commits a chord after minStable consecutive detections', () {
    final t = ProgressionTracker(minStable: 3);
    expect(t.update('C'), <String>[]);
    expect(t.update('C'), <String>[]);
    expect(t.update('C'), ['C']);
    expect(t.current, 'C');
  });

  test('ignores brief blips', () {
    final t = ProgressionTracker(minStable: 3);
    for (var i = 0; i < 3; i++) {
      t.update('C');
    }
    t.update('G'); // blip, not stable
    t.update('C'); // back to C
    expect(t.history, ['C']);
  });

  test('records a distinct progression', () {
    final t = ProgressionTracker(minStable: 2);
    final seq = ['C', 'C', 'G', 'G', 'Am', 'Am', 'F', 'F'];
    List<String> prog = [];
    for (final c in seq) {
      prog = t.update(c);
    }
    expect(prog, ['C', 'G', 'Am', 'F']);
  });

  test('collapses repeats and handles silence', () {
    final t = ProgressionTracker(minStable: 2);
    for (var i = 0; i < 4; i++) {
      t.update('C');
    }
    t.update(null); // silence resets candidate, keeps history
    for (var i = 0; i < 2; i++) {
      t.update('C'); // same chord again -> not duplicated
    }
    expect(t.history, ['C']);
  });

  test('recent and reset', () {
    final t = ProgressionTracker(minStable: 1, maxDisplay: 3);
    for (final c in ['C', 'G', 'Am', 'F', 'C']) {
      t.update(c);
    }
    expect(t.recent(), ['Am', 'F', 'C']);
    t.reset();
    expect(t.history, isEmpty);
    expect(t.current, isNull);
  });
}

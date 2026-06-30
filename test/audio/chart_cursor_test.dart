import 'package:flutter_test/flutter_test.dart';
import 'package:halo_setlist/audio/chart_cursor.dart';

void main() {
  test('starts at the beginning of the chart', () {
    final cursor = ChartCursor(['C', 'G', 'Am', 'F']);
    expect(cursor.currentChord, 'C');
    expect(cursor.nextChord, 'G');
    expect(cursor.isAtEnd, isFalse);
  });

  test('advances when the detected chord matches the expected next chord', () {
    final cursor = ChartCursor(['C', 'G', 'Am', 'F']);

    expect(cursor.onChordDetected('G'), isTrue);
    expect(cursor.currentChord, 'G');
    expect(cursor.nextChord, 'Am');
  });

  test('ignores detections that do not match the expected next chord', () {
    final cursor = ChartCursor(['C', 'G', 'Am', 'F']);

    expect(cursor.onChordDetected('Am'), isFalse); // passing tone / noise
    expect(cursor.onChordDetected('C'), isFalse); // repeat of current
    expect(cursor.currentChord, 'C');
  });

  test('follows a repeating progression', () {
    final cursor = ChartCursor(['C', 'G', 'C', 'Am', 'C']);

    for (final chord in ['G', 'C', 'Am', 'C']) {
      expect(cursor.onChordDetected(chord), isTrue);
    }
    expect(cursor.currentChord, 'C');
    expect(cursor.isAtEnd, isTrue);
    expect(cursor.nextChord, isNull);
  });

  test('detections at the end of the chart are ignored', () {
    final cursor = ChartCursor(['C', 'G'], currentIndex: 1);
    expect(cursor.isAtEnd, isTrue);
    expect(cursor.onChordDetected('C'), isFalse);
    expect(cursor.currentChord, 'G');
  });

  test('manual advance/back/reset', () {
    final cursor = ChartCursor(['C', 'G', 'Am']);

    cursor.advance();
    expect(cursor.currentChord, 'G');

    cursor.advance();
    cursor.advance(); // no-op at the end
    expect(cursor.currentChord, 'Am');

    cursor.back();
    expect(cursor.currentChord, 'G');

    cursor.reset();
    expect(cursor.currentChord, 'C');

    cursor.back(); // no-op at the start
    expect(cursor.currentChord, 'C');
  });
}

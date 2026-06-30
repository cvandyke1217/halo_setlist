import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A 256x256 on-screen mock of the Halo glasses' circular display, rendering
/// exactly what `assets/frame_app.lua`'s `draw_chord` would show for a given
/// `SETCHORD|<current>|<next>` payload.
///
/// This mirrors the Lua's `fit_text`/`fit_size`/`half_width_at` layout math
/// so the preview matches the on-device result (text shrinks/clamps to stay
/// inside the circular safe area).
class HaloDisplayPreview extends StatelessWidget {
  /// The current chord, or null/empty to show the idle placeholder.
  final String current;

  /// The next chord, or empty/null at the end of the song.
  final String? next;

  const HaloDisplayPreview({super.key, required this.current, this.next});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipOval(
        child: ColoredBox(
          color: Colors.black,
          child: CustomPaint(
            painter: _HaloDisplayPainter(current: current, next: next ?? ''),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _HaloDisplayPainter extends CustomPainter {
  final String current;
  final String next;

  _HaloDisplayPainter({required this.current, required this.next});

  // Logical display resolution that `frame_app.lua` was written for.
  static const double _displaySize = 256;
  static const double _cx = 128;
  static const double _safeR = 116;

  static const Color _labelColor = Color(0xFFC0C0C0);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF33AAEE);

  /// Mirrors `text_width` in frame_app.lua: an approximate glyph width.
  double _textWidth(String text, double fontSize) => text.length * fontSize * 0.58;

  /// Mirrors `half_width_at`: half the chord-width of the circle at height [y].
  double _halfWidthAt(double y) {
    final dy = (y - 128).abs();
    if (dy >= _safeR) return 0;
    return math.sqrt(_safeR * _safeR - dy * dy);
  }

  /// Mirrors `fit_size`: largest font size <= [maxSize] that keeps [text]
  /// within the circle's safe width at baseline [y].
  double _fitSize(String text, double y, double maxSize, double minSize) {
    var fontSize = maxSize;
    while (fontSize > minSize) {
      final hw = math.min(_halfWidthAt(y), _halfWidthAt(y + fontSize));
      if (_textWidth(text, fontSize) <= 2 * hw) break;
      fontSize -= 1;
    }
    return fontSize;
  }

  /// Mirrors `fit_text`: draws horizontally-centered text, shrunk/clamped to
  /// stay inside the circular safe area.
  void _fitText(Canvas canvas, Size canvasSize, String text, double y, double maxSize, Color color,
      {double minSize = 10}) {
    final fontSize = _fitSize(text, y, maxSize, minSize);
    final hw = math.min(_halfWidthAt(y), _halfWidthAt(y + fontSize));
    final w = _textWidth(text, fontSize);
    var x = (_cx - w / 2).floorToDouble();
    final left = (_cx - hw).ceilToDouble();
    if (x < left) x = left;

    final scale = canvasSize.width / _displaySize;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontFamily: 'monospace', fontSize: fontSize * scale),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x * scale, y * scale));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final currentText = current.isEmpty ? '--' : current;

    _fitText(canvas, size, 'NOW PLAYING', 34, 16, _labelColor);
    _fitText(canvas, size, currentText, 90, 70, _accent);

    if (next.isNotEmpty) {
      _fitText(canvas, size, 'Next: $next', 196, 24, _white);
    } else {
      _fitText(canvas, size, 'End of song', 196, 20, _labelColor);
    }
  }

  @override
  bool shouldRepaint(covariant _HaloDisplayPainter oldDelegate) =>
      oldDelegate.current != current || oldDelegate.next != next;
}

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:halo_setlist/audio/chord_templates.dart';

void main() {
  test('builds 24 unit-normalized major/minor templates', () {
    final templates = buildChordTemplates();
    expect(templates, hasLength(24));

    final names = templates.map((t) => t.name).toSet();
    expect(names, contains('C'));
    expect(names, contains('Cm'));
    expect(names, contains('G'));
    expect(names, contains('Am'));
    expect(names.length, 24); // all distinct

    for (final template in templates) {
      final norm = math.sqrt(template.vector.fold<double>(0, (sum, v) => sum + v * v));
      expect(norm, closeTo(1.0, 1e-9));
    }
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo_setlist/widgets/halo_display_preview.dart';

/// Golden tests that double as visual screenshots of what `frame_app.lua`
/// renders on the Halo glasses for a given `SETCHORD|<current>|<next>`
/// payload. Run `flutter test --update-goldens` to (re)generate the PNGs
/// under `test/widgets/goldens/`.
///
/// The test font renderer draws solid boxes instead of glyphs unless a real
/// font is registered, so a system monospace font is loaded under the
/// 'monospace' family the preview uses - this only affects how these
/// screenshots look, not the app itself.
void main() {
  setUpAll(() async {
    const candidates = [
      '/System/Library/Fonts/Supplemental/Courier New.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final loader = FontLoader('monospace')
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
        break;
      }
    }
  });

  Future<void> pumpPreview(WidgetTester tester, {required String current, String? next}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: Colors.grey.shade900,
          body: Center(
            child: SizedBox(
              width: 256,
              height: 256,
              child: HaloDisplayPreview(current: current, next: next),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders a typical mid-song chord change', (tester) async {
    await pumpPreview(tester, current: 'Em', next: 'G');
    await expectLater(
      find.byType(HaloDisplayPreview),
      matchesGoldenFile('goldens/halo_display_em_to_g.png'),
    );
  });

  testWidgets('renders the start of a song', (tester) async {
    await pumpPreview(tester, current: 'G', next: 'C');
    await expectLater(
      find.byType(HaloDisplayPreview),
      matchesGoldenFile('goldens/halo_display_g_to_c.png'),
    );
  });

  testWidgets('renders the end of the song', (tester) async {
    await pumpPreview(tester, current: 'C', next: '');
    await expectLater(
      find.byType(HaloDisplayPreview),
      matchesGoldenFile('goldens/halo_display_end_of_song.png'),
    );
  });

  testWidgets('shrinks long chord names to fit the circle', (tester) async {
    await pumpPreview(tester, current: 'F#maj7', next: 'Bbm7b5');
    await expectLater(
      find.byType(HaloDisplayPreview),
      matchesGoldenFile('goldens/halo_display_long_chord_names.png'),
    );
  });

  testWidgets('renders the idle placeholder before any chord is detected', (tester) async {
    await pumpPreview(tester, current: '', next: '');
    await expectLater(
      find.byType(HaloDisplayPreview),
      matchesGoldenFile('goldens/halo_display_idle.png'),
    );
  });
}

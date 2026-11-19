import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/core/values/text_styles.dart';
import 'package:host_bora/app/core/widget/module_default_text_scope.dart';

/// Guards the line height carried by [moduleDefaultTextStyle].
///
/// That height merges into every module [Text] that does not set its own, so
/// raising it grows the line box of roughly 1,600 existing labels — including
/// single-line ones sitting inside fixed-height rows. These tests pin the
/// combinations the app actually uses so the height cannot be raised to a
/// value that silently overflows them.
void main() {
  // Fixed container heights that appear most often around text in
  // lib/app/modules, plus AppValues.formButtonHeight.
  const rowHeights = <double>[20, 22, 24, 36, 38, 40, 42, 44, 48, 50, 52, 56];

  // The inline font sizes used across the app, smallest and largest first.
  const fontSizes = <double>[10, 11, 12, 13, 14, 15, 16, 18, 20, 22];

  Widget harness(Widget child) => MaterialApp(
        home: Scaffold(
          body: ModuleDefaultTextScope(child: child),
        ),
      );

  testWidgets('inherited line height does not overflow fixed-height rows',
      (tester) async {
    for (final height in rowHeights) {
      for (final size in fontSizes) {
        // A label at this size only belongs in a row that can hold it; the
        // pairing is skipped rather than asserted when the glyph is taller
        // than the container by design.
        if (size * 1.35 > height) continue;

        await tester.pumpWidget(
          harness(
            SizedBox(
              height: height,
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mwenyeji wa nyumba',
                      style: TextStyle(fontSize: size),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflowed at fontSize $size in a ${height}px row',
        );
      }
    }
  });

  testWidgets('padding-based chips and buttons still lay out', (tester) async {
    await tester.pumpWidget(
      harness(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: const Text('Per Month', style: TextStyle(fontSize: 12)),
            ),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('module default declares a line height', () {
    // The whole point of the style. A null height here would silently return
    // ~1,600 labels to the font's default leading.
    expect(moduleDefaultTextStyle.height, isNotNull);
    expect(moduleDefaultTextStyle.height, greaterThanOrEqualTo(1.3));
    // Material's body spec is 1.5; anything beyond that stops fitting the
    // 20px and 22px rows this app uses for dense secondary labels.
    expect(moduleDefaultTextStyle.height, lessThanOrEqualTo(1.5));
  });

  test('rent default carries the line height but no font size', () {
    // Rent screens set their own sizes; a fontSize here would override every
    // one of them, which is why the workspace opted out in the first place.
    expect(rentDefaultTextStyle.fontSize, isNull);
    expect(rentDefaultTextStyle.height, moduleDefaultTextStyle.height);
  });
}

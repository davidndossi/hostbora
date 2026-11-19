import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/core/theme/app_typography.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final brightness in Brightness.values) {
      test('type scale uses system font on $platform ($brightness)', () {
        final theme = ThemeData(
          brightness: brightness,
          platform: platform,
          useMaterial3: false,
          textTheme: AppTypography.textTheme(),
        );
        final styles = <String, TextStyle?>{
          'bodyMedium': theme.textTheme.bodyMedium,
          'titleMedium': theme.textTheme.titleMedium,
          'bodyLarge': theme.textTheme.bodyLarge,
          'titleLarge': theme.textTheme.titleLarge,
          'labelSmall': theme.textTheme.labelSmall,
        };
        for (final e in styles.entries) {
          final s = e.value!;
          // The scale never pins a family; the platform typography supplies
          // San Francisco on iOS and the built-in Roboto on Android.
          final family = s.fontFamily ?? '';
          if (platform == TargetPlatform.iOS) {
            expect(
              family.startsWith('.SF') || family.startsWith('CupertinoSystem'),
              isTrue,
              reason: '${e.key} resolved to "$family" on iOS',
            );
          } else {
            expect(family, 'Roboto', reason: e.key);
          }
          expect(s.color, isNotNull, reason: '${e.key} keeps theme text color');
          expect(
            s.fontFeatures,
            contains(const FontFeature.tabularFigures()),
            reason: '${e.key} uses tabular figures',
          );
        }
        // Inputs and list tiles read these slots, so they must stay regular.
        expect(theme.textTheme.titleMedium!.fontWeight, FontWeight.w400);
        expect(theme.textTheme.bodyLarge!.fontWeight, FontWeight.w400);
        // Smallest allowed size.
        expect(theme.textTheme.labelSmall!.fontSize, 10);
      });
    }
  }
}

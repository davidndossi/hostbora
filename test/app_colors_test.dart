import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the palette against the two ways it grew to 62 tokens: values that
/// outlived their last caller, and new names for colours that already had one.
///
/// Parses the source rather than importing the class because Dart offers no
/// reflection over static fields in AOT, and because the call-site counts have
/// to come from the tree anyway.
void main() {
  final paletteFile = File('lib/app/core/values/app_colors.dart');
  final palette = paletteFile.readAsStringSync();

  /// `name -> declared value`, single-line `Color` declarations only. The
  /// MaterialColor swatch is multi-line and deliberately excluded: it is one
  /// token by definition and has no duplicate to find.
  final declarations = <String, String>{
    for (final m in RegExp(
      r'static (?:const )?Color (\w+) = ([^;]+);',
    ).allMatches(palette))
      m.group(1)!: m.group(2)!.trim(),
  };

  List<File> dartSources() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList(growable: false);

  test('palette declares at least one token', () {
    expect(declarations, isNotEmpty, reason: 'parser stopped matching');
  });

  test('every token is referenced outside the palette', () {
    final others = dartSources()
        .where((f) => f.path != paletteFile.path)
        .map((f) => f.readAsStringSync())
        .join('\n');

    final dead = declarations.keys
        .where((n) => !RegExp('\\bAppColors\\.$n\\b').hasMatch(others))
        .toList()
      ..sort();

    expect(
      dead,
      isEmpty,
      reason:
          'Unused colour tokens. Delete them rather than leaving them for a '
          'future caller to pick arbitrarily: ${dead.join(', ')}',
    );
  });

  test('no two tokens hold the same colour value', () {
    // Roles that are genuinely separate but currently share a value. Splitting
    // one later should not require touching the other, so both names stay.
    const allowedPairs = {
      {'appBarIconColor', 'appBarTextColor'},
      {'centerTextColor', 'suffixImageColor'},
    };

    String literalFor(String name, [int depth = 0]) {
      final value = declarations[name]!;
      if (depth < 6 && declarations.containsKey(value)) {
        return literalFor(value, depth + 1);
      }
      return value.toLowerCase();
    }

    final byValue = <String, Set<String>>{};
    for (final name in declarations.keys) {
      byValue.putIfAbsent(literalFor(name), () => <String>{}).add(name);
    }

    final duplicates = byValue.entries
        .where((e) => e.value.length > 1)
        .where((e) => !allowedPairs.any((p) => p.containsAll(e.value)))
        .map((e) => '${e.key} shared by ${e.value.join(' + ')}')
        .toList()
      ..sort();

    expect(
      duplicates,
      isEmpty,
      reason:
          'Two names for one colour. Reuse the existing token, or add the pair '
          'to allowedPairs if the roles really are independent:\n'
          '${duplicates.join('\n')}',
    );
  });
}

import '../../../../l10n/app_localizations.dart';

/// Floor index in [PropertyUnitRecord.floor] and units_json `unitFloor`.
abstract final class PropertyUnitFloor {
  static const int ground = 0;
  static const int first = 1;
  static const int second = 2;
  static const int third = 3;
  static const int defaultIndex = ground;
  static const List<int> indices = [ground, first, second, third];

  static int parse(dynamic raw) {
    if (raw is int && indices.contains(raw)) return raw;
    if (raw is num) return parse(raw.toInt());
    final n = int.tryParse(raw?.toString() ?? '');
    if (n != null && indices.contains(n)) return n;
    return defaultIndex;
  }

  static String label(AppLocalizations l10n, int floor) {
    switch (floor) {
      case first:
        return l10n.unitFloorFirst;
      case second:
        return l10n.unitFloorSecond;
      case third:
        return l10n.unitFloorThird;
      default:
        return l10n.unitFloorGround;
    }
  }
}

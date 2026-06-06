import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../db/tenant_local_data_source.dart';

/// Represents a vacancy period between two consecutive tenant leases on a unit.
class TenantVacancyGap {
  const TenantVacancyGap({
    required this.propertyLabel,
    required this.propertyRef,
    required this.unitLabel,
    required this.gapStart,
    required this.gapEnd,
    required this.previousTenant,
    required this.nextTenant,
  });

  final String propertyLabel;
  final String propertyRef;
  final String unitLabel;
  final DateTime gapStart;
  final DateTime gapEnd;
  final String previousTenant;
  final String nextTenant;

  int get gapDays => gapEnd.difference(gapStart).inDays;

  String get gapDaysLabel {
    final d = gapDays;
    if (d == 1) return '1 day';
    return '$d days';
  }

  static final _fmt = DateFormat('dd/MM/yyyy');

  String get gapStartDisplay => _fmt.format(gapStart);
  String get gapEndDisplay => _fmt.format(gapEnd);
}

class TenantGapDetectionService {
  TenantGapDetectionService()
      : _tenantLocal = Get.find<TenantLocalDataSource>();

  final TenantLocalDataSource _tenantLocal;

  /// Detects vacancy gaps between consecutive tenants on each unit.
  ///
  /// Returns gaps sorted by gap length (longest first).
  Future<List<TenantVacancyGap>> detectGaps({
    String? propertyRef,
    int minimumGapDays = 1,
  }) async {
    final allTenants = await _tenantLocal.getAllNewestFirst();

    // Group by property+unit key.
    final unitGroups = <String, List<TenantRecord>>{};
    for (final t in allTenants) {
      if (propertyRef != null &&
          propertyRef.isNotEmpty &&
          t.propertyRef != propertyRef) {
        continue;
      }
      final unitKey = '${t.propertyRef}||${t.unitLabel}';
      unitGroups.putIfAbsent(unitKey, () => []).add(t);
    }

    final gaps = <TenantVacancyGap>[];

    for (final entry in unitGroups.entries) {
      final tenants = entry.value;
      if (tenants.length < 2) continue;

      // Sort by lease start ascending.
      tenants.sort((a, b) => a.leaseStartIso.compareTo(b.leaseStartIso));

      for (var i = 0; i < tenants.length - 1; i++) {
        final current = tenants[i];
        final next = tenants[i + 1];

        final currentEnd = _parseDate(current.leaseEndIso);
        final nextStart = _parseDate(next.leaseStartIso);

        if (currentEnd == null || nextStart == null) continue;
        if (!nextStart.isAfter(currentEnd)) continue;

        final gapDays = nextStart.difference(currentEnd).inDays;
        if (gapDays < minimumGapDays) continue;

        gaps.add(
          TenantVacancyGap(
            propertyLabel: current.propertyLabel,
            propertyRef: current.propertyRef,
            unitLabel: current.unitLabel,
            gapStart: currentEnd,
            gapEnd: nextStart,
            previousTenant: current.tenantName,
            nextTenant: next.tenantName,
          ),
        );
      }
    }

    // Longest gap first.
    gaps.sort((a, b) => b.gapDays.compareTo(a.gapDays));
    return gaps;
  }

  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final d = DateTime.parse(raw.trim());
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }
}

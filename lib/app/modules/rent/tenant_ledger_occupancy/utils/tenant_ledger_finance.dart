import 'package:intl/intl.dart';

import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';

/// Shared rent-ledger billing math and income ↔ tenant matching.
class TenantLedgerFinance {
  TenantLedgerFinance._();

  static const tenantIdNotePrefix = 'tenantId:';
  static final _tenantIdNotePattern = RegExp(
    r'(?:^|[^\d])tenantId:(\d+)(?!\d)',
    multiLine: true,
  );

  static DateTime? parseIsoDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final d = DateTime.parse(raw.trim());
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  static int monthsBetween(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    if (b.isBefore(a)) return 0;
    // End date is inclusive: 1 Jul–31 Dec is 6 months, not 5.
    final exclusiveEnd = b.add(const Duration(days: 1));
    var months =
        (exclusiveEnd.year - a.year) * 12 + (exclusiveEnd.month - a.month);
    if (exclusiveEnd.day < a.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  static int daysBetween(DateTime start, DateTime end) {
    final d = end.difference(start).inDays;
    return d < 0 ? 0 : d;
  }

  static int billingUnitsBetween(String startIso, String endIso, String frequency) {
    final start = parseIsoDate(startIso);
    final end = parseIsoDate(endIso);
    if (start == null || end == null || !end.isAfter(start)) return 1;
    final freq = frequency.trim().toLowerCase();
    if (freq == 'per stay') return 1;
    final days = end.difference(start).inDays;
    switch (freq) {
      case 'per day':
      case 'per night':
        return days.clamp(1, 36500);
      case 'per week':
        return (days / 7).ceil().clamp(1, 5200);
      case 'per year':
        return ((end.year - start.year) +
                ((end.month > start.month ||
                        (end.month == start.month && end.day >= start.day))
                    ? 0
                    : -1))
            .clamp(1, 300);
      case 'per month':
      default:
        return monthsBetween(start, end).clamp(1, 1200);
    }
  }

  static int totalDueTsh(TenantRecord rec) {
    if (rec.rentAmountValue <= 0) return 0;
    final freq = rec.rentFrequency.trim().toLowerCase();
    if (freq == 'per stay') return rec.rentAmountValue.round();
    final start = parseIsoDate(rec.leaseStartIso);
    final end = parseIsoDate(rec.leaseEndIso);
    if (start == null || end == null || !end.isAfter(start)) {
      return rec.rentAmountValue.round();
    }
    final units = billingUnitsBetween(
      rec.leaseStartIso,
      rec.leaseEndIso,
      rec.rentFrequency,
    );
    return (units * rec.rentAmountValue).round();
  }

  static DateTime stayAnchor(TenantRecord rec, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final end = parseIsoDate(rec.leaseEndIso);
    if (end != null && end.isBefore(today)) return end;
    return today;
  }

  static int currentStayMonths(TenantRecord rec, DateTime now) {
    final start = parseIsoDate(rec.leaseStartIso);
    if (start == null) return 0;
    return monthsBetween(start, stayAnchor(rec, now)).clamp(0, 1200);
  }

  static int currentStayDays(TenantRecord rec, DateTime now) {
    final start = parseIsoDate(rec.leaseStartIso);
    if (start == null) return 0;
    return daysBetween(start, stayAnchor(rec, now));
  }

  static String currentStayLabel(TenantRecord rec, DateTime now, {bool isSw = false}) {
    final months = currentStayMonths(rec, now);
    final days = currentStayDays(rec, now);
    if (rec.rentFrequency.trim().toLowerCase() == 'per stay') {
      if (days <= 0) {
        return isSw ? 'Siku 0' : '0 days';
      }
      return isSw ? 'Siku $days' : '$days days';
    }
    if (months <= 0) {
      return isSw ? 'Mwezi 1' : '1 month';
    }
    return isSw ? 'Miezi $months' : '$months months';
  }

  static int leaseDurationUnits(TenantRecord rec) {
    return billingUnitsBetween(
      rec.leaseStartIso,
      rec.leaseEndIso,
      rec.rentFrequency,
    ).clamp(1, 1200);
  }

  static String tenancyRangeLabel(TenantRecord rec, {bool isSw = false}) {
    final start = parseIsoDate(rec.leaseStartIso);
    final end = parseIsoDate(rec.leaseEndIso);
    if (start == null) {
      return isSw ? 'Tarehe haijasajiliwa' : 'Dates not recorded';
    }
    final fmt = DateFormat('dd/MM/yyyy');
    final startLabel = fmt.format(start);
    if (end == null) {
      return isSw ? '$startLabel – sasa' : '$startLabel – Present';
    }
    return '$startLabel – ${fmt.format(end)}';
  }

  static String leaseDurationLabel(TenantRecord rec, {bool isSw = false}) {
    final units = leaseDurationUnits(rec);
    final freq = rec.rentFrequency.trim().toLowerCase();
    if (freq == 'per stay') {
      return isSw ? 'Kukaa kimoja' : 'Single stay';
    }
    if (freq == 'per day' || freq == 'per night') {
      return isSw ? 'Usiku $units' : '$units nights';
    }
    if (freq == 'per week') {
      return isSw ? 'Wiki $units' : '$units weeks';
    }
    if (freq == 'per year') {
      return isSw ? 'Miaka $units' : '$units years';
    }
    return isSw ? 'Miezi $units' : '$units months';
  }

  static String paymentStatusValue(int due, int paid) {
    if (due <= 0 || paid >= due) return 'paid';
    if (paid <= 0) return 'pending';
    return 'partial';
  }

  static bool notesLinkTenant(String notes, int tenantId) {
    if (tenantId <= 0) return false;
    for (final match in _tenantIdNotePattern.allMatches(notes)) {
      if (int.tryParse(match.group(1) ?? '') == tenantId) return true;
    }
    return false;
  }

  /// Keeps local `tenantId:` tags when a remote payment overwrites notes.
  static String mergeNotesKeepingTenantIds(String incoming, String existing) {
    var merged = incoming;
    for (final match in _tenantIdNotePattern.allMatches(existing)) {
      final id = int.tryParse(match.group(1) ?? '');
      if (id == null || id <= 0) continue;
      merged = appendTenantIdNote(merged, id);
    }
    return merged;
  }

  static bool incomeMatchesTenant(IncomeRecord r, TenantRecord t) {
    if (t.id <= 0) return false;
    if (r.tenantId > 0) return r.tenantId == t.id;
    if (notesLinkTenant(r.notes, t.id)) return true;
    return _incomeMatchesTenantPlace(r, t);
  }

  /// Legacy payments often have [IncomeRecord.tenantId] 0 and no `tenantId:`
  /// note. Match them only when the tenant name agrees **and** the listing
  /// (propertyRef, or property + unit labels) agrees — never by name alone.
  static bool _incomeMatchesTenantPlace(IncomeRecord r, TenantRecord t) {
    final name = t.tenantName.trim().toLowerCase();
    final rName = r.tenantName.trim().toLowerCase();
    if (name.isEmpty || rName != name) return false;

    final tRef = t.propertyRef.trim();
    final rRef = r.propertyRef.trim();
    if (tRef.isNotEmpty && rRef.isNotEmpty) return tRef == rRef;

    final unit = t.unitLabel.trim().toLowerCase();
    final rUnit = r.apartmentUnit.trim().toLowerCase();
    final label = t.propertyLabel.trim().toLowerCase();
    final apt = r.apartment.trim().toLowerCase();
    final unitOk = unit.isNotEmpty && rUnit.isNotEmpty && unit == rUnit;
    final placeOk = label.isNotEmpty &&
        apt.isNotEmpty &&
        (apt == label || apt.contains(label) || label.contains(apt));
    if (unitOk && (placeOk || apt.isEmpty || label.isEmpty)) return true;
    if (placeOk && (unit.isEmpty || rUnit.isEmpty || unit == rUnit)) {
      return true;
    }
    return false;
  }

  static String appendTenantIdNote(String notes, int tenantId) {
    final tag = '$tenantIdNotePrefix$tenantId';
    if (notes.contains(tag)) return notes;
    final trimmed = notes.trim();
    if (trimmed.isEmpty) return tag;
    return '$trimmed\n$tag';
  }
}

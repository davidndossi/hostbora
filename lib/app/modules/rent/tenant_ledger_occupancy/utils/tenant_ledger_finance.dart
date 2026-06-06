import 'package:intl/intl.dart';

import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';

/// Shared rent-ledger billing math and income ↔ tenant matching.
class TenantLedgerFinance {
  TenantLedgerFinance._();

  static const tenantIdNotePrefix = 'tenantId:';

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
    var months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) months -= 1;
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

  static bool incomeMatchesTenant(IncomeRecord r, TenantRecord t) {
    final idTag = '$tenantIdNotePrefix${t.id}';
    if (r.notes.contains(idTag)) return true;

    final incomeTenant = r.tenantName.trim().toLowerCase();
    final tenantName = t.tenantName.trim().toLowerCase();
    final tenantMatches = incomeTenant.isNotEmpty && incomeTenant == tenantName;
    if (incomeTenant.isNotEmpty && !tenantMatches) return false;

    final tenantRef = t.propertyRef.trim();
    final incomeRef = r.propertyRef.trim();
    final refMatches =
        tenantRef.isNotEmpty && incomeRef.isNotEmpty && tenantRef == incomeRef;
    if (tenantRef.isNotEmpty && incomeRef.isNotEmpty && !refMatches) {
      return false;
    }

    final unitMatches = _incomeRowMatchesTenantUnit(r, t);
    if (refMatches && (tenantMatches || unitMatches)) return true;
    if (tenantMatches && unitMatches) return true;
    if (tenantMatches && _incomeRowMatchesTenantProperty(r, t)) return true;
    return !tenantMatches &&
        unitMatches &&
        _incomeRowMatchesTenantProperty(r, t);
  }

  static bool _incomeRowMatchesTenantUnit(IncomeRecord r, TenantRecord t) {
    final tenantUnitId = t.apartmentUnitId.trim().toLowerCase();
    final tenantUnit = t.unitLabel.trim().toLowerCase();
    final incomeUnit = r.apartmentUnit.trim().toLowerCase();
    final notes = r.notes.trim().toLowerCase();
    if (tenantUnitId.isNotEmpty && incomeUnit == tenantUnitId) return true;
    if (tenantUnit.isNotEmpty && incomeUnit == tenantUnit) return true;
    if (tenantUnit.isNotEmpty && notes.contains(tenantUnit)) return true;
    return false;
  }

  static bool _incomeRowMatchesTenantProperty(IncomeRecord r, TenantRecord t) {
    final pl = t.propertyLabel.trim().toLowerCase();
    if (pl.isEmpty) return true;
    final ap = r.apartment.trim().toLowerCase();
    final unit = r.apartmentUnit.trim().toLowerCase();
    final notes = r.notes.trim().toLowerCase();
    final blob = '$ap $unit $notes'.trim();
    return blob.contains(pl) ||
        (ap.isNotEmpty && pl.contains(ap)) ||
        (unit.isNotEmpty && pl.contains(unit));
  }

  static String appendTenantIdNote(String notes, int tenantId) {
    final tag = '$tenantIdNotePrefix$tenantId';
    if (notes.contains(tag)) return notes;
    final trimmed = notes.trim();
    if (trimmed.isEmpty) return tag;
    return '$trimmed\n$tag';
  }
}

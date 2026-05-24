/// Billing units and stay totals from [rentAmountValue] + [rentFrequency] + lease dates.
class TenantRentBilling {
  TenantRentBilling._();

  static int billingUnitsBetween(
    DateTime start,
    DateTime end,
    String frequency,
  ) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final daysInclusive = (e.difference(s).inDays + 1).clamp(1, 36500);
    switch (frequency.trim().toLowerCase()) {
      case 'per stay':
        return 1;
      case 'per day':
        return daysInclusive;
      case 'per week':
        return (daysInclusive / 7).ceil().clamp(1, 5200);
      case 'per year':
        return ((e.year - s.year) +
                ((e.month > s.month ||
                        (e.month == s.month && e.day >= s.day))
                    ? 0
                    : -1))
            .clamp(1, 300);
      case 'per month':
      default:
        return _monthsBetween(s, e).clamp(1, 1200);
    }
  }

  static int _monthsBetween(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  /// Total due for the full lease span: rate × billing units.
  static double totalForStay({
    required double ratePerPeriod,
    required String frequency,
    required DateTime leaseStart,
    required DateTime leaseEnd,
  }) {
    if (ratePerPeriod <= 0) return 0;
    final units = billingUnitsBetween(leaseStart, leaseEnd, frequency);
    return ratePerPeriod * units;
  }

  /// Revenue for a tenant row in one calendar month (handles Per Stay lump sums).
  static double revenueInCalendarMonth({
    required double rentAmountValue,
    required String rentFrequency,
    required String leaseStartIso,
    required String leaseEndIso,
    required DateTime monthStart,
    required DateTime nextMonthStart,
  }) {
    if (rentAmountValue <= 0) return 0;
    final start = _parseIsoDate(leaseStartIso);
    final end = _parseIsoDate(leaseEndIso);
    if (start == null || end == null) return rentAmountValue;
    final ms = DateTime(monthStart.year, monthStart.month, monthStart.day);
    final me = DateTime(
      nextMonthStart.year,
      nextMonthStart.month,
      nextMonthStart.day,
    ).subtract(const Duration(days: 1));
    if (end.isBefore(ms) || start.isAfter(me)) return 0;

    final freq = rentFrequency.trim().toLowerCase();
    if (freq == 'per stay') {
      if (start.year == monthStart.year && start.month == monthStart.month) {
        return rentAmountValue;
      }
      return 0;
    }

    DateTime ovStart = start.isAfter(ms) ? start : ms;
    DateTime ovEnd = end.isBefore(me) ? end : me;
    if (ovEnd.isBefore(ovStart)) return 0;
    final overlapDays = ovEnd.difference(ovStart).inDays + 1;
    switch (freq) {
      case 'per day':
        return rentAmountValue * overlapDays;
      case 'per week':
        return rentAmountValue * (overlapDays / 7).ceil();
      case 'per year':
        return rentAmountValue / 12;
      case 'per month':
      default:
        return rentAmountValue;
    }
  }

  static DateTime? _parseIsoDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.length >= 10 && t[4] == '-' && t[7] == '-') {
      final y = int.tryParse(t.substring(0, 4));
      final m = int.tryParse(t.substring(5, 7));
      final d = int.tryParse(t.substring(8, 10));
      if (y != null &&
          m != null &&
          d != null &&
          m >= 1 &&
          m <= 12 &&
          d >= 1 &&
          d <= 31) {
        return DateTime(y, m, d);
      }
    }
    try {
      final p = DateTime.parse(t);
      return DateTime(p.year, p.month, p.day);
    } catch (_) {
      return null;
    }
  }

  static String periodLabel(String frequency, {bool sw = false}) {
    switch (frequency.trim().toLowerCase()) {
      case 'per stay':
        return sw ? 'kukaa' : 'stay';
      case 'per day':
        return sw ? 'siku' : 'day';
      case 'per week':
        return sw ? 'wiki' : 'week';
      case 'per year':
        return sw ? 'mwaka' : 'year';
      case 'per month':
      default:
        return sw ? 'mwezi' : 'month';
    }
  }
}

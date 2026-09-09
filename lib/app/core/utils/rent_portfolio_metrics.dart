import '../../data/local/db/income_local_data_source.dart';
import '../../data/local/db/property_local_data_source.dart';
import '../../data/local/db/tenant_local_data_source.dart';
import 'property_unit_count.dart';

/// Portfolio-level rent KPIs for hub / dashboard cards.
class RentPortfolioMetrics {
  const RentPortfolioMetrics({
    required this.monthlyIncome,
    required this.occupancyPercent,
    required this.activeLeases,
    required this.totalArrears,
  });

  final double monthlyIncome;
  final int occupancyPercent;
  final int activeLeases;
  final double totalArrears;
}

class RentPortfolioMetricsCalculator {
  const RentPortfolioMetricsCalculator._();

  static Future<RentPortfolioMetrics> compute({
    required List<PropertyRecord> properties,
    required List<TenantRecord> tenants,
    required List<IncomeRecord> incomeRows,
    required DateTime now,
  }) async {
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    var monthlyIncome = 0.0;
    for (final row in incomeRows) {
      final d = row.paidLocalCalendarOrCreated();
      if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
        monthlyIncome += row.amountValue;
      }
    }

    var totalUnits = 0;
    var occupiedSlots = 0;
    var activeLeases = 0;
    var totalArrears = 0.0;

    for (final p in properties) {
      final unitCount = _unitCountForProperty(p);
      totalUnits += unitCount;

      final propertyTenants = tenants.where((t) => _tenantMatchesProperty(t, p)).toList();
      var activeOnProperty = 0;
      for (final t in propertyTenants) {
        final start = _parseDate(t.leaseStartIso);
        final end = _parseDate(t.leaseEndIso); // null = open-ended
        if (!_isLeaseActiveOnDay(start, end, today)) continue;
        activeOnProperty++;
        activeLeases++;

        final paid = _sumIncomeForTenant(t, incomeRows);
        final freq = t.rentFrequency.trim().toLowerCase();
        final isPerNight =
            freq.contains('night') || freq.contains('bnb') || freq.contains('per night');
        final isWeekly = freq.contains('week');
        final isYearly = freq.contains('year') || freq.contains('annual');

        double expectedToDate;
        double totalAmount;

        if (isPerNight) {
          // BnB: expected = nights elapsed × per-night rate
          final leaseStart = start ?? today;
          final elapsed = today.difference(leaseStart).inDays.clamp(0, 3650);
          expectedToDate = t.rentAmountValue * elapsed;
          final leaseEnd = end ?? today;
          final totalNights = leaseEnd.difference(leaseStart).inDays.clamp(1, 3650);
          totalAmount = t.rentAmountValue * totalNights;
        } else if (isWeekly) {
          final leaseStart = start ?? today;
          final elapsed = today.difference(leaseStart).inDays.clamp(0, 3650);
          expectedToDate = (t.rentAmountValue / 7) * elapsed;
          final leaseEnd = end ?? today.add(const Duration(days: 30));
          totalAmount = (t.rentAmountValue / 7) *
              leaseEnd.difference(leaseStart).inDays.clamp(1, 3650);
        } else if (isYearly) {
          final leaseStart = start ?? today;
          final elapsed = today.difference(leaseStart).inDays.clamp(0, 3650);
          expectedToDate = (t.rentAmountValue / 365) * elapsed;
          final leaseEnd = end ?? today.add(const Duration(days: 365));
          totalAmount = (t.rentAmountValue / 365) *
              leaseEnd.difference(leaseStart).inDays.clamp(1, 3650);
        } else {
          // Monthly (default)
          final leaseEnd = end ?? today.add(const Duration(days: 30));
          final totalMonths =
              _monthsBetween(start ?? today, leaseEnd).clamp(1, 240);
          final spentMonths =
              _monthsBetween(start ?? today, today).clamp(0, totalMonths);
          totalAmount = t.rentAmountValue * totalMonths;
          expectedToDate =
              (t.rentAmountValue * spentMonths).clamp(0, totalAmount);
        }

        final paidClamped = paid.clamp(0, totalAmount);
        final arrears =
            (expectedToDate - paidClamped).clamp(0, double.infinity);
        totalArrears += arrears;
      }
      if (unitCount > 0) {
        occupiedSlots += activeOnProperty.clamp(0, unitCount);
      } else if (activeOnProperty > 0) {
        occupiedSlots += activeOnProperty;
        totalUnits += activeOnProperty;
      }
    }

    final occupancyPercent = totalUnits <= 0
        ? 0
        : ((occupiedSlots / totalUnits) * 100).round().clamp(0, 100);

    return RentPortfolioMetrics(
      monthlyIncome: monthlyIncome,
      occupancyPercent: occupancyPercent,
      activeLeases: activeLeases,
      totalArrears: totalArrears,
    );
  }

  static int _unitCountForProperty(PropertyRecord p) =>
      PropertyUnitCount.of(p);

  static bool _tenantMatchesProperty(TenantRecord t, PropertyRecord p) {
    final ref = t.propertyRef.trim();
    final pRef = p.propertyRef.trim();
    if (ref.isNotEmpty && pRef.isNotEmpty && ref == pRef) return true;
    final legacy = 'legacy_${p.id}';
    final local = 'local_${p.id}';
    if (ref == legacy || ref == local) return true;
    final label = t.propertyLabel.trim().toLowerCase();
    if (label.isEmpty) return false;
    final loc = p.propertyLocation.trim().toLowerCase();
    final name = p.propertyName.trim().toLowerCase();
    final line = loc.isNotEmpty && name.isNotEmpty ? '$loc · $name' : (loc.isNotEmpty ? loc : name);
    return label == line || label.contains(loc) || line.contains(label);
  }

  static bool _isLeaseActiveOnDay(
    DateTime? start,
    DateTime? end,
    DateTime day,
  ) {
    // No start date → skip (tenant has no recorded lease start)
    if (start == null) return false;
    final s = DateTime(start.year, start.month, start.day);
    if (day.isBefore(s)) return false;
    // Null end = open-ended lease; treat as still active
    if (end == null) return true;
    final e = DateTime(end.year, end.month, end.day);
    return !day.isAfter(e);
  }

  static double _sumIncomeForTenant(
    TenantRecord tenant,
    List<IncomeRecord> incomeRows,
  ) {
    var sum = 0.0;
    for (final row in incomeRows) {
      if (row.tenantName.trim().toLowerCase() !=
          tenant.tenantName.trim().toLowerCase()) {
        continue;
      }
      final tenantRef = tenant.propertyRef.trim();
      final incomeRef = row.propertyRef.trim();
      if (tenantRef.isNotEmpty &&
          incomeRef.isNotEmpty &&
          tenantRef != incomeRef) {
        continue;
      }
      sum += row.amountValue;
    }
    return sum;
  }

  static DateTime? _parseDate(String v) {
    try {
      final d = DateTime.parse(v);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  static int _monthsBetween(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) months -= 1;
    return months < 0 ? 0 : months;
  }
}

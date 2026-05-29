import '../../data/local/db/tenant_local_data_source.dart';
import 'tenant_rent_billing.dart';

/// One tenant's expected rent per calendar month (1–12) for a given year.
class TenantExpectedPaymentRow {
  const TenantExpectedPaymentRow({
    required this.tenantName,
    required this.unitLabel,
    required this.monthlyAmounts,
    required this.yearTotal,
  });

  final String tenantName;
  final String unitLabel;
  final List<double> monthlyAmounts;
  final double yearTotal;
}

/// Expected rent due per month for one property (all tenants on that listing).
class PropertyExpectedPaymentSchedule {
  const PropertyExpectedPaymentSchedule({
    required this.propertyKey,
    required this.propertyLabel,
    required this.monthlyAmounts,
    required this.yearTotal,
    required this.tenantRows,
  });

  final String propertyKey;
  final String propertyLabel;
  final List<double> monthlyAmounts;
  final double yearTotal;
  final List<TenantExpectedPaymentRow> tenantRows;
}

/// Portfolio-wide expected rent schedule for one calendar year.
class ExpectedPaymentScheduleSnapshot {
  const ExpectedPaymentScheduleSnapshot({
    required this.year,
    required this.properties,
    required this.monthTotals,
    required this.grandTotal,
  });

  final int year;
  final List<PropertyExpectedPaymentSchedule> properties;
  final List<double> monthTotals;
  final double grandTotal;

  static const monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class RentExpectedPaymentScheduleBuilder {
  const RentExpectedPaymentScheduleBuilder._();

  static ExpectedPaymentScheduleSnapshot build({
    required int year,
    required List<TenantRecord> tenants,
  }) {
    final propertyMap = <String, _PropertyAccumulator>{};

    for (final t in tenants) {
      final key = _propertyKey(t);
      final label = _propertyLabel(t);
      propertyMap.putIfAbsent(
        key,
        () => _PropertyAccumulator(key: key, label: label),
      );

      final tenantMonths = List<double>.filled(12, 0);
      for (var month = 1; month <= 12; month++) {
        final monthStart = DateTime(year, month, 1);
        final nextMonth = month == 12
            ? DateTime(year + 1, 1, 1)
            : DateTime(year, month + 1, 1);
        final expected = TenantRentBilling.revenueInCalendarMonth(
          rentAmountValue: t.rentAmountValue,
          rentFrequency: t.rentFrequency,
          leaseStartIso: t.leaseStartIso,
          leaseEndIso: t.leaseEndIso,
          monthStart: monthStart,
          nextMonthStart: nextMonth,
        );
        tenantMonths[month - 1] = expected;
        propertyMap[key]!.monthly[month - 1] += expected;
      }

      final tenantTotal = tenantMonths.fold<double>(0, (a, b) => a + b);
      if (tenantTotal > 0) {
        propertyMap[key]!.tenants.add(
          TenantExpectedPaymentRow(
            tenantName: t.tenantName.trim().isEmpty ? 'Tenant' : t.tenantName.trim(),
            unitLabel: t.unitLabel.trim(),
            monthlyAmounts: tenantMonths,
            yearTotal: tenantTotal,
          ),
        );
      }
    }

    final properties = propertyMap.values
        .map((a) => a.toSchedule())
        .where((p) => p.yearTotal > 0)
        .toList()
      ..sort((a, b) => b.yearTotal.compareTo(a.yearTotal));

    final monthTotals = List<double>.filled(12, 0);
    for (final p in properties) {
      for (var i = 0; i < 12; i++) {
        monthTotals[i] += p.monthlyAmounts[i];
      }
    }

    return ExpectedPaymentScheduleSnapshot(
      year: year,
      properties: properties,
      monthTotals: monthTotals,
      grandTotal: monthTotals.fold<double>(0, (a, b) => a + b),
    );
  }

  static String _propertyKey(TenantRecord t) {
    final ref = t.propertyRef.trim();
    if (ref.isNotEmpty) return ref;
    final label = t.propertyLabel.trim();
    if (label.isNotEmpty) return label.toLowerCase();
    return 'unassigned';
  }

  static String _propertyLabel(TenantRecord t) {
    final label = t.propertyLabel.trim();
    if (label.isNotEmpty) return label;
    final ref = t.propertyRef.trim();
    if (ref.isNotEmpty) return ref;
    return 'Unassigned property';
  }
}

class _PropertyAccumulator {
  _PropertyAccumulator({required this.key, required this.label});

  final String key;
  final String label;
  final monthly = List<double>.filled(12, 0);
  final tenants = <TenantExpectedPaymentRow>[];

  PropertyExpectedPaymentSchedule toSchedule() {
    final total = monthly.fold<double>(0, (a, b) => a + b);
    tenants.sort((a, b) => b.yearTotal.compareTo(a.yearTotal));
    return PropertyExpectedPaymentSchedule(
      propertyKey: key,
      propertyLabel: label,
      monthlyAmounts: List<double>.from(monthly),
      yearTotal: total,
      tenantRows: List<TenantExpectedPaymentRow>.from(tenants),
    );
  }
}

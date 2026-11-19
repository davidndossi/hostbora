import '../../data/local/db/income_local_data_source.dart';
import '../../data/local/db/property_local_data_source.dart';
import '../../data/local/db/tenant_local_data_source.dart';
import '../../modules/rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';
import 'tenant_rent_billing.dart';

/// A rent tenant or BnB guest with an unpaid balance that is already due.
class OverdueOccupant {
  const OverdueOccupant({
    required this.tenantId,
    required this.name,
    required this.unitLabel,
    required this.propertyLabel,
    required this.amountOwed,
    required this.daysOverdue,
    required this.phoneNumber,
    required this.workspaceType,
    required this.propertyRef,
  });

  final int tenantId;
  final String name;
  final String unitLabel;
  final String propertyLabel;
  final double amountOwed;
  final int daysOverdue;
  final String phoneNumber;
  final String workspaceType;
  final String propertyRef;

  bool get isBnb => workspaceType.trim().toLowerCase() == 'bnb';

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  /// Screenshot order: unit · property.
  String get placeLine {
    final unit = unitLabel.trim();
    final property = propertyLabel.trim();
    if (unit.isNotEmpty && property.isNotEmpty) return '$unit · $property';
    if (unit.isNotEmpty) return unit;
    return property;
  }
}

/// Builds the combined overdue list (rent arrears + unpaid BnB stays).
class OverdueOccupants {
  OverdueOccupants._();

  /// Hub ids that must never be shown to a user as a property name.
  static final RegExp _refLike = RegExp(
    r'^(local|legacy)_\d+$|^\d+$|^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Every hub id a tenant row may use for a property → that property's name.
  static Map<String, String> _propertyNamesByRef(
    List<PropertyRecord> properties,
  ) {
    final out = <String, String>{};
    for (final p in properties) {
      final name = p.propertyName.trim().isNotEmpty
          ? p.propertyName.trim()
          : p.propertyLocation.trim();
      if (name.isEmpty) continue;
      final ref = p.propertyRef.trim();
      if (ref.isNotEmpty) out[ref] = name;
      out['legacy_${p.id}'] = name;
      out['local_${p.id}'] = name;
    }
    return out;
  }

  /// Property name for the row: the real name when the property is known,
  /// otherwise the stored label unless it is only a raw id.
  static String _propertyName(
    TenantRecord tenant,
    Map<String, String> namesByRef,
  ) {
    final ref = tenant.propertyRef.trim();
    final resolved = namesByRef[ref];
    if (resolved != null && resolved.isNotEmpty) return resolved;
    final label = tenant.propertyLabel.trim();
    if (label.isEmpty || label == ref || _refLike.hasMatch(label)) return '';
    return label;
  }

  static List<OverdueOccupant> fromRecords({
    required List<TenantRecord> rentTenants,
    required List<TenantRecord> bnbTenants,
    required List<IncomeRecord> incomes,
    List<PropertyRecord> properties = const [],
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final names = _propertyNamesByRef(properties);
    final items = <OverdueOccupant>[
      for (final t in rentTenants)
        ?_ofTenant(
          tenant: t,
          incomes: incomes,
          today: day,
          workspaceType: 'rent',
          propertyNames: names,
        ),
      for (final t in bnbTenants)
        ?_ofTenant(
          tenant: t,
          incomes: incomes,
          today: day,
          workspaceType: 'bnb',
          propertyNames: names,
        ),
    ];
    items.sort((a, b) {
      final byDays = b.daysOverdue.compareTo(a.daysOverdue);
      if (byDays != 0) return byDays;
      return b.amountOwed.compareTo(a.amountOwed);
    });
    return items;
  }

  static OverdueOccupant? _ofTenant({
    required TenantRecord tenant,
    required List<IncomeRecord> incomes,
    required DateTime today,
    required String workspaceType,
    required Map<String, String> propertyNames,
  }) {
    final start = TenantLedgerFinance.parseIsoDate(tenant.leaseStartIso);
    if (start == null || start.isAfter(today)) return null;

    var paid = 0.0;
    for (final row in incomes) {
      if (!TenantLedgerFinance.incomeMatchesTenant(row, tenant)) continue;
      paid += row.amountValue;
    }

    final freq = tenant.rentFrequency.trim().toLowerCase();
    final stayLike = workspaceType == 'bnb' ||
        freq == 'per stay' ||
        freq == 'per day' ||
        freq == 'per night';

    final expected = stayLike
        ? TenantLedgerFinance.totalDueTsh(tenant).toDouble()
        : _expectedToDate(
            tenant: tenant,
            start: start,
            today: today,
          );
    final owed = expected - paid;
    if (owed < 1) return null;

    final dueOn = stayLike
        ? start
        : _firstUnpaidDueDate(
            start: start,
            rate: tenant.rentAmountValue,
            paid: paid,
            today: today,
          );
    if (dueOn == null || dueOn.isAfter(today)) return null;
    final days = today.difference(dueOn).inDays;
    return OverdueOccupant(
      tenantId: tenant.id,
      name: tenant.tenantName.trim(),
      unitLabel: tenant.unitLabel.trim(),
      propertyLabel: _propertyName(tenant, propertyNames),
      amountOwed: owed,
      daysOverdue: days < 1 ? 1 : days,
      phoneNumber: tenant.phoneNumber.trim(),
      workspaceType: workspaceType,
      propertyRef: tenant.propertyRef.trim(),
    );
  }

  static double _expectedToDate({
    required TenantRecord tenant,
    required DateTime start,
    required DateTime today,
  }) {
    final end = TenantLedgerFinance.parseIsoDate(tenant.leaseEndIso);
    final last = end != null && end.isBefore(today) ? end : today;
    var expected = 0.0;
    var cursor = DateTime(start.year, start.month, start.day);
    while (!cursor.isAfter(last)) {
      final monthStart = DateTime(cursor.year, cursor.month, 1);
      final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
      expected += TenantRentBilling.revenueInCalendarMonth(
        rentAmountValue: tenant.rentAmountValue,
        rentFrequency: tenant.rentFrequency,
        leaseStartIso: tenant.leaseStartIso,
        leaseEndIso: tenant.leaseEndIso,
        monthStart: monthStart,
        nextMonthStart: nextMonth,
      );
      cursor = _addMonthsKeepingDay(start, cursor, 1);
    }
    return expected;
  }

  static DateTime? _firstUnpaidDueDate({
    required DateTime start,
    required double rate,
    required double paid,
    required DateTime today,
  }) {
    if (rate <= 0) return start.isAfter(today) ? null : start;
    final covered = (paid / rate).floor();
    var due = start;
    for (var i = 0; i < covered; i++) {
      due = _addMonthsKeepingDay(start, due, 1);
    }
    return due;
  }

  static DateTime _addMonthsKeepingDay(
    DateTime original,
    DateTime from,
    int months,
  ) {
    final m = from.month + months;
    final y = from.year + (m - 1) ~/ 12;
    final month = ((m - 1) % 12) + 1;
    final lastDay = DateTime(y, month + 1, 0).day;
    final day = original.day <= lastDay ? original.day : lastDay;
    return DateTime(y, month, day);
  }
}

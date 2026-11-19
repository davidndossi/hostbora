import 'package:intl/intl.dart';

import '../../../core/utils/expected_month_rent.dart';
import '../../../core/utils/overdue_occupants.dart';
import '../../../core/utils/property_unit_count.dart';
import '../../../core/utils/tenant_rent_billing.dart';
import '../../../modules/rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';
import '../../model/check_in_item.dart';
import '../db/expense_local_data_source.dart';
import '../db/income_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import 'portfolio_ai_context.dart';

/// Builds [PortfolioAiContext] from local rows plus optional remote extras.
class PortfolioAiContextAssembler {
  PortfolioAiContextAssembler._();

  static final _monthFmt = DateFormat('MMMM yyyy');

  static PortfolioAiContext assemble({
    required String workspace,
    required List<PropertyRecord> properties,
    required List<TenantRecord> tenants,
    required List<IncomeRecord> incomes,
    required List<ExpenseRecord> expenses,
    List<CheckInItem> bookings = const [],
    int maintenanceTasks = 0,
    int? remoteActiveBookings,
    bool includedRemote = false,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);
    final monthStart = DateTime(at.year, at.month, 1);
    final monthEnd = DateTime(at.year, at.month + 1, 1);
    final prevStart = DateTime(at.year, at.month - 1, 1);
    final threshold30 = today.add(const Duration(days: 30));
    final isBnb = workspace == 'bnb';

    final names = <String>[];
    var totalUnits = 0;
    for (final p in properties) {
      totalUnits += _unitsOf(p);
      final label = _propertyLabel(p);
      if (label.isNotEmpty) names.add(label);
    }
    if (totalUnits <= 0 && properties.isNotEmpty) {
      totalUnits = properties.length;
    }

    final monthIncome = _monthCollectedIncome(
      incomes: incomes,
      tenants: tenants,
      monthStart: monthStart,
      monthEnd: monthEnd,
    );
    final prevMonthIncome = _monthCollectedIncome(
      incomes: incomes,
      tenants: tenants,
      monthStart: prevStart,
      monthEnd: monthStart,
    );
    final monthExpenses = _sumExpensesIn(expenses, monthStart, monthEnd);
    final prevMonthExpenses = _sumExpensesIn(expenses, prevStart, monthStart);

    var activeTenants = 0;
    var leasesExpiring = 0;
    var occupiedFromTenants = 0;
    var monthExpected = 0.0;

    for (final t in tenants) {
      if (!t.isActiveTenancy) continue;
      final start = _parseDay(t.leaseStartIso);
      final end = _parseDay(t.leaseEndIso);
      final active = start != null &&
          !start.isAfter(today) &&
          (end == null || !end.isBefore(today));
      if (active) {
        activeTenants++;
        occupiedFromTenants++;
        monthExpected += ExpectedMonthRent.of(
          t,
          monthStart: monthStart,
          nextMonthStart: monthEnd,
        );
      }
      if (end != null &&
          (end.isAfter(today) || end.isAtSameMomentAs(today)) &&
          !end.isAfter(threshold30)) {
        leasesExpiring++;
      }
    }

    var activeBookings = 0;
    var checkInsToday = 0;
    var checkOutsToday = 0;
    if (isBnb) {
      for (final b in bookings) {
        if (b.isInactive) continue;
        final ci = _parseDay(b.checkInIso);
        final co = _parseDay(b.checkOutIso);
        if (ci == null || co == null) continue;
        if (_stayOverlapsDay(ci, co, today)) activeBookings++;
        if (ci == today) checkInsToday++;
        if (co == today) checkOutsToday++;
      }
      if (remoteActiveBookings != null && remoteActiveBookings > activeBookings) {
        activeBookings = remoteActiveBookings;
      }
    }

    var occupiedUnits = isBnb
        ? (totalUnits > 0
            ? activeBookings.clamp(0, totalUnits)
            : activeBookings)
        : occupiedFromTenants;
    if (!isBnb && totalUnits > 0) {
      occupiedUnits = occupiedUnits.clamp(0, totalUnits);
    }

    final occupancy = totalUnits > 0
        ? ((occupiedUnits / totalUnits) * 100).clamp(0.0, 100.0)
        : (activeTenants > 0 ? 100.0 : 0.0);

    final overdue = OverdueOccupants.fromRecords(
      rentTenants: isBnb ? const [] : tenants,
      bnbTenants: isBnb ? tenants : const [],
      incomes: incomes,
      now: today,
    );
    final arrearsRows = [
      for (final o in overdue.take(8))
        PortfolioAiArrearsRow(
          name: o.name,
          place: o.placeLine,
          amount: o.amountOwed,
        ),
    ];
    var arrearsTotal = 0.0;
    for (final o in overdue) {
      arrearsTotal += o.amountOwed;
    }

    final collectionRate = monthExpected > 0
        ? ((monthIncome / monthExpected) * 100).clamp(0.0, 999.0)
        : 0.0;

    final slices = _propertySlices(
      properties: properties,
      tenants: tenants,
      incomes: incomes,
      expenses: expenses,
      bookings: bookings,
      isBnb: isBnb,
      today: today,
      monthStart: monthStart,
      monthEnd: monthEnd,
    );

    return PortfolioAiContext(
      workspace: workspace,
      monthLabel: _monthFmt.format(at),
      prevMonthLabel: _monthFmt.format(prevStart),
      propertyCount: properties.length,
      totalUnits: totalUnits,
      occupiedUnits: occupiedUnits,
      occupancyPercent: occupancy,
      activeTenants: activeTenants,
      monthIncome: monthIncome,
      monthExpenses: monthExpenses,
      monthNet: monthIncome - monthExpenses,
      monthExpected: monthExpected,
      collectionRatePercent: collectionRate,
      prevMonthIncome: prevMonthIncome,
      prevMonthExpenses: prevMonthExpenses,
      arrearsTenantCount: overdue.length,
      arrearsTotal: arrearsTotal,
      leasesExpiring30Days: leasesExpiring,
      activeBookingsToday: activeBookings,
      checkInsToday: checkInsToday,
      checkOutsToday: checkOutsToday,
      maintenanceTasks: maintenanceTasks,
      propertyNames: names.take(8).toList(),
      expenseCategories: _expenseBuckets(expenses, monthStart, monthEnd),
      properties: slices,
      arrearsRows: arrearsRows,
      includedRemote: includedRemote,
    );
  }

  static List<PortfolioAiPropertySlice> _propertySlices({
    required List<PropertyRecord> properties,
    required List<TenantRecord> tenants,
    required List<IncomeRecord> incomes,
    required List<ExpenseRecord> expenses,
    required List<CheckInItem> bookings,
    required bool isBnb,
    required DateTime today,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) {
    final out = <PortfolioAiPropertySlice>[];
    for (final p in properties) {
      final units = _unitsOf(p);
      final onProperty = tenants.where((t) => _tenantMatchesProperty(t, p)).toList();
      var occupied = 0;
      var expected = 0.0;
      var income = 0.0;
      for (final t in onProperty) {
        if (!t.isActiveTenancy) continue;
        final start = _parseDay(t.leaseStartIso);
        final end = _parseDay(t.leaseEndIso);
        final active = start != null &&
            !start.isAfter(today) &&
            (end == null || !end.isBefore(today));
        if (!active) continue;
        occupied++;
        expected += ExpectedMonthRent.of(
          t,
          monthStart: monthStart,
          nextMonthStart: monthEnd,
        );
        var paidTotal = 0.0;
        for (final r in incomes) {
          if (TenantLedgerFinance.incomeMatchesTenant(r, t)) paidTotal += r.amountValue;
        }
        income += TenantRentBilling.collectedInCalendarMonth(
          rentAmountValue: t.rentAmountValue,
          rentFrequency: t.rentFrequency,
          leaseStartIso: t.leaseStartIso,
          leaseEndIso: t.leaseEndIso,
          paidTotal: paidTotal,
          monthStart: monthStart,
          nextMonthStart: monthEnd,
        );
      }
      if (isBnb) {
        occupied = 0;
        for (final b in bookings) {
          if (b.isInactive) continue;
          if (!_bookingMatchesProperty(b, p)) continue;
          final ci = _parseDay(b.checkInIso);
          final co = _parseDay(b.checkOutIso);
          if (ci == null || co == null) continue;
          if (_stayOverlapsDay(ci, co, today)) occupied++;
        }
      }
      if (units > 0) occupied = occupied.clamp(0, units);
      var unassignedIncome = 0.0;
      for (final r in incomes) {
        if (!_incomeMatchesProperty(r, p)) continue;
        final matchedTenant = onProperty.any(
          (t) => TenantLedgerFinance.incomeMatchesTenant(r, t),
        );
        if (matchedTenant) continue;
        final d = r.paidLocalCalendarOrCreated();
        if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
          unassignedIncome += r.amountValue;
        }
      }
      income += unassignedIncome;

      var propertyExpenses = 0.0;
      for (final e in expenses) {
        if (!_expenseMatchesProperty(e, p)) continue;
        final d = e.paidLocalCalendarOrCreated();
        if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
          propertyExpenses += e.amountValue;
        }
      }

      final occ = units > 0 ? ((occupied / units) * 100).clamp(0.0, 100.0) : 0.0;
      out.add(
        PortfolioAiPropertySlice(
          name: _propertyLabel(p),
          propertyRef: p.propertyRef,
          units: units > 0 ? units : 1,
          occupied: occupied,
          occupancyPercent: occ,
          monthIncome: income,
          monthExpenses: propertyExpenses,
          monthExpected: expected,
        ),
      );
    }
    out.sort((a, b) => b.occupancyPercent.compareTo(a.occupancyPercent));
    return out.take(8).toList();
  }

  static List<PortfolioAiExpenseBucket> _expenseBuckets(
    List<ExpenseRecord> expenses,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    final totals = <String, double>{};
    for (final e in expenses) {
      final d = e.paidLocalCalendarOrCreated();
      if (d.isBefore(monthStart) || !d.isBefore(monthEnd)) continue;
      final key = e.category.trim().isEmpty ? 'Other' : e.category.trim();
      totals[key] = (totals[key] ?? 0) + e.amountValue;
    }
    final buckets = [
      for (final e in totals.entries)
        PortfolioAiExpenseBucket(category: e.key, amount: e.value),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return buckets.take(6).toList();
  }

  static double _monthCollectedIncome({
    required List<IncomeRecord> incomes,
    required List<TenantRecord> tenants,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) {
    var collected = 0.0;
    final matchedIds = <int>{};
    for (final t in tenants) {
      var paidTotal = 0.0;
      for (final r in incomes) {
        if (!TenantLedgerFinance.incomeMatchesTenant(r, t)) continue;
        paidTotal += r.amountValue;
        matchedIds.add(r.id);
      }
      collected += TenantRentBilling.collectedInCalendarMonth(
        rentAmountValue: t.rentAmountValue,
        rentFrequency: t.rentFrequency,
        leaseStartIso: t.leaseStartIso,
        leaseEndIso: t.leaseEndIso,
        paidTotal: paidTotal,
        monthStart: monthStart,
        nextMonthStart: monthEnd,
      );
    }
    for (final r in incomes) {
      if (matchedIds.contains(r.id)) continue;
      final d = r.paidLocalCalendarOrCreated();
      if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
        collected += r.amountValue;
      }
    }
    return collected;
  }

  static double _sumExpensesIn(
    List<ExpenseRecord> expenses,
    DateTime start,
    DateTime end,
  ) {
    var sum = 0.0;
    for (final r in expenses) {
      final d = r.paidLocalCalendarOrCreated();
      if (!d.isBefore(start) && d.isBefore(end)) sum += r.amountValue;
    }
    return sum;
  }

  static int _unitsOf(PropertyRecord p) {
    final n = PropertyUnitCount.of(p);
    return n > 0 ? n : 0;
  }

  static String _propertyLabel(PropertyRecord r) {
    final suite = r.propertyName.trim();
    final loc = r.propertyLocation.trim();
    if (suite.isNotEmpty && loc.isNotEmpty) return '$loc · $suite';
    return suite.isNotEmpty ? suite : loc;
  }

  static bool _tenantMatchesProperty(TenantRecord t, PropertyRecord p) {
    final ref = t.propertyRef.trim();
    final pRef = p.propertyRef.trim();
    if (ref.isNotEmpty && pRef.isNotEmpty) {
      return ref == pRef || ref == 'legacy_${p.id}' || ref == 'local_${p.id}';
    }
    if (ref == 'legacy_${p.id}' || ref == 'local_${p.id}') return true;
    final label = t.propertyLabel.trim().toLowerCase();
    if (label.isEmpty) return false;
    final loc = p.propertyLocation.trim().toLowerCase();
    final name = p.propertyName.trim().toLowerCase();
    final line = loc.isNotEmpty && name.isNotEmpty
        ? '$loc · $name'
        : (loc.isNotEmpty ? loc : name);
    return label == line || label.contains(loc) || line.contains(label);
  }

  static bool _incomeMatchesProperty(IncomeRecord r, PropertyRecord p) {
    final ref = r.propertyRef.trim();
    final pRef = p.propertyRef.trim();
    if (ref.isNotEmpty && pRef.isNotEmpty) return ref == pRef;
    final apt = r.apartment.trim().toLowerCase();
    if (apt.isEmpty) return false;
    final loc = p.propertyLocation.trim().toLowerCase();
    final name = p.propertyName.trim().toLowerCase();
    final label = _propertyLabel(p).toLowerCase();
    return apt == label || apt == loc || apt == name ||
        (name.isNotEmpty && apt.contains(name));
  }

  static bool _expenseMatchesProperty(ExpenseRecord e, PropertyRecord p) {
    final apt = e.apartment.trim().toLowerCase();
    if (apt.isEmpty) return false;
    final loc = p.propertyLocation.trim().toLowerCase();
    final name = p.propertyName.trim().toLowerCase();
    final label = _propertyLabel(p).toLowerCase();
    return apt == label || apt == loc || apt == name ||
        (name.isNotEmpty && apt.contains(name));
  }

  static bool _bookingMatchesProperty(CheckInItem b, PropertyRecord p) {
    final listing = (b.listingId ?? '').trim();
    final pRef = p.propertyRef.trim();
    if (listing.isNotEmpty && pRef.isNotEmpty && listing == pRef) return true;
    final type = b.propertyType.trim().toLowerCase();
    if (type.isEmpty) return false;
    final name = p.propertyName.trim().toLowerCase();
    final loc = p.propertyLocation.trim().toLowerCase();
    return type == name || type == loc || type.contains(name);
  }

  static DateTime? _parseDay(String raw) {
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
    final p = DateTime.tryParse(t);
    if (p == null) return null;
    return DateTime(p.year, p.month, p.day);
  }

  static bool _stayOverlapsDay(DateTime checkIn, DateTime checkOut, DateTime day) {
    return !checkIn.isAfter(day) && checkOut.isAfter(day);
  }
}

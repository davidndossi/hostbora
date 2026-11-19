import '../../data/local/db/income_local_data_source.dart';
import '../../data/local/db/tenant_local_data_source.dart';
import '../../data/model/rewards_dashboard.dart';
import '../../modules/rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';
import 'tenant_rent_billing.dart';
import 'unlinked_payments.dart';

/// This calendar month's expected vs collected rent, including prepaid months.
class MonthRentCollection {
  const MonthRentCollection({
    required this.expected,
    required this.collected,
    this.otherIncome = 0,
  });

  final double expected;
  final double collected;

  /// Cash dated in the month that isn't tied to a tenant. Not part of
  /// [collected] (so it can't inflate the collection %), but it is real
  /// income for finance totals.
  final double otherIncome;

  /// All money received in the month: rent collected plus other income.
  double get totalIncome => collected + otherIncome;

  int get pct {
    if (collected <= 0) return 0;
    if (expected <= 0) return 100;
    return ((collected / expected) * 100).round().clamp(0, 100);
  }

  static MonthRentCollection fromRecords({
    required List<TenantRecord> tenants,
    required List<IncomeRecord> incomes,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final monthStart = DateTime(clock.year, clock.month, 1);
    final nextMonthStart = DateTime(clock.year, clock.month + 1, 1);
    var expected = 0.0;
    var collected = 0.0;
    var otherIncome = 0.0;
    final matchedIds = <int>{};
    for (final tenant in tenants) {
      expected += TenantRentBilling.revenueInCalendarMonth(
        rentAmountValue: tenant.rentAmountValue,
        rentFrequency: tenant.rentFrequency,
        leaseStartIso: tenant.leaseStartIso,
        leaseEndIso: tenant.leaseEndIso,
        monthStart: monthStart,
        nextMonthStart: nextMonthStart,
      );
      var paidTotal = 0.0;
      for (final row in incomes) {
        if (!TenantLedgerFinance.incomeMatchesTenant(row, tenant)) continue;
        paidTotal += row.amountValue;
        if (row.id > 0) matchedIds.add(row.id);
      }
      collected += TenantRentBilling.collectedInCalendarMonth(
        rentAmountValue: tenant.rentAmountValue,
        rentFrequency: tenant.rentFrequency,
        leaseStartIso: tenant.leaseStartIso,
        leaseEndIso: tenant.leaseEndIso,
        paidTotal: paidTotal,
        monthStart: monthStart,
        nextMonthStart: nextMonthStart,
      );
    }
    for (final row in incomes) {
      if (matchedIds.contains(row.id)) continue;
      final paid = row.paidLocalCalendarOrCreated();
      final day = DateTime(paid.year, paid.month, paid.day);
      if (day.isBefore(monthStart) || !day.isBefore(nextMonthStart)) continue;
      // Payments with no tenant can't be allocated to a month; they are
      // reported as "other income" rather than rent collected.
      if (UnlinkedPayments.countsTowardCollection(row)) {
        collected += row.amountValue;
      } else {
        otherIncome += row.amountValue;
      }
    }
    return MonthRentCollection(
      expected: expected,
      collected: collected,
      otherIncome: otherIncome,
    );
  }

  static bool isCollectionChallenge(RewardChallenge challenge) {
    final key = challenge.key.toLowerCase();
    final title = challenge.title.toLowerCase();
    return key.contains('collection') ||
        title.contains('collection') ||
        title.contains('ukusanyaji');
  }

  RewardsDashboard applyTo(RewardsDashboard dashboard) {
    if (expected <= 0 && collected <= 0) return dashboard;
    final next = <RewardChallenge>[];
    var changed = false;
    for (final challenge in dashboard.challenges) {
      if (!isCollectionChallenge(challenge) || challenge.pct >= pct) {
        next.add(challenge);
        continue;
      }
      changed = true;
      next.add(
        RewardChallenge(
          key: challenge.key,
          title: challenge.title,
          description: challenge.description,
          pct: pct,
          current: collected,
          target: expected > 0 ? expected : challenge.target,
          unit: challenge.unit.trim().isEmpty ? 'TZS' : challenge.unit,
          complete: pct >= 100 || challenge.complete,
        ),
      );
    }
    if (!changed) return dashboard;
    return RewardsDashboard(
      balance: dashboard.balance,
      smsCredits: dashboard.smsCredits,
      academyCompleted: dashboard.academyCompleted,
      challenges: next,
      earn: dashboard.earn,
      catalog: dashboard.catalog,
      achievements: dashboard.achievements,
    );
  }
}

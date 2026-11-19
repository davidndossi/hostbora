import '../../data/local/db/income_local_data_source.dart';
import '../../data/local/db/tenant_local_data_source.dart';
import '../../modules/rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';

/// Payments that no tenant owns, and how they are treated in rent collection.
///
/// A rent payment only reduces "yet to collect" once it is tied to a tenant,
/// because that is what lets it be allocated to the right months (a six-month
/// prepayment covers six months, an overpayment is capped per month). Payments
/// without a tenant are reported separately instead of being added wholesale
/// to the month they happened to be paid in.
abstract final class UnlinkedPayments {
  static bool isBnb(IncomeRecord r) =>
      r.workspaceType.trim().toLowerCase() == 'bnb';

  /// BnB income is received per booking, not per tenant lease, so it still
  /// counts as collected when it matches no tenant. Anything else that matches
  /// no tenant is "other income" and stays out of rent collection.
  static bool countsTowardCollection(IncomeRecord r) => isBnb(r);

  /// Rent-workspace payments with no tenant link, newest first.
  ///
  /// Yields to the event loop regularly: matching is tenants x payments, and
  /// this runs on Home, which must stay responsive.
  static Future<List<IncomeRecord>> find({
    required List<TenantRecord> tenants,
    required List<IncomeRecord> incomes,
  }) async {
    final out = <IncomeRecord>[];
    var visited = 0;
    for (final r in incomes) {
      if (++visited % 25 == 0) await Future<void>.delayed(Duration.zero);
      if (isBnb(r)) continue;
      if (r.tenantId > 0) continue;
      if (tenants.any((t) => TenantLedgerFinance.incomeMatchesTenant(r, t))) {
        continue;
      }
      out.add(r);
    }
    return out;
  }
}

import 'package:get/get.dart';

import '../../data/local/db/expense_local_data_source.dart';
import '../../data/local/db/income_local_data_source.dart';
import '../../data/local/preference/preference_manager.dart';
import '../../data/local/db/property_local_data_source.dart';
import 'plan_agents.dart';

/// What the signed-in plan is currently withholding from the host.
///
/// Every figure is read from the device's own database, so the upgrade prompt
/// can name a real amount instead of a generic promise. That matters both ways:
/// a host with months of records gets a concrete number, and a host with
/// nothing recorded yet gets no claim at all rather than an invented one —
/// see [hasHiddenHistory].
class PlanLossSnapshot {
  const PlanLossSnapshot({
    required this.hiddenIncomeCount,
    required this.hiddenIncomeTotal,
    required this.hiddenExpenseCount,
    required this.hiddenExpenseTotal,
    required this.monthsOnDevice,
    required this.propertyCount,
  });

  const PlanLossSnapshot.empty()
      : hiddenIncomeCount = 0,
        hiddenIncomeTotal = 0,
        hiddenExpenseCount = 0,
        hiddenExpenseTotal = 0,
        monthsOnDevice = 0,
        propertyCount = 0;

  /// Payments dated before the current calendar month, which the Free plan
  /// filters out of every list via [PlanAccess.isInPlanHistory].
  final int hiddenIncomeCount;
  final double hiddenIncomeTotal;

  final int hiddenExpenseCount;
  final double hiddenExpenseTotal;

  /// Calendar months spanned by the records on this device, inclusive. One
  /// means everything was recorded this month and nothing is being withheld.
  final int monthsOnDevice;

  final int propertyCount;

  int get hiddenRecordCount => hiddenIncomeCount + hiddenExpenseCount;

  /// Gates the loss figures in the UI. Without this a brand-new account would
  /// be told it is losing "Tsh 0 across 0 payments", which is both useless and
  /// a reason to distrust every other number in the sheet.
  bool get hasHiddenHistory => hiddenRecordCount > 0;

  /// Reads the whole picture off the device, degrading to [empty] rather than
  /// throwing: the upgrade prompt must still open if a table is unavailable.
  static Future<PlanLossSnapshot> load({DateTime? now}) async {
    try {
      final clock = now ?? DateTime.now();
      final monthStart = DateTime(clock.year, clock.month, 1);

      final income = await _incomeRows();
      final expenses = await _expenseRows();

      var hiddenIncomeCount = 0;
      var hiddenIncomeTotal = 0.0;
      var hiddenExpenseCount = 0;
      var hiddenExpenseTotal = 0.0;
      DateTime? earliest;

      void track(DateTime day) {
        if (earliest == null || day.isBefore(earliest!)) earliest = day;
      }

      for (final row in income) {
        final paid = row.paidLocalCalendarOrCreated();
        final day = DateTime(paid.year, paid.month, paid.day);
        track(day);
        if (day.isBefore(monthStart)) {
          hiddenIncomeCount++;
          // amountValue is already stored in the base currency.
          hiddenIncomeTotal += row.amountValue;
        }
      }
      for (final row in expenses) {
        final paid = row.paidLocalCalendarOrCreated();
        final day = DateTime(paid.year, paid.month, paid.day);
        track(day);
        if (day.isBefore(monthStart)) {
          hiddenExpenseCount++;
          hiddenExpenseTotal += row.amountValue;
        }
      }

      return PlanLossSnapshot(
        hiddenIncomeCount: hiddenIncomeCount,
        hiddenIncomeTotal: hiddenIncomeTotal,
        hiddenExpenseCount: hiddenExpenseCount,
        hiddenExpenseTotal: hiddenExpenseTotal,
        monthsOnDevice: _monthSpan(earliest, monthStart),
        propertyCount: await _propertyCount(),
      );
    } catch (_) {
      return const PlanLossSnapshot.empty();
    }
  }

  /// Inclusive count of calendar months from the first record to this one.
  static int _monthSpan(DateTime? earliest, DateTime monthStart) {
    if (earliest == null) return 0;
    final from = DateTime(earliest.year, earliest.month);
    final months = (monthStart.year - from.year) * 12 +
        (monthStart.month - from.month) +
        1;
    return months < 1 ? 1 : months;
  }

  static Future<List<IncomeRecord>> _incomeRows() async {
    if (!Get.isRegistered<IncomeLocalDataSource>()) return const [];
    try {
      return await Get.find<IncomeLocalDataSource>().getAllNewestFirst();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<ExpenseRecord>> _expenseRows() async {
    if (!Get.isRegistered<ExpenseLocalDataSource>()) return const [];
    try {
      return await Get.find<ExpenseLocalDataSource>().getAllNewestFirst();
    } catch (_) {
      return const [];
    }
  }

  /// Mirrors the count the property cap is enforced against, so the sheet and
  /// the gate can never disagree about how many properties the host has.
  static Future<int> _propertyCount() async {
    if (!Get.isRegistered<PropertyLocalDataSource>()) return 0;
    try {
      var userId = '';
      try {
        final prefs = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        );
        userId = (await prefs.getUser()).id?.trim() ?? '';
      } catch (_) {}
      final local = Get.find<PropertyLocalDataSource>();
      final ids = <int>{};
      for (final workspace in const ['bnb', 'rent']) {
        final rows = await local.getAllVisibleNewestFirst(
          userId: userId,
          workspaceType: workspace,
        );
        for (final row in rows) {
          ids.add(row.id);
        }
      }
      return ids.length;
    } catch (_) {
      return 0;
    }
  }
}

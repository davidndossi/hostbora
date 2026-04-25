import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_expense_local_data_source.dart';
import '../../../../data/local/db/rent_property_local_data_source.dart';
import '../../../../data/local/db/rent_utility_topup_local_data_source.dart';

enum UtilityActivityType { lukuTopUp, waterBill, other }

class UtilityActivityItem {
  const UtilityActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.impactLabel,
    required this.amountLabel,
    required this.isPositive,
  });

  final UtilityActivityType type;
  final String title;
  final String subtitle;
  final String impactLabel;
  final String amountLabel;
  final bool isPositive;
}

class RentSmartUtilityDashboardController extends BaseController {
  RentSmartUtilityDashboardController()
      : _expenseLocal = Get.find<RentExpenseLocalDataSource>(),
        _propertyLocal = Get.find<RentPropertyLocalDataSource>(),
        _topUpLocal = Get.find<RentUtilityTopUpLocalDataSource>();

  final RentExpenseLocalDataSource _expenseLocal;
  final RentPropertyLocalDataSource _propertyLocal;
  final RentUtilityTopUpLocalDataSource _topUpLocal;

  final loading = true.obs;
  final unitLabel = 'UNIT 402'.obs;
  final editorialName = 'The Concierge Editorial'.obs;
  final trustScore = 9.8.obs;
  final globalStatus = 'Active'.obs;
  final propertyLabel = ''.obs;

  // LUKU electricity (kWh).
  final lukuUnits = 0.0.obs;
  final lukuCapacity = 250.0.obs;
  final lukuCoverageDays = 0.obs;

  // Water (liters).
  final waterLiters = 0.0.obs;
  final waterCapacity = 6000.0.obs;
  final nextMeterReadingLabel = ''.obs;

  // 7 days usage (Mon..Sun) scaled for chart.
  final weeklyUsage = <double>[0, 0, 0, 0, 0, 0, 0].obs;

  final activities = <UtilityActivityItem>[].obs;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  static const _avgDailyKwh = 12.0;

  @override
  void onReady() {
    super.onReady();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    try {
      final properties = await _propertyLocal.getAllNewestFirst();
      if (properties.isNotEmpty) {
        final p = properties.first;
        final loc = p.propertyLocation.trim();
        if (loc.isNotEmpty) {
          unitLabel.value = 'UNIT · ${loc.toUpperCase()}';
          propertyLabel.value = loc;
        }
        final suite = p.apartmentSuite.trim();
        if (suite.isNotEmpty) {
          unitLabel.value = 'UNIT · ${suite.toUpperCase()}';
          propertyLabel.value = suite.isEmpty ? propertyLabel.value : suite;
        }
      }

      final topUps = await _topUpLocal.getAllNewestFirst();
      final lukuTotal = topUps
          .where((t) => t.kind == RentUtilityKind.luku)
          .fold<double>(0, (a, b) => a + b.unitsAdded);
      final waterTotal = topUps
          .where((t) => t.kind == RentUtilityKind.water)
          .fold<double>(0, (a, b) => a + b.unitsAdded);

      if (lukuTotal > 0) {
        lukuUnits.value = lukuTotal;
        lukuCapacity.value = lukuTotal < 250 ? 250 : lukuTotal * 1.1;
        lukuCoverageDays.value = (lukuTotal / _avgDailyKwh).floor();
      } else {
        lukuUnits.value = 142.5;
        lukuCapacity.value = 250;
        lukuCoverageDays.value = 12;
      }

      if (waterTotal > 0) {
        waterLiters.value = waterTotal;
        waterCapacity.value = waterTotal < 6000 ? 6000 : waterTotal * 1.1;
      } else {
        waterLiters.value = 4280;
        waterCapacity.value = 6000;
      }

      final nextRead = DateTime.now().add(const Duration(days: 7));
      nextMeterReadingLabel.value = _isSw
          ? 'Soma ijayo la mita: ${DateFormat('d MMM').format(nextRead)}'
          : 'Next meter reading: ${DateFormat('d MMM').format(nextRead)}';

      _buildActivityFeed(topUps);
      _updateWeeklyTrend(topUps);

      // Fall back to utility expenses for any remaining activity context.
      if (activities.isEmpty) {
        final expenses = await _expenseLocal.getAllNewestFirst();
        final utilityExpenses =
            expenses.where((e) => e.category.trim() == 'Utilities').toList();
        if (utilityExpenses.isNotEmpty) {
          _buildActivityFromExpenses(utilityExpenses);
        }
      }

      if (activities.isEmpty) {
        _seedDefaultActivities();
      }
    } finally {
      loading.value = false;
    }
  }

  void _buildActivityFeed(List<RentUtilityTopUpRecord> topUps) {
    final items = <UtilityActivityItem>[];
    final money = NumberFormat('#,###', 'en_US');

    for (final t in topUps.take(10)) {
      final date = DateTime.tryParse(t.dateIso);
      final dateLabel =
          date == null ? '' : DateFormat('MMM d').format(date);
      final provider = t.provider.trim().isEmpty
          ? (_isSw ? 'Pesa kwa Simu' : 'Mobile Money')
          : t.provider.trim();
      if (t.kind == RentUtilityKind.luku) {
        items.add(
          UtilityActivityItem(
            type: UtilityActivityType.lukuTopUp,
            title: _isSw ? 'Malipo ya LUKU' : 'LUKU Top-up',
            subtitle: _isSw
                ? 'Kupitia $provider${dateLabel.isEmpty ? '' : ' • $dateLabel'}'
                : 'Via $provider${dateLabel.isEmpty ? '' : ' • $dateLabel'}',
            impactLabel: '+${t.unitsAdded.toStringAsFixed(1)} kWh',
            amountLabel: 'TZS ${money.format(t.amountTsh.round())}',
            isPositive: true,
          ),
        );
      } else if (t.kind == RentUtilityKind.water) {
        items.add(
          UtilityActivityItem(
            type: UtilityActivityType.waterBill,
            title: _isSw ? 'Ujazaji wa Maji' : 'Water Recharge',
            subtitle: _isSw
                ? 'Kupitia $provider${dateLabel.isEmpty ? '' : ' • $dateLabel'}'
                : 'Via $provider${dateLabel.isEmpty ? '' : ' • $dateLabel'}',
            impactLabel: '+${t.unitsAdded.toStringAsFixed(0)} L',
            amountLabel: 'TZS ${money.format(t.amountTsh.round())}',
            isPositive: true,
          ),
        );
      }
    }

    activities.assignAll(items);
  }

  void _buildActivityFromExpenses(List<RentExpenseRecord> utilityExpenses) {
    final items = <UtilityActivityItem>[];
    final money = NumberFormat('#,###', 'en_US');

    for (final e in utilityExpenses.take(6)) {
      final date = DateTime.tryParse(e.datePaidIso);
      final dateLabel = date == null ? '' : DateFormat('MMM d').format(date);
      final combined = (e.notes + e.category).toLowerCase();
      final isWater = combined.contains('water') || combined.contains('maji');
      final isLuku = combined.contains('luku') || combined.contains('umeme');

      if (isWater) {
        items.add(UtilityActivityItem(
          type: UtilityActivityType.waterBill,
          title: _isSw ? 'Bili ya Maji' : 'Water Bill',
          subtitle:
              'Auto-Debit${dateLabel.isEmpty ? '' : ' • $dateLabel'}',
          impactLabel: '${(e.amountValue / 10).round()} L',
          amountLabel: 'TZS ${money.format(e.amountValue.round())}',
          isPositive: false,
        ));
      } else if (isLuku) {
        items.add(UtilityActivityItem(
          type: UtilityActivityType.lukuTopUp,
          title: _isSw ? 'Malipo ya LUKU' : 'LUKU Top-up',
          subtitle:
              'Via Mobile Money${dateLabel.isEmpty ? '' : ' • $dateLabel'}',
          impactLabel: '+${(e.amountValue / 700).toStringAsFixed(1)} kWh',
          amountLabel: 'TZS ${money.format(e.amountValue.round())}',
          isPositive: true,
        ));
      }
    }

    activities.assignAll(items);
  }

  void _seedDefaultActivities() {
    activities.assignAll(const [
      UtilityActivityItem(
        type: UtilityActivityType.lukuTopUp,
        title: 'LUKU Top-up',
        subtitle: 'Via M-Pesa · 14:20',
        impactLabel: '+50.0 kWh',
        amountLabel: 'TZS 35,000',
        isPositive: true,
      ),
      UtilityActivityItem(
        type: UtilityActivityType.waterBill,
        title: 'Water Bill',
        subtitle: 'Auto-Debit · Oct 12',
        impactLabel: '1,200 L',
        amountLabel: 'TZS 12,500',
        isPositive: false,
      ),
      UtilityActivityItem(
        type: UtilityActivityType.lukuTopUp,
        title: 'LUKU Top-up',
        subtitle: 'Via Airtel Money · Oct 05',
        impactLabel: '+100.0 kWh',
        amountLabel: 'TZS 70,000',
        isPositive: true,
      ),
    ]);
  }

  void _updateWeeklyTrend(List<RentUtilityTopUpRecord> topUps) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final totals = List<double>.filled(7, 0);
    bool any = false;
    for (final t in topUps) {
      final d = DateTime.tryParse(t.dateIso);
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      final diff = day.difference(start).inDays;
      if (diff >= 0 && diff < 7) {
        totals[diff] += t.unitsAdded;
        any = true;
      }
    }
    if (any) {
      weeklyUsage.assignAll(totals);
    } else {
      weeklyUsage.assignAll(const [14, 18, 16, 26, 30, 36, 10]);
    }
  }

  double get lukuProgress => lukuCapacity.value <= 0
      ? 0
      : (lukuUnits.value / lukuCapacity.value).clamp(0, 1);

  double get waterProgress => waterCapacity.value <= 0
      ? 0
      : (waterLiters.value / waterCapacity.value).clamp(0, 1);

  /// Persist a LUKU electricity top-up and reload derived metrics.
  Future<void> addLukuTopUp({
    required double kwh,
    required double amountTsh,
    String provider = '',
    String notes = '',
    DateTime? date,
  }) async {
    final when = date ?? DateTime.now();
    await _topUpLocal.insert(
      kind: RentUtilityKind.luku,
      unitsAdded: kwh,
      amountTsh: amountTsh,
      provider: provider,
      notes: notes,
      propertyLabel: propertyLabel.value,
      dateIso: when.toIso8601String(),
    );
    await loadAll();
    showSuccessMessage(
      _isSw
          ? 'Umeongeza ${kwh.toStringAsFixed(1)} kWh za LUKU'
          : 'Added ${kwh.toStringAsFixed(1)} kWh of LUKU',
    );
  }

  /// Persist a water recharge and reload derived metrics.
  Future<void> addWaterTopUp({
    required double liters,
    required double amountTsh,
    String provider = '',
    String notes = '',
    DateTime? date,
  }) async {
    final when = date ?? DateTime.now();
    await _topUpLocal.insert(
      kind: RentUtilityKind.water,
      unitsAdded: liters,
      amountTsh: amountTsh,
      provider: provider,
      notes: notes,
      propertyLabel: propertyLabel.value,
      dateIso: when.toIso8601String(),
    );
    await loadAll();
    showSuccessMessage(
      _isSw
          ? 'Umeongeza ${liters.toStringAsFixed(0)} lita za maji'
          : 'Added ${liters.toStringAsFixed(0)} L of water',
    );
  }

  void onViewAllActivity() {
    showSuccessMessage(
      _isSw ? 'Inapakia historia kamili' : 'Loading full utility history',
    );
  }
}

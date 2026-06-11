import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/rent_utility_topup_local_data_source.dart';
import '../../../../data/local/service/offline_sync_worker_service.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../add_listing/models/apartment_unit_draft.dart';
import '../utils/luku_sms_ocr_parser.dart';

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
    : _expenseLocal = Get.find<ExpenseLocalDataSource>(),
      _propertyLocal = Get.find<PropertyLocalDataSource>(),
      _topUpLocal = Get.find<RentUtilityTopUpLocalDataSource>(),
      _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>();

  final ExpenseLocalDataSource _expenseLocal;
  final PropertyLocalDataSource _propertyLocal;
  final RentUtilityTopUpLocalDataSource _topUpLocal;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final loading = true.obs;
  final unitLabel = ''.obs;
  final trustScore = 0.0.obs;
  final globalStatus = ''.obs;
  final propertyLabel = ''.obs;
  final propertyRef = ''.obs;

  // LUKU electricity (kWh).
  final lukuUnits = 0.0.obs;
  final lukuCapacity = 0.0.obs;
  final lukuCoverageDays = 0.obs;

  // Water (liters).
  final waterLiters = 0.0.obs;
  final waterCapacity = 0.0.obs;
  final nextMeterReadingLabel = ''.obs;

  // 7 days usage (Mon..Sun) scaled for chart.
  final weeklyUsage = <double>[0, 0, 0, 0, 0, 0, 0].obs;

  final activities = <UtilityActivityItem>[].obs;

  /// Apartment units for the current property (empty for standalone houses).
  final availableUnits = <ApartmentUnitDraft>[].obs;

  /// Empty string means "all units / whole property".
  final selectedUnitId = ''.obs;
  final selectedUnitName = ''.obs;

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
        final ref = p.propertyRef.trim().isNotEmpty
            ? p.propertyRef.trim()
            : 'legacy_${p.id}';
        propertyRef.value = ref;
        if (loc.isNotEmpty) {
          unitLabel.value = 'UNIT · ${loc.toUpperCase()}';
          propertyLabel.value = loc;
        }
        final suite = p.apartmentSuite.trim();
        if (suite.isNotEmpty) {
          unitLabel.value = 'UNIT · ${suite.toUpperCase()}';
          propertyLabel.value = suite.isEmpty ? propertyLabel.value : suite;
        }
        _loadPropertyUnits(p.unitsJson);
      }

      final allTopUps = await _topUpLocal.getAllNewestFirst();
      // Filter to selected unit when one is chosen.
      final uid = selectedUnitId.value.trim();
      final topUps = uid.isEmpty
          ? allTopUps
          : allTopUps.where((t) => t.unitId == uid).toList();

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
        lukuUnits.value = 0.0;
        lukuCapacity.value = 0;
        lukuCoverageDays.value = 0;
      }

      if (waterTotal > 0) {
        waterLiters.value = waterTotal;
        waterCapacity.value = waterTotal < 6000 ? 6000 : waterTotal * 1.1;
      } else {
        waterLiters.value = 0;
        waterCapacity.value = 0;
      }

      _updateNextMeterReading(topUps);

      _buildActivityFeed(topUps);
      _updateWeeklyTrend(topUps);

      // Fall back to utility expenses for any remaining activity context.
      if (activities.isEmpty) {
        final expenses = await _expenseLocal.getAllNewestFirst(
          workspaceType: 'rent',
        );
        final utilityExpenses = expenses
            .where((e) => e.category.trim() == 'Utilities')
            .toList();
        if (utilityExpenses.isNotEmpty) {
          _buildActivityFromExpenses(utilityExpenses);
        }
      }

      _computeStatusAndTrust(topUps);
    } finally {
      loading.value = false;
    }
  }

  void _buildActivityFeed(List<RentUtilityTopUpRecord> topUps) {
    final items = <UtilityActivityItem>[];
    final money = NumberFormat('#,###', 'en_US');

    for (final t in topUps.take(10)) {
      final date = DateTime.tryParse(t.dateIso);
      final dateLabel = date == null ? '' : DateFormat('dd/MM').format(date);
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

  void _buildActivityFromExpenses(List<ExpenseRecord> utilityExpenses) {
    final items = <UtilityActivityItem>[];
    final money = NumberFormat('#,###', 'en_US');

    for (final e in utilityExpenses.take(6)) {
      final date = DateTime.tryParse(e.datePaidIso);
      final dateLabel = date == null ? '' : DateFormat('dd/MM').format(date);
      final combined = (e.notes + e.category).toLowerCase();
      final isWater = combined.contains('water') || combined.contains('maji');
      final isLuku = combined.contains('luku') || combined.contains('umeme');

      if (isWater) {
        items.add(
          UtilityActivityItem(
            type: UtilityActivityType.waterBill,
            title: _isSw ? 'Bili ya Maji' : 'Water Bill',
            subtitle: 'Auto-Debit${dateLabel.isEmpty ? '' : ' • $dateLabel'}',
            impactLabel: '${(e.amountValue / 10).round()} L',
            amountLabel: 'TZS ${money.format(e.amountValue.round())}',
            isPositive: false,
          ),
        );
      } else if (isLuku) {
        items.add(
          UtilityActivityItem(
            type: UtilityActivityType.lukuTopUp,
            title: _isSw ? 'Malipo ya LUKU' : 'LUKU Top-up',
            subtitle:
                'Via Mobile Money${dateLabel.isEmpty ? '' : ' • $dateLabel'}',
            impactLabel: '+${(e.amountValue / 700).toStringAsFixed(1)} kWh',
            amountLabel: 'TZS ${money.format(e.amountValue.round())}',
            isPositive: true,
          ),
        );
      }
    }

    activities.assignAll(items);
  }

  void _updateWeeklyTrend(List<RentUtilityTopUpRecord> topUps) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final totals = List<double>.filled(7, 0);
    for (final t in topUps) {
      final d = _parseDateOrCreated(t.dateIso, t.createdAtMs);
      final day = DateTime(d.year, d.month, d.day);
      final diff = day.difference(start).inDays;
      if (diff >= 0 && diff < 7) {
        totals[diff] += t.unitsAdded;
      }
    }
    weeklyUsage.assignAll(totals);
  }

  DateTime _parseDateOrCreated(String iso, int createdMs) {
    final raw = iso.trim();
    if (raw.length >= 10 && raw[4] == '-' && raw[7] == '-') {
      final y = int.tryParse(raw.substring(0, 4));
      final m = int.tryParse(raw.substring(5, 7));
      final d = int.tryParse(raw.substring(8, 10));
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(createdMs);
  }

  void _updateNextMeterReading(List<RentUtilityTopUpRecord> topUps) {
    DateTime base = DateTime.now();
    if (topUps.isNotEmpty) {
      final latest = topUps.first;
      base = _parseDateOrCreated(latest.dateIso, latest.createdAtMs);
    }
    final nextRead = base.add(const Duration(days: 7));
    nextMeterReadingLabel.value = _isSw
        ? 'Soma ijayo ya mita: ${DateFormat('d MMM').format(nextRead)}'
        : 'Next meter reading: ${DateFormat('d MMM').format(nextRead)}';
  }

  void _computeStatusAndTrust(List<RentUtilityTopUpRecord> topUps) {
    final now = DateTime.now();
    DateTime? latestDate;
    if (topUps.isNotEmpty) {
      latestDate = _parseDateOrCreated(
        topUps.first.dateIso,
        topUps.first.createdAtMs,
      );
    }
    final recencyDays = latestDate == null
        ? 999
        : now.difference(latestDate).inDays;
    final hasAnyBalance = lukuUnits.value > 0 || waterLiters.value > 0;
    final isLow =
        lukuCoverageDays.value <= 2 ||
        (waterCapacity.value > 0 && waterProgress < 0.2);

    if (!hasAnyBalance) {
      globalStatus.value = _isSw ? 'Hakuna data' : 'No Data';
    } else if (isLow || recencyDays > 14) {
      globalStatus.value = _isSw ? 'Inahitaji kujazwa' : 'Needs Top-up';
    } else {
      globalStatus.value = _isSw ? 'Imara' : 'Healthy';
    }

    var score = 10.0;
    if (!hasAnyBalance) score -= 4.5;
    if (isLow) score -= 2.5;
    if (recencyDays > 7) score -= 1.5;
    if (recencyDays > 14) score -= 1.0;
    trustScore.value = score.clamp(0.0, 10.0);
  }

  double get lukuProgress => lukuCapacity.value <= 0
      ? 0
      : (lukuUnits.value / lukuCapacity.value).clamp(0, 1);

  double get waterProgress => waterCapacity.value <= 0
      ? 0
      : (waterLiters.value / waterCapacity.value).clamp(0, 1);

  // ── Unit helpers ────────────────────────────────────────────────────────────

  void _loadPropertyUnits(String unitsJson) {
    if (unitsJson.trim().isEmpty) {
      availableUnits.clear();
      return;
    }
    try {
      final decoded = jsonDecode(unitsJson);
      if (decoded is! List) {
        availableUnits.clear();
        return;
      }
      final units = decoded
          .whereType<Map>()
          .map((m) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(m)))
          .where((u) => u.unitName.trim().isNotEmpty)
          .toList();
      availableUnits.assignAll(units);
      // If the previously selected unit no longer exists, reset.
      if (selectedUnitId.value.isNotEmpty &&
          !units.any((u) => u.unitId == selectedUnitId.value)) {
        selectedUnitId.value = '';
        selectedUnitName.value = '';
      }
    } catch (_) {
      availableUnits.clear();
    }
  }

  /// Switch the active unit filter. Pass empty string to show all units.
  Future<void> selectUnit(String unitId) async {
    final unit = availableUnits.firstWhereOrNull((u) => u.unitId == unitId);
    selectedUnitId.value = unitId;
    selectedUnitName.value = unit?.unitName.trim() ?? '';
    await loadAll();
  }

  // ── Top-up persistence ───────────────────────────────────────────────────────

  /// Persist a LUKU electricity top-up and reload derived metrics.
  Future<void> addLukuTopUp({
    required double kwh,
    required double amountTsh,
    String provider = '',
    String meterNumber = '',
    String notes = '',
    DateTime? date,
  }) async {
    final when = date ?? DateTime.now();
    final uid = selectedUnitId.value.trim();
    final uName = selectedUnitName.value.trim();
    final localId = await _topUpLocal.insert(
      kind: RentUtilityKind.luku,
      unitsAdded: kwh,
      amountTsh: amountTsh,
      provider: provider,
      meterNumber: meterNumber,
      unitId: uid,
      unitName: uName,
      notes: notes,
      propertyLabel: propertyLabel.value,
      propertyRef: propertyRef.value,
      dateIso: when.toIso8601String(),
    );

    final payload = _buildPayload(
      kind: RentUtilityKind.luku,
      units: kwh,
      amount: amountTsh,
      provider: provider,
      meterNumber: meterNumber,
      unitId: uid,
      unitName: uName,
      notes: notes,
      purchaseDate: when.toIso8601String(),
    );
    try {
      final res = await _repository.addUtilityTopUp(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'utility',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'utility:create:luku:$localId',
      );
      _syncWorker.runNow();
    }

    await loadAll();
    showSuccessMessage(
      _isSw
          ? 'Umeongeza ${kwh.toStringAsFixed(1)} kWh za LUKU'
          : 'Added ${kwh.toStringAsFixed(1)} kWh of LUKU',
    );
  }

  Future<void> addLukuTopUpsFromSms(List<LukuSmsTopUpDraft> drafts) async {
    if (drafts.isEmpty) return;
    final uid = selectedUnitId.value.trim();
    final uName = selectedUnitName.value.trim();
    for (final draft in drafts) {
      final localId = await _topUpLocal.insert(
        kind: RentUtilityKind.luku,
        unitsAdded: draft.unitsKwh,
        amountTsh: draft.amountTsh,
        provider: 'SMS OCR',
        meterNumber: draft.meterNumber,
        unitId: uid,
        unitName: uName,
        notes: draft.notes,
        propertyLabel: propertyLabel.value,
        propertyRef: propertyRef.value,
        dateIso: draft.date.toIso8601String(),
      );
      final payload = _buildPayload(
        kind: RentUtilityKind.luku,
        units: draft.unitsKwh,
        amount: draft.amountTsh,
        provider: 'SMS OCR',
        meterNumber: draft.meterNumber,
        unitId: uid,
        unitName: uName,
        notes: draft.notes,
        purchaseDate: draft.date.toIso8601String(),
      );
      try {
        final res = await _repository.addUtilityTopUp(payload);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'API error');
      } catch (_) {
        await _syncQueue.enqueue(
          entityType: 'utility',
          operation: 'create',
          payloadJson: jsonEncode(payload),
          dedupeKey: 'utility:create:luku:$localId',
        );
        _syncWorker.runNow();
      }
    }
    await loadAll();
    final count = drafts.length;
    showSuccessMessage(
      _isSw
          ? 'Umeingiza malipo $count ya LUKU'
          : 'Imported $count LUKU top-up${count == 1 ? '' : 's'}',
    );
  }

  /// Persist a water recharge and reload derived metrics.
  Future<void> addWaterTopUp({
    required double liters,
    required double amountTsh,
    String provider = '',
    String meterNumber = '',
    String notes = '',
    DateTime? date,
  }) async {
    final when = date ?? DateTime.now();
    final uid = selectedUnitId.value.trim();
    final uName = selectedUnitName.value.trim();
    final localId = await _topUpLocal.insert(
      kind: RentUtilityKind.water,
      unitsAdded: liters,
      amountTsh: amountTsh,
      provider: provider,
      meterNumber: meterNumber,
      unitId: uid,
      unitName: uName,
      notes: notes,
      propertyLabel: propertyLabel.value,
      propertyRef: propertyRef.value,
      dateIso: when.toIso8601String(),
    );

    final payload = _buildPayload(
      kind: RentUtilityKind.water,
      units: liters,
      amount: amountTsh,
      provider: provider,
      meterNumber: meterNumber,
      unitId: uid,
      unitName: uName,
      notes: notes,
      purchaseDate: when.toIso8601String(),
    );
    try {
      final res = await _repository.addUtilityTopUp(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'utility',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'utility:create:water:$localId',
      );
      _syncWorker.runNow();
    }

    await loadAll();
    showSuccessMessage(
      _isSw
          ? 'Umeongeza ${liters.toStringAsFixed(0)} lita za maji'
          : 'Added ${liters.toStringAsFixed(0)} L of water',
    );
  }

  Map<String, dynamic> _buildPayload({
    required String kind,
    required double units,
    required double amount,
    required String purchaseDate,
    String provider = '',
    String meterNumber = '',
    String unitId = '',
    String unitName = '',
    String notes = '',
  }) {
    return {
      'kind': kind,
      'units': units,
      'amount': amount,
      'purchaseDate': purchaseDate,
      'propertyRef': propertyRef.value,
      if (provider.isNotEmpty) 'notes': notes.isNotEmpty
          ? '$notes • via $provider'
          : 'via $provider'
      else if (notes.isNotEmpty) 'notes': notes,
      if (meterNumber.isNotEmpty) 'meterNumber': meterNumber,
      if (unitId.isNotEmpty) 'unitId': unitId,
      if (unitName.isNotEmpty) 'unitName': unitName,
    };
  }

  void onViewAllActivity() {
    showSuccessMessage(
      _isSw ? 'Inapakia historia kamili' : 'Loading full utility history',
    );
  }

  void openLukuUsageGraph() {
    Get.toNamed(
      Routes.RENT_UTILITY_USAGE_GRAPH,
      parameters: {'kind': RentUtilityKind.luku},
    );
  }

  void openWaterUsageGraph() {
    Get.toNamed(
      Routes.RENT_UTILITY_USAGE_GRAPH,
      parameters: {'kind': RentUtilityKind.water},
    );
  }
}

import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_utility_topup_local_data_source.dart';

/// Daily top-up totals for the last 30 days (index 0 = oldest day in window).
class RentUtilityUsageGraphController extends BaseController {
  RentUtilityUsageGraphController()
      : _topUpLocal = Get.find<RentUtilityTopUpLocalDataSource>();

  final RentUtilityTopUpLocalDataSource _topUpLocal;

  final loading = true.obs;
  final dailyTotals = <double>[].obs;

  String get kind {
    final k = (Get.parameters['kind'] ?? '').toLowerCase().trim();
    if (k == RentUtilityKind.water) return RentUtilityKind.water;
    return RentUtilityKind.luku;
  }

  bool get isLuku => kind == RentUtilityKind.luku;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final records = await _topUpLocal.getByKind(kind);
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);
      final start = todayDay.subtract(const Duration(days: 29));
      final buckets = List<double>.filled(30, 0);

      for (final t in records) {
        final d = _parseDateOrCreated(t.dateIso, t.createdAtMs);
        final day = DateTime(d.year, d.month, d.day);
        if (day.isBefore(start) || day.isAfter(todayDay)) continue;
        final idx = day.difference(start).inDays;
        if (idx >= 0 && idx < 30) {
          buckets[idx] += t.unitsAdded;
        }
      }
      dailyTotals.assignAll(buckets);
    } catch (_) {
      dailyTotals.assignAll(List<double>.filled(30, 0));
    } finally {
      loading.value = false;
    }
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

  double get maxY {
    final m = dailyTotals.fold<double>(0, (a, b) => a > b ? a : b);
    return m <= 0 ? 1 : m * 1.15;
  }

  bool get hasAnyData => dailyTotals.any((v) => v > 0);
}

import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/repository/app_repository.dart';

class AdminGrowthMetricsController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final metrics = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  final isSavingTargets = false.obs;

  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading(true);
    try {
      final res = await _repository.getGrowthMetrics();
      _apply(res.data);
    } catch (_) {
      showErrorMessage(_t('Could not load metrics', 'Imeshindikana kupakia vipimo'));
    } finally {
      isLoading(false);
    }
  }

  Map<String, dynamic> currentTargets() {
    final data = metrics.value;
    if (data == null) return {};
    final raw = data['targets'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {
      'communityMembers': _nested(data['communityMembers'], 'target'),
      'registrations': _nested(data['registrations'], 'target'),
      'firstPropertyPct': _nested(data['firstProperty'], 'targetPct'),
      'retentionPct': _nested(data['retention7Day'], 'targetPct'),
      'referralPct': _nested(data['referralDriven'], 'targetPct'),
    };
  }

  Future<void> saveTargets({
    required int communityMembers,
    required int registrations,
    required double firstPropertyPct,
    required double retentionPct,
    required double referralPct,
  }) async {
    isSavingTargets(true);
    try {
      final res = await _repository.updateGrowthTargets({
        'communityMembers': communityMembers,
        'registrations': registrations,
        'firstPropertyPct': firstPropertyPct,
        'retentionPct': retentionPct,
        'referralPct': referralPct,
      });
      _apply(res.data);
      showSuccessMessage(_t('Targets updated', 'Malengo yamesasishwa'));
    } catch (_) {
      showErrorMessage(_t('Could not save targets', 'Imeshindikana kuhifadhi malengo'));
    } finally {
      isSavingTargets(false);
    }
  }

  void _apply(dynamic data) {
    if (data is Map<String, dynamic>) {
      metrics.value = data;
    } else if (data is Map) {
      metrics.value = data.map((k, v) => MapEntry(k.toString(), v));
    } else {
      showErrorMessage(_t('Could not load metrics', 'Imeshindikana kupakia vipimo'));
    }
  }

  dynamic _nested(dynamic raw, String key) {
    if (raw is Map) return raw[key];
    return null;
  }
}

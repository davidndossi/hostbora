import 'package:get/get.dart';

import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/sales_agent_models.dart';
import '../../../data/repository/app_repository.dart';
import '/app/core/base/base_controller.dart';

class SalesAgentDashboardController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());
  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );

  final dashboard = Rxn<SalesAgentDashboard>();
  final isLoading = false.obs;

  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  void onReady() {
    super.onReady();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading(true);
    try {
      final user = await _preferenceManager.getUser();
      final userId = user.id ?? '';
      if (userId.isEmpty) {
        showErrorMessage(_t('User not found', 'Mtumiaji hajapatikana'));
        return;
      }
      final res = await _repository.getSalesAgentDashboard(userId);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        dashboard.value = SalesAgentDashboard.fromJson(data);
      } else {
        showErrorMessage(_t('Could not load dashboard', 'Imeshindikana kupakia dashibodi'));
      }
    } catch (_) {
      showErrorMessage(_t('Could not load dashboard', 'Imeshindikana kupakia dashibodi'));
    } finally {
      isLoading(false);
    }
  }

  String formatTzs(int amount) {
    final s = amount.toString();
    final buf = StringBuffer('TZS ');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

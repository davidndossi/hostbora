import 'package:get/get.dart';

import '../../../data/local/service/currency_service.dart';
import '../../../data/model/sales_agent_models.dart';
import '../../../data/repository/app_repository.dart';
import '/app/core/base/base_controller.dart';

class AdminSalesAgentDetailController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final dashboard = Rxn<SalesAgentDashboard>();
  final isLoading = false.obs;
  late final int agentId;

  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  void onInit() {
    super.onInit();
    agentId = int.tryParse('${Get.arguments?['agentId']}') ?? 0;
  }

  @override
  void onReady() {
    super.onReady();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (agentId <= 0) return;
    isLoading(true);
    try {
      final res = await _repository.getAdminSalesAgentDashboard(agentId);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        dashboard.value = SalesAgentDashboard.fromJson(data);
      }
    } catch (_) {
      showErrorMessage(_t('Could not load agent stats', 'Imeshindikana kupakia takwimu'));
    } finally {
      isLoading(false);
    }
  }

  String formatTzs(int amount) =>
      Get.find<CurrencyService>().formatBase(amount);
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/sales_agent_models.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class AdminSalesAgentsController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final agents = <SalesAgentSummary>[].obs;
  final isLoadingList = false.obs;
  final isSaving = false.obs;
  final searchQuery = ''.obs;

  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final regionController = TextEditingController();
  final agentCodeController = TextEditingController();
  final userIdController = TextEditingController();

  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  List<SalesAgentSummary> get filteredAgents {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return agents;
    return agents
        .where(
          (a) =>
              a.fullName.toLowerCase().contains(q) ||
              a.agentCode.toLowerCase().contains(q) ||
              a.phone.contains(q),
        )
        .toList();
  }

  @override
  void onReady() {
    super.onReady();
    loadAgents();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    regionController.dispose();
    agentCodeController.dispose();
    userIdController.dispose();
    super.onClose();
  }

  Future<void> loadAgents() async {
    isLoadingList(true);
    try {
      final res = await _repository.listSalesAgents();
      final data = res.data;
      if (data is List) {
        agents.assignAll(
          data
              .whereType<Map>()
              .map((e) => SalesAgentSummary.fromJson(e.cast<String, dynamic>())),
        );
      }
    } catch (_) {
      showErrorMessage(_t('Could not load agents', 'Imeshindikana kupakia wakala'));
    } finally {
      isLoadingList(false);
    }
  }

  Future<void> createAgent() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    isSaving(true);
    try {
      final body = CreateSalesAgentRequest(
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        region: regionController.text.trim(),
        agentCode: agentCodeController.text.trim(),
        userId: userIdController.text.trim(),
      ).toJson();
      final res = await _repository.createSalesAgent(body);
      if (res.isSuccess) {
        showSuccessMessage(_t('Agent created', 'Wakala ameundwa'));
        _clearForm();
        Get.back();
        await loadAgents();
      } else {
        showErrorMessage(res.message ?? _t('Failed to create agent', 'Imeshindikana kuunda wakala'));
      }
    } catch (_) {
      showErrorMessage(_t('Failed to create agent', 'Imeshindikana kuunda wakala'));
    } finally {
      isSaving(false);
    }
  }

  Future<void> toggleStatus(SalesAgentSummary agent) async {
    final next = agent.status.toLowerCase() == 'active' ? 'suspended' : 'active';
    try {
      await _repository.updateSalesAgentStatus(agent.id, next);
      await loadAgents();
    } catch (_) {
      showErrorMessage(_t('Could not update status', 'Imeshindikana kubadilisha hali'));
    }
  }

  void openAgentDashboard(SalesAgentSummary agent) {
    Get.toNamed(Routes.ADMIN_SALES_AGENT_DETAIL, arguments: {'agentId': agent.id});
  }

  void _clearForm() {
    fullNameController.clear();
    phoneController.clear();
    emailController.clear();
    regionController.clear();
    agentCodeController.clear();
    userIdController.clear();
  }
}

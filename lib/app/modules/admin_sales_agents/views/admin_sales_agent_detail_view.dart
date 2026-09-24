import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/admin_sales_agent_detail_controller.dart';

class AdminSalesAgentDetailView extends BaseView<AdminSalesAgentDetailController> {
  AdminSalesAgentDetailView({super.key});

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t('Agent performance', 'Utendaji wa wakala'),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.dashboard.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final dash = controller.dashboard.value;
      if (dash == null) {
        return Center(child: Text(_t('No data', 'Hakuna data')));
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(dash.agent.fullName),
            subtitle: Text('${dash.agent.agentCode} · ${dash.agent.region}'),
          ),
          _row(_t('Invited', 'Walioalikwa'), '${dash.invited}'),
          _row(_t('Registered', 'Waliojisajili'), '${dash.registered}'),
          _row(_t('Active', 'Hai'), '${dash.active}'),
          _row(_t('Paid', 'Waliolipa'), '${dash.paidSubscribers}'),
          _row(
            _t('Commission this month', 'Kamisheni mwezi huu'),
            controller.formatTzs(dash.commissionThisMonthTzs),
          ),
          const Divider(),
          ...dash.customers.map(
            (c) => ListTile(
              title: Text(c.customerName.isEmpty ? c.customerPhone : c.customerName),
              subtitle: Text('${c.plan} · ${c.subscriptionStatus}'),
            ),
          ),
        ],
      );
    });
  }

  Widget _row(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

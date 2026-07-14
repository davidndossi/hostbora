import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/sales_agent_dashboard_controller.dart';

class SalesAgentDashboardView extends BaseView<SalesAgentDashboardController> {
  SalesAgentDashboardView({super.key});

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t('Sales dashboard', 'Dashibodi ya mauzo'),
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
        return Center(
          child: Text(_t('No dashboard data', 'Hakuna data ya dashibodi')),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statCard(
              context,
              title: dash.agent.fullName,
              subtitle: dash.agent.agentCode,
              children: [
                _metricRow(_t('Recruited', 'Waliowajiliwa'), '${dash.totalRecruited}'),
                _metricRow(_t('Active subscribers', 'Wanaofanya kazi'), '${dash.activeSubscribers}'),
                _metricRow(_t('Paid subscribers', 'Waliolipa'), '${dash.paidSubscribers}'),
              ],
            ),
            const SizedBox(height: 12),
            _statCard(
              context,
              title: _t('Commission', 'Kamisheni'),
              subtitle: dash.periodMonth,
              children: [
                _metricRow(
                  _t('This month', 'Mwezi huu'),
                  controller.formatTzs(dash.commissionThisMonthTzs),
                ),
                _metricRow(
                  _t('Approved total', 'Jumla iliyoidhinishwa'),
                  controller.formatTzs(dash.commissionApprovedTzs),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _statCard(
              context,
              title: _t('Active by plan', 'Hai kwa kifurushi'),
              subtitle: '',
              children: [
                _metricRow('Starter', '${dash.byTier['starter'] ?? 0}'),
                _metricRow('Pro', '${dash.byTier['pro'] ?? 0}'),
                _metricRow('Ultra', '${dash.byTier['ultra'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _t('Recruited customers', 'Wateja uliowajili'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...dash.customers.map((c) => Card(
                  child: ListTile(
                    title: Text(c.customerName.isEmpty ? c.customerPhone : c.customerName),
                    subtitle: Text('${c.plan.toUpperCase()} · ${c.subscriptionStatus}'),
                    trailing: Icon(
                      c.active ? Icons.check_circle : Icons.remove_circle_outline,
                      color: c.active ? Colors.green : Colors.grey,
                    ),
                  ),
                )),
          ],
        ),
      );
    });
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

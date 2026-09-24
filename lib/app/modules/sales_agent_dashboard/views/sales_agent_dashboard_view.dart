import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
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
            _referralCard(context, dash.agent.fullName, dash.agent.agentCode),
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
            ...dash.customers.map(
              (c) => Card(
                child: ListTile(
                  title: Text(
                    c.customerName.isEmpty ? c.customerPhone : c.customerName,
                  ),
                  subtitle: Text('${c.plan.toUpperCase()} · ${c.subscriptionStatus}'),
                  trailing: Icon(
                    c.active ? Icons.check_circle : Icons.remove_circle_outline,
                    color: c.active ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _referralCard(BuildContext context, String name, String code) {
    final dash = controller.dashboard.value!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              _t('My Referral Code', 'Msimbo wangu wa mrejeleo'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.designAccent,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: _t('Copy', 'Nakili'),
                  onPressed: controller.copyReferralCode,
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  tooltip: _t('QR code', 'Msimbo wa QR'),
                  onPressed: controller.showInviteQr,
                  icon: const Icon(Icons.qr_code_2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isInviting.value
                      ? null
                      : controller.invitePropertyOwner,
                  icon: controller.isInviting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(
                    _t('Invite Property Owner', 'Alika mmiliki wa nyumba'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _funnelStat(_t('Invited', 'Walioalikwa'), '${dash.invited}'),
                _funnelStat(_t('Registered', 'Waliojisajili'), '${dash.registered}'),
                _funnelStat(_t('Active', 'Hai'), '${dash.active}'),
              ],
            ),
            const SizedBox(height: 12),
            _metricRow(
              _t('Reward', 'Zawadi'),
              _t('To be implemented', 'Inakuja'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _funnelStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
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

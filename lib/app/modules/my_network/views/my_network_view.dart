import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/model/host_network.dart';
import '../controllers/my_network_controller.dart';

class MyNetworkView extends BaseView<MyNetworkController> {
  MyNetworkView({super.key});

  String _t(String en, String sw) => controller.isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t('My Network', 'Mtandao wangu'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.loading.value && controller.network.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = controller.network.value;
      if (data == null) {
        return Center(child: Text(_t('No network data yet.', 'Hakuna data ya mtandao bado.')));
      }
      final format = NumberFormat.decimalPattern();
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text('MY NETWORK', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _statRow(_t('Invited', 'Walioalikwa'), format.format(data.invited)),
            _statRow(_t('Registered', 'Waliojisajili'), format.format(data.registered)),
            _statRow(_t('Active Hosts', 'Wenyeji hai'), format.format(data.activeHosts)),
            const SizedBox(height: 16),
            _statRow('HB Points', format.format(data.hbPoints)),
            _statRow(
              _t('Free subscription', 'Usajili wa bure'),
              _t('${data.freeMonths} months', 'Miezi ${data.freeMonths}'),
            ),
            const SizedBox(height: 20),
            Text(
              _t('Share your referral link', 'Sambaza kiungo cha mwaliko'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              data.inviteUrl,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.shareWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.shareSms,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('SMS'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.copyLink,
              icon: const Icon(Icons.copy),
              label: Text(_t('Copy referral link', 'Nakili kiungo')),
            ),
            const SizedBox(height: 24),
            Text(
              _t('A host becomes active after they register, add a property, add a tenant or unit, and record a payment.',
                  'Mwenyeji huwa hai baada ya kujisajili, kuongeza mali, kuongeza mpangaji au chumba, na kurekodi malipo.'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (data.referrals.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(_t('Referrals', 'Walioalika'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ...data.referrals.map((row) => _referralTile(theme, row)),
            ],
          ],
        ),
      );
    });
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.colorPrimary)),
        ],
      ),
    );
  }

  Widget _referralTile(ThemeData theme, HostNetworkReferral row) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(row.fullName?.isNotEmpty == true ? row.fullName! : (row.username ?? row.referredUserId)),
      subtitle: Text(
        row.rewardStatus == 'awarded'
            ? _t('Active host', 'Mwenyeji hai')
            : _t('Registered', 'Amejisajili'),
      ),
    );
  }
}

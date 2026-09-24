import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/model/rewards_dashboard.dart';
import '../controllers/challenges_rewards_controller.dart';

class ChallengesRewardsView extends BaseView<ChallengesRewardsController> {
  ChallengesRewardsView({super.key});

  String _t(String en, String sw) => controller.isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t('Challenges & Rewards', 'Changamoto na Zawadi'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.loading.value && controller.dashboard.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = controller.dashboard.value;
      if (data == null) {
        return Center(
          child: Text(_t('No rewards data yet.', 'Hakuna data ya zawadi bado.')),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _balanceCard(theme, data),
            const SizedBox(height: 20),
            Text(
              _t('This month', 'Mwezi huu'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...data.challenges.map((challenge) => _challengeCard(theme, challenge)),
            const SizedBox(height: 20),
            Text(
              _t('Earn HB Points', 'Pata HB Points'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...data.earn.map((item) => _earnRow(theme, item)),
            if (!data.academyCompleted) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: controller.saving.value ? null : () async {
                  controller.openAcademy();
                  await controller.completeAcademy();
                },
                child: Text(_t('Complete HostBora Academy', 'Kamilisha HostBora Academy')),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              _t('Redeem', 'Komboa'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...data.catalog.map((item) => _redeemRow(theme, data, item)),
          ],
        ),
      );
    });
  }

  Widget _balanceCard(ThemeData theme, RewardsDashboard data) {
    return Card(
      color: AppColors.designAccent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HB POINTS',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${data.balance}',
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (data.smsCredits > 0)
              Text(
                _t(
                  '${data.smsCredits} SMS reminders remaining',
                  'SMS ${data.smsCredits} zimebaki',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _challengeCard(ThemeData theme, RewardChallenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(challenge.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(challenge.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (challenge.pct / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: AppColors.designAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progressLabel(challenge),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(RewardChallenge challenge) {
    if (challenge.unit == 'TZS') {
      final format = NumberFormat.decimalPattern();
      return 'TZS ${format.format(challenge.current.round())} / TZS ${format.format(challenge.target.round())}   ${challenge.pct}%';
    }
    if (challenge.unit == 'months') {
      return '${challenge.current.round()} / ${challenge.target.round()} ${_t('months', 'miezi')}   ${challenge.pct}%';
    }
    return '${challenge.pct}%';
  }

  Widget _earnRow(ThemeData theme, RewardEarnItem item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.label),
      trailing: Text(
        item.claimed ? _t('Claimed', 'Imechukuliwa') : '+${item.points}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: item.claimed ? theme.colorScheme.onSurfaceVariant : AppColors.designAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _redeemRow(ThemeData theme, RewardsDashboard data, RewardCatalogItem item) {
    final canAfford = data.balance >= item.cost;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(item.label),
        subtitle: Text('${item.cost} HB${item.description == null ? '' : ' · ${item.description}'}'),
        trailing: TextButton(
          onPressed: (!canAfford || controller.saving.value) ? null : () => controller.redeem(item),
          child: Text(_t('Redeem', 'Komboa')),
        ),
      ),
    );
  }
}

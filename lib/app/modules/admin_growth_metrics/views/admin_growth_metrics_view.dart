import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/admin_growth_metrics_controller.dart';

class AdminGrowthMetricsView extends BaseView<AdminGrowthMetricsController> {
  AdminGrowthMetricsView({super.key});

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t('Growth metrics', 'Vipimo vya ukuaji'),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.metrics.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = controller.metrics.value;
      if (data == null) {
        return Center(child: Text(_t('No metrics yet', 'Hakuna vipimo bado')));
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _editTargets(context),
                icon: const Icon(Icons.tune),
                label: Text(_t('Edit targets', 'Hariri malengo')),
              ),
            ),
            _countCard(
              context,
              title: _t('Community members', 'Wanajamii'),
              metric: _map(data['communityMembers']),
              suffix: '+',
            ),
            const SizedBox(height: 12),
            _countCard(
              context,
              title: _t('HostBora registrations', 'Usajili wa HostBora'),
              metric: _map(data['registrations']),
              suffix: '+',
            ),
            const SizedBox(height: 12),
            _rateCard(
              context,
              title: _t('Users adding first property', 'Walioongeza mali ya kwanza'),
              metric: _map(data['firstProperty']),
              detail: _t(
                '${_num(data['firstProperty'], 'usersWithProperty')} of ${_num(data['firstProperty'], 'registeredUsers')}',
                '${_num(data['firstProperty'], 'usersWithProperty')} kati ya ${_num(data['firstProperty'], 'registeredUsers')}',
              ),
            ),
            const SizedBox(height: 12),
            _rateCard(
              context,
              title: _t('Users returning after 7 days', 'Wanaorudi baada ya siku 7'),
              metric: _map(data['retention7Day']),
              detail: _t(
                '${_num(data['retention7Day'], 'returned')} of ${_num(data['retention7Day'], 'cohortSize')} eligible',
                '${_num(data['retention7Day'], 'returned')} kati ya ${_num(data['retention7Day'], 'cohortSize')} wanaostahili',
              ),
            ),
            const SizedBox(height: 12),
            _rateCard(
              context,
              title: _t('Referral-driven registrations', 'Usajili wa mrejeleo'),
              metric: _map(data['referralDriven']),
              detail: _t(
                '${_num(data['referralDriven'], 'referred')} of ${_num(data['referralDriven'], 'registeredUsers')}',
                '${_num(data['referralDriven'], 'referred')} kati ya ${_num(data['referralDriven'], 'registeredUsers')}',
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _editTargets(BuildContext context) async {
    final current = controller.currentTargets();
    final community = TextEditingController(
      text: current['communityMembers']?.toString() ?? '100',
    );
    final registrations = TextEditingController(
      text: current['registrations']?.toString() ?? '50',
    );
    final firstProperty = TextEditingController(
      text: current['firstPropertyPct']?.toString() ?? '60',
    );
    final retention = TextEditingController(
      text: current['retentionPct']?.toString() ?? '30',
    );
    final referral = TextEditingController(
      text: current['referralPct']?.toString() ?? '15',
    );
    final saved = await Get.dialog<bool>(
      AlertDialog(
        title: Text(_t('Edit targets', 'Hariri malengo')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _targetField(community, _t('Community members', 'Wanajamii')),
              _targetField(registrations, _t('HostBora registrations', 'Usajili')),
              _targetField(firstProperty, _t('First property %', 'Mali ya kwanza %')),
              _targetField(retention, _t('7-day return %', 'Kurudi siku 7 %')),
              _targetField(referral, _t('Referral %', 'Mrejeleo %')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(_t('Save', 'Hifadhi')),
          ),
        ],
      ),
    );
    if (saved != true) {
      community.dispose();
      registrations.dispose();
      firstProperty.dispose();
      retention.dispose();
      referral.dispose();
      return;
    }
    final communityN = int.tryParse(community.text.trim());
    final registrationsN = int.tryParse(registrations.text.trim());
    final firstN = double.tryParse(firstProperty.text.trim());
    final retentionN = double.tryParse(retention.text.trim());
    final referralN = double.tryParse(referral.text.trim());
    community.dispose();
    registrations.dispose();
    firstProperty.dispose();
    retention.dispose();
    referral.dispose();
    if (communityN == null ||
        registrationsN == null ||
        firstN == null ||
        retentionN == null ||
        referralN == null) {
      controller.showErrorMessage(_t('Enter valid numbers', 'Weka namba sahihi'));
      return;
    }
    await controller.saveTargets(
      communityMembers: communityN,
      registrations: registrationsN,
      firstPropertyPct: firstN,
      retentionPct: retentionN,
      referralPct: referralN,
    );
  }

  Widget _targetField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }

  String _num(dynamic raw, String key) => _map(raw)[key]?.toString() ?? '0';

  Widget _countCard(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> metric,
    required String suffix,
  }) {
    final value = metric['value']?.toString() ?? '0';
    final target = metric['target']?.toString() ?? '0';
    final onTrack = metric['onTrack'] == true;
    return _card(
      context,
      title: title,
      value: '$value$suffix',
      target: _t('Target $target$suffix', 'Lengo $target$suffix'),
      onTrack: onTrack,
    );
  }

  Widget _rateCard(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> metric,
    required String detail,
  }) {
    final pct = metric['pct']?.toString() ?? '0';
    final target = metric['targetPct']?.toString() ?? '0';
    final onTrack = metric['onTrack'] == true;
    return _card(
      context,
      title: title,
      value: '$pct%',
      target: '${_t('Target', 'Lengo')} >$target% · $detail',
      onTrack: onTrack,
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required String value,
    required String target,
    required bool onTrack,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                ),
                Icon(
                  onTrack ? Icons.check_circle : Icons.timelapse,
                  color: onTrack ? AppColors.paaYanguSuccess : AppColors.paaYanguWarm,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.designAccent,
                  ),
            ),
            const SizedBox(height: 4),
            Text(target, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

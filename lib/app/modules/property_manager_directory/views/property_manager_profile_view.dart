import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/property_manager_profile_controller.dart';

class PropertyManagerProfileView extends BaseView<PropertyManagerProfileController> {
  PropertyManagerProfileView({super.key});

  String _t(String en, String sw) => controller.isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t('Manager profile', 'Wasifu wa msimamizi'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.loading.value && controller.manager.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final manager = controller.manager.value;
      if (manager == null) {
        return Center(child: Text(_t('Profile not found.', 'Wasifu haupatikani.')));
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            manager.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (manager.certified) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified, color: AppColors.colorPrimary),
                const SizedBox(width: 6),
                Text(
                  'HostBora Certified',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.colorPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _row(_t('Location', 'Eneo'), manager.locationLabel),
          _row(
            _t('Property type', 'Aina ya mali'),
            manager.propertyTypeLabels.isEmpty ? '—' : manager.propertyTypeLabels.join(', '),
          ),
          _row(
            _t('Properties managed', 'Mali anazosimamia'),
            '${manager.propertyCount}',
          ),
          if (manager.hostScore != null) _row('Host Score', '${manager.hostScore}'),
          if ((manager.bio ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(manager.bio!.trim(), style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),
          Text(
            _t('Contact manager', 'Wasiliana na msimamizi'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: controller.contactWhatsApp,
            icon: const Icon(Icons.chat),
            label: const Text('WhatsApp'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.contactSms,
            icon: const Icon(Icons.sms_outlined),
            label: const Text('SMS'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.contactCall,
            icon: const Icon(Icons.call_outlined),
            label: Text(_t('Call', 'Piga simu')),
          ),
        ],
      );
    });
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

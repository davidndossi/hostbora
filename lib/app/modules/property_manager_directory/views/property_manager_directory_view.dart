import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/model/property_manager.dart';
import '../controllers/property_manager_directory_controller.dart';

class PropertyManagerDirectoryView extends BaseView<PropertyManagerDirectoryController> {
  PropertyManagerDirectoryView({super.key});

  String _t(String en, String sw) => controller.isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t('Property Managers', 'Wasimamizi wa Mali'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final data = controller.directory.value;
      if (controller.loading.value && data == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _filterField(
              theme,
              label: _t('Location', 'Eneo'),
              value: controller.location.value,
              options: data?.locations ?? const [],
              onChanged: controller.setLocation,
            ),
            const SizedBox(height: 12),
            _filterField(
              theme,
              label: _t('Property Type', 'Aina ya mali'),
              value: controller.propertyType.value,
              options: data?.propertyTypes ?? const [],
              onChanged: controller.setPropertyType,
            ),
            const SizedBox(height: 12),
            _filterField(
              theme,
              label: _t('Properties', 'Mali'),
              value: controller.properties.value,
              options: data?.propertyBands ?? const [],
              onChanged: controller.setProperties,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            if ((data?.managers ?? const []).isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  _t(
                    'No certified property managers match these filters yet.',
                    'Hakuna wasimamizi walioidhinishwa wanaolingana bado.',
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ...data!.managers.map((manager) => _managerCard(theme, manager)),
          ],
        ),
      );
    });
  }

  Widget _filterField(
    ThemeData theme, {
    required String label,
    required String value,
    required List<DirectoryOption> options,
    required Future<void> Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              isExpanded: true,
              hint: Text(_t('Any', 'Yoyote')),
              items: [
                DropdownMenuItem<String>(value: '', child: Text(_t('Any', 'Yoyote'))),
                ...options.map(
                  (option) => DropdownMenuItem<String>(
                    value: option.key,
                    child: Text(option.label),
                  ),
                ),
              ],
              onChanged: (next) => onChanged(next == null || next.isEmpty ? '' : next),
            ),
          ),
        ),
      ],
    );
  }

  Widget _managerCard(ThemeData theme, PropertyManager manager) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              manager.displayName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (manager.certified) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified, size: 18, color: AppColors.colorPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'HostBora Certified',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.colorPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _t(
                '${manager.propertyCount} properties managed',
                'Mali ${manager.propertyCount} anazosimamia',
              ),
              style: theme.textTheme.bodyMedium,
            ),
            if (manager.hostScore != null)
              Text(
                'Host Score ${manager.hostScore}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => controller.openProfile(manager),
                child: Text(_t('View Profile', 'Angalia wasifu')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

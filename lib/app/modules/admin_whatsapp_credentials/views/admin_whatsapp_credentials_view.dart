import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/admin_whatsapp_credentials_controller.dart';

class AdminWhatsappCredentialsView extends BaseView<AdminWhatsappCredentialsController> {
  AdminWhatsappCredentialsView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  Color _statusColor(String status, bool configured) {
    if (configured) return Colors.green.shade700;
    if (status == 'FAILED') return Colors.red.shade700;
    if (status == 'PENDING') return Colors.orange.shade800;
    return Colors.grey.shade700;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(
        context,
        'WhatsApp credentials',
        'Hati miliki za WhatsApp',
      ),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppValues.spacing_20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(
                () => Text(
                  _t(
                    context,
                    '${controller.configuredCount.value} of ${controller.rows.length} hosts linked',
                    'Wamiliki ${controller.configuredCount.value} kati ya ${controller.rows.length} wameunganisha',
                  ),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppValues.spacing_10),
              TextField(
                decoration: InputDecoration(
                  labelText: _t(context, 'Search hosts', 'Tafuta wamiliki'),
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => controller.searchQuery.value = v,
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingList.value) {
              return const DefaultScreenSkeleton();
            }
            final list = controller.filteredRows;
            if (list.isEmpty) {
              return Center(
                child: Text(
                  _t(context, 'No users found', 'Hakuna watumiaji'),
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: controller.loadCredentials,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppValues.spacing_20,
                  vertical: AppValues.spacing_10,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = list[index];
                  final label = row.fullName.trim().isNotEmpty
                      ? row.fullName
                      : row.username;
                  return Card(
                    child: ListTile(
                      isThreeLine: true,
                      title: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.username),
                          if ((row.phoneNumberId ?? '').isNotEmpty)
                            Text(
                              'Phone ID: ${row.phoneNumberId}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if ((row.apiKeyPreview ?? '').isNotEmpty)
                            Text(
                              'Token: ${row.apiKeyPreview}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if ((row.lastError ?? '').trim().isNotEmpty)
                            Text(
                              row.lastError!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            row.configured
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _statusColor(row.status, row.configured),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            row.status,
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(row.status, row.configured),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

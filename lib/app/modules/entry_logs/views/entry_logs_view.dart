import 'package:flutter/material.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/entry_logs_controller.dart';
import '../model/entry_log_item.dart';

const _teal = Color(0xFF0A6A69);

class EntryLogsView extends BaseView<EntryLogsController> {
  EntryLogsView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: Theme.of(context).colorScheme.onSurface,
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            appLocalization.entryLogs,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Obx(
            () {
              final loc = controller.locationName.value.trim();
              final subtitle = loc.isEmpty
                  ? controller.deviceName.value
                  : '${controller.deviceName.value} • $loc';
              return Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: c.secondary,
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Obx(
          () => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh, size: 18, color: _teal),
              label: Text(
                '${_t(context, en: 'SYNCED', sw: 'IMESAWAZISHWA')} ${controller.lastSynced.value.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _teal,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterTabs(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.allItems.isEmpty) {
                return const DefaultScreenSkeleton();
              }
              if (controller.loadError.value.isNotEmpty &&
                  controller.allItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 40,
                          color: c.isDark
                              ? Colors.white54
                              : AppColors.textColorSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.loadError.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: c.isDark
                                ? Colors.white70
                                : AppColors.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: controller.loadLogs,
                          child: Text(
                            _t(context, en: 'Retry', sw: 'Jaribu tena'),
                            style: const TextStyle(color: _teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final byDay = controller.itemsByDay;
              if (byDay.isEmpty) {
                return Center(
                  child: Text(
                    _t(context, en: 'No events', sw: 'Hakuna matukio'),
                    style: TextStyle(
                      fontSize: 16,
                      color: c.isDark
                          ? Colors.white70
                          : AppColors.textColorSecondary,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: byDay.length,
                itemBuilder: (context, index) {
                  final key = byDay.keys.elementAt(index);
                  final items = byDay[key]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.isDark
                                ? Colors.white70
                                : AppColors.textColorSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...items.map((e) => _LogEntryCard(item: e)),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Obx(
      () => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          _FilterChip(
            label: _t(context, en: 'All Events', sw: 'Matukio Yote'),
            isSelected: controller.selectedFilter.value == EntryLogFilter.all,
            onTap: () => controller.setFilter(EntryLogFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _t(context, en: 'APP Unlocks', sw: 'Fungua kwa APP'),
            isSelected:
                controller.selectedFilter.value == EntryLogFilter.appUnlocks,
            onTap: () => controller.setFilter(EntryLogFilter.appUnlocks),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _t(context, en: 'PIN Codes', sw: 'Namba za PIN'),
            isSelected:
                controller.selectedFilter.value == EntryLogFilter.pinCodes,
            onTap: () => controller.setFilter(EntryLogFilter.pinCodes),
          ),
        ],
      ),
    ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Material(
      color: isSelected
          ? _teal.withValues(alpha: 0.15)
          : (c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite),
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: Border.all(
              color: isSelected
                  ? _teal
                  : (c.isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.designInputBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? _teal
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final EntryLogItem item;

  const _LogEntryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.designInputBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.28 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconWidget(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.isDark
                        ? Colors.white70
                        : AppColors.textColorSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.isDark
                            ? Colors.white70
                            : AppColors.textColorSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _statusChip(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconWidget() {
    final (IconData icon, Color color) = switch (item.iconType) {
      EntryLogIconType.phone => (
        Icons.smartphone,
        AppColors.textColorSecondary,
      ),
      EntryLogIconType.lock => (
        Icons.lock_outline,
        AppColors.textColorSecondary,
      ),
      EntryLogIconType.key => (Icons.key, AppColors.textColorSecondary),
      EntryLogIconType.keypad => (Icons.dialpad, AppColors.textColorSecondary),
      EntryLogIconType.warning => (
        Icons.warning_amber_rounded,
        AppColors.paaYanguAlert,
      ),
    };
    return Icon(icon, size: 24, color: color);
  }

  Widget _statusChip() {
    final (String label, Color color) = switch (item.status) {
      EntryLogStatus.success => (
        Get.locale?.languageCode == 'sw' ? 'IMEFAULU' : 'SUCCESS',
        AppColors.colorSuccessGreen,
      ),
      EntryLogStatus.completed => (
        Get.locale?.languageCode == 'sw' ? 'IMEKAMILIKA' : 'COMPLETED',
        AppColors.textColorSecondary,
      ),
      EntryLogStatus.manual => (
        Get.locale?.languageCode == 'sw' ? 'MWONGOZO' : 'MANUAL',
        AppColors.textColorSecondary,
      ),
      EntryLogStatus.alert => (
        Get.locale?.languageCode == 'sw' ? 'TAHADHARI' : 'ALERT',
        AppColors.paaYanguAlert,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

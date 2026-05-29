import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/app_swipeable_card.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/maintenance_tasks_controller.dart';
import '../model/maintenance_task.dart';

class MaintenanceTasksView extends BaseView<MaintenanceTasksController> {
  MaintenanceTasksView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText:
          appLocalization.maintenanceAndTasks, //'Maintenance & Tasks'
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterTabs(context),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const DefaultScreenSkeleton();
              }
              final list = controller.tasks;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    _t(context, en: 'No tasks', sw: 'Hakuna kazi'),
                    style: TextStyle(
                      fontSize: 16,
                      color: context.tokens.textSecondary,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: list.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = list[index];
                  return _SwipeableTaskCard(
                    task: task,
                    onToggleComplete: () => controller.toggleComplete(task),
                    onTap: () => controller.openTaskDetail(task),
                    onCompleteSwipe: () => controller.completeTaskFromSwipe(task),
                    onSnoozeSwipe: () => controller.snoozeTask(task),
                    labelComplete: _t(context, en: 'Complete', sw: 'Maliza'),
                    labelSnooze: _t(context, en: 'Snooze 1 day', sw: 'Ahirisha siku 1'),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget? floatingActionButton() => FloatingActionButton(
    onPressed: controller.addTask,
    backgroundColor: AppColors.designAccent,
    child: const Icon(Icons.add, color: AppColors.textColorWhite, size: 28),
  );

  Widget _buildFilterTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterChip(
                label: _t(context, en: 'All', sw: 'Zote'),
                isSelected: controller.selectedFilter.value == TaskFilter.all,
                onTap: () => controller.setFilter(TaskFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _t(context, en: 'Pending', sw: 'Inasubiri'),
                isSelected:
                    controller.selectedFilter.value == TaskFilter.pending,
                onTap: () => controller.setFilter(TaskFilter.pending),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _t(context, en: 'In Progress', sw: 'Inaendelea'),
                isSelected:
                    controller.selectedFilter.value == TaskFilter.inProgress,
                onTap: () => controller.setFilter(TaskFilter.inProgress),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _t(context, en: 'Completed', sw: 'Imekamilika'),
                isSelected:
                    controller.selectedFilter.value == TaskFilter.completed,
                onTap: () => controller.setFilter(TaskFilter.completed),
              ),
            ],
          ),
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
          ? AppColors.colorPrimary
          : (c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite),
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: isSelected
                ? null
                : Border.all(
                    color: c.isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.designInputBorder,
                  ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.textColorWhite
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeableTaskCard extends StatelessWidget {
  const _SwipeableTaskCard({
    required this.task,
    required this.onToggleComplete,
    required this.onTap,
    required this.onCompleteSwipe,
    required this.onSnoozeSwipe,
    required this.labelComplete,
    required this.labelSnooze,
  });

  final MaintenanceTask task;
  final VoidCallback onToggleComplete;
  final VoidCallback onTap;
  final VoidCallback onCompleteSwipe;
  final Future<void> Function() onSnoozeSwipe;
  final String labelComplete;
  final String labelSnooze;

  @override
  Widget build(BuildContext context) {
    return AppSwipeableCard(
      dismissKey: ValueKey('task_swipe_${task.id}'),
      startLabel: labelSnooze,
      endLabel: labelComplete,
      onSwipeStartToEnd: onSnoozeSwipe,
      onSwipeEndToStart: () async => onCompleteSwipe(),
      child: _TaskCard(
        task: task,
        onToggleComplete: onToggleComplete,
        onTap: onTap,
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final MaintenanceTask task;
  final VoidCallback onToggleComplete;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onToggleComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final isCompleted = task.isCompleted;
    final opacity = isCompleted ? 0.6 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card.copyWith(
            color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
            border: Border.all(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: c.isDark ? 0.28 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckbox(context, isCompleted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            (c.headline)
                                .withValues(alpha: opacity),
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Get.locale?.languageCode == 'sw' ? 'Amepewa' : 'Assigned to'} ${task.assignee}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.colorPrimary.withValues(
                          alpha: opacity,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isCompleted && task.completedAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color:
                                (c.isDark
                                        ? Colors.white70
                                        : AppColors.textColorSecondary)
                                    .withValues(alpha: opacity),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${Get.locale?.languageCode == 'sw' ? 'Imekamilika' : 'Completed'} ${_formatCompletedAgo(task.completedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  (c.isDark
                                          ? Colors.white70
                                          : AppColors.textColorSecondary)
                                      .withValues(alpha: opacity),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color:
                                (c.isDark
                                        ? Colors.white70
                                        : AppColors.textColorSecondary)
                                    .withValues(alpha: opacity),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.dueDate != null
                                ? _formatDueDate(task.dueDate!)
                                : (Get.locale?.languageCode == 'sw'
                                      ? 'Hakuna tarehe'
                                      : 'No date'),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  (c.isDark
                                          ? Colors.white70
                                          : AppColors.textColorSecondary)
                                      .withValues(alpha: opacity),
                            ),
                          ),
                        ],
                      ),
                    if (!isCompleted) ...[
                      const SizedBox(height: 8),
                      _PriorityLabel(priority: task.priority),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: (c.secondary)
                    .withValues(alpha: opacity),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context, bool isCompleted) {
    final c = FormSurfaceColors.of(context);
    return GestureDetector(
      onTap: onToggleComplete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.colorPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCompleted
                ? AppColors.colorPrimary
                : (c.isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.designInputBorder),
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: AppColors.textColorWhite)
            : null,
      ),
    );
  }

  String _formatDueDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(d.year, d.month, d.day);
    final time = DateFormat.jm().format(d);
    if (taskDate == today) {
      return Get.locale?.languageCode == 'sw' ? 'Leo, $time' : 'Today, $time';
    }
    if (taskDate == tomorrow) {
      return Get.locale?.languageCode == 'sw'
          ? 'Kesho, $time'
          : 'Tomorrow, $time';
    }
    return '${DateFormat('EEEE').format(d)}, $time';
  }

  String _formatCompletedAgo(DateTime completedAt) {
    final diff = DateTime.now().difference(completedAt);
    if (diff.inHours > 0) {
      return Get.locale?.languageCode == 'sw'
          ? 'saa ${diff.inHours} zilizopita'
          : '${diff.inHours}h ago';
    }
    if (diff.inMinutes > 0) {
      return Get.locale?.languageCode == 'sw'
          ? 'dakika ${diff.inMinutes} zilizopita'
          : '${diff.inMinutes}m ago';
    }
    return Get.locale?.languageCode == 'sw' ? 'Sasa hivi' : 'Just now';
  }
}

class _PriorityLabel extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityLabel({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (priority) {
      TaskPriority.high => (
        Get.locale?.languageCode == 'sw'
            ? 'KIPAUMBELE CHA JUU'
            : 'HIGH PRIORITY',
        const Color(0xFFE07A5F),
        AppColors.textColorWhite,
      ),
      TaskPriority.medium => (
        Get.locale?.languageCode == 'sw' ? 'WASTANI' : 'MEDIUM',
        const Color(0xFFF5A623),
        AppColors.textColorPrimary,
      ),
      TaskPriority.low => (
        Get.locale?.languageCode == 'sw' ? 'CHINI' : 'LOW',
        AppColors.slateBlueGrey.withValues(alpha: 0.3),
        AppColors.textColorPrimary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

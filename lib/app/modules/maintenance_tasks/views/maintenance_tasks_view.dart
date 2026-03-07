import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/maintenance_tasks_controller.dart';
import '../model/maintenance_task.dart';

class MaintenanceTasksView extends BaseView<MaintenanceTasksController> {
  MaintenanceTasksView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.maintenanceAndTasks, //'Maintenance & Tasks'
      isCentered: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: AppColors.colorPrimary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: controller.addTask,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.add, color: AppColors.textColorWhite, size: 24),
              ),
            ),
          ),
        ),
      ],
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
              final list = controller.filteredTasks;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _TaskCard(
                  task: list[index],
                  onToggleComplete: () => controller.toggleComplete(list[index]),
                  onTap: () => controller.openTaskDetail(list[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterChip(label: 'All', isSelected: controller.selectedFilter.value == TaskFilter.all, onTap: () => controller.setFilter(TaskFilter.all)),
            const SizedBox(width: 8),
            _FilterChip(label: 'Pending', isSelected: controller.selectedFilter.value == TaskFilter.pending, onTap: () => controller.setFilter(TaskFilter.pending)),
            const SizedBox(width: 8),
            _FilterChip(label: 'In Progress', isSelected: controller.selectedFilter.value == TaskFilter.inProgress, onTap: () => controller.setFilter(TaskFilter.inProgress)),
            const SizedBox(width: 8),
            _FilterChip(label: 'Completed', isSelected: controller.selectedFilter.value == TaskFilter.completed, onTap: () => controller.setFilter(TaskFilter.completed)),
          ],
        )),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.colorPrimary : AppColors.colorWhite,
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: isSelected ? null : Border.all(color: AppColors.designInputBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.textColorWhite : AppColors.textColorPrimary,
            ),
          ),
        ),
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
    final isCompleted = task.isCompleted;
    final opacity = isCompleted ? 0.6 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckbox(isCompleted),
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
                        color: AppColors.textColorPrimary.withOpacity(opacity),
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assigned to ${task.assignee}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.colorPrimary.withOpacity(opacity),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isCompleted && task.completedAt != null)
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: AppColors.textColorSecondary.withOpacity(opacity)),
                          const SizedBox(width: 6),
                          Text(
                            'Completed ${_formatCompletedAgo(task.completedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textColorSecondary.withOpacity(opacity),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textColorSecondary.withOpacity(opacity)),
                          const SizedBox(width: 6),
                          Text(
                            task.dueDate != null ? _formatDueDate(task.dueDate!) : 'No date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textColorSecondary.withOpacity(opacity),
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
              Icon(Icons.chevron_right, color: AppColors.textColorSecondary.withOpacity(opacity), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isCompleted) {
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
            color: isCompleted ? AppColors.colorPrimary : AppColors.designInputBorder,
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
    if (taskDate == today) return 'Today, $time';
    if (taskDate == tomorrow) return 'Tomorrow, $time';
    return '${DateFormat('EEEE').format(d)}, $time';
  }

  String _formatCompletedAgo(DateTime completedAt) {
    final diff = DateTime.now().difference(completedAt);
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _PriorityLabel extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityLabel({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (priority) {
      TaskPriority.high => ('HIGH PRIORITY', const Color(0xFFE07A5F), AppColors.textColorWhite),
      TaskPriority.medium => ('MEDIUM', const Color(0xFFF5A623), AppColors.textColorPrimary),
      TaskPriority.low => ('LOW', AppColors.slateBlueGrey.withOpacity(0.3), AppColors.textColorPrimary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

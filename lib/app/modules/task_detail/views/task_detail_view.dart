import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../maintenance_tasks/model/maintenance_task.dart';
import '../controllers/task_detail_controller.dart';

class TaskDetailView extends BaseView<TaskDetailController> {
  TaskDetailView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(context, en: 'Task detail', sw: 'Maelezo ya kazi'),
      isCentered: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          color: FormSurfaceColors.of(context).isDark
              ? Colors.white
              : AppColors.appBarIconColor,
          onPressed: controller.openEdit,
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      final err = controller.loadError.value;
      final task = controller.task.value;

      if (controller.loading.value && task == null) {
        return const DefaultScreenSkeleton();
      }

      if (task == null || task.id.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  err ??
                      _t(context, en: 'Task not found', sw: 'Kazi haipo'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.loadTask,
                  child: Text(_t(context, en: 'Retry', sw: 'Jaribu tena')),
                ),
              ],
            ),
          ),
        );
      }

      final c = FormSurfaceColors.of(context);
      final dateFmt = DateFormat.yMMMd().add_jm();
      final surface = c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite;

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: controller.loadTask,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (err != null) ...[
                    Material(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppValues.radius_6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          err,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    task.title.isEmpty
                        ? _t(context, en: 'Untitled task', sw: 'Kazi bila jina')
                        : task.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (task.id.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_t(context, en: 'ID', sw: 'Kitambulisho')}: ${task.id}',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.isDark ? Colors.white60 : AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _infoCard(
                    context,
                    surface: surface,
                    isDark: c.isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row(
                          context,
                          Icons.flag_outlined,
                          _t(context, en: 'Status', sw: 'Hali'),
                          _statusLabel(context, task.status),
                        ),
                        const Divider(height: 28),
                        _row(
                          context,
                          Icons.priority_high,
                          _t(context, en: 'Priority', sw: 'Kipaumbele'),
                          _priorityLabel(context, task.priority),
                        ),
                        const Divider(height: 28),
                        _row(
                          context,
                          Icons.person_outline,
                          _t(context, en: 'Assignee', sw: 'Aliyepewa'),
                          task.assignee.isEmpty
                              ? _t(context, en: 'Unassigned', sw: 'Hajapewa mtu')
                              : task.assignee,
                        ),
                        if (task.dueDate != null) ...[
                          const Divider(height: 28),
                          _row(
                            context,
                            Icons.event_outlined,
                            _t(context, en: 'Due', sw: 'Mwisho'),
                            dateFmt.format(task.dueDate!.toLocal()),
                          ),
                        ],
                        if (task.isCompleted && task.completedAt != null) ...[
                          const Divider(height: 28),
                          _row(
                            context,
                            Icons.check_circle_outline,
                            _t(context, en: 'Completed at', sw: 'Imekamilika'),
                            dateFmt.format(task.completedAt!.toLocal()),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    context,
                    surface: surface,
                    isDark: c.isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(context, en: 'Description', sw: 'Maelezo'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: c.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description.trim().isEmpty
                              ? _t(
                                  context,
                                  en: 'No description',
                                  sw: 'Hakuna maelezo',
                                )
                              : task.description.trim(),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: controller.toggleComplete,
                    child: Text(
                      task.isCompleted
                          ? _t(
                              context,
                              en: 'Mark as not done',
                              sw: 'Weka kama haijakamilika',
                            )
                          : _t(
                              context,
                              en: 'Mark as done',
                              sw: 'Weka kama imekamilika',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (controller.loading.value && controller.task.value != null)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _infoCard(
    BuildContext context, {
    required Color surface,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.designInputBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final c = FormSurfaceColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.colorPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.isDark ? Colors.white60 : AppColors.textColorSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(BuildContext context, TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return _t(context, en: 'Pending', sw: 'Inasubiri');
      case TaskStatus.inProgress:
        return _t(context, en: 'In progress', sw: 'Inaendelea');
      case TaskStatus.completed:
        return _t(context, en: 'Completed', sw: 'Imekamilika');
    }
  }

  String _priorityLabel(BuildContext context, TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return _t(context, en: 'High', sw: 'Juu');
      case TaskPriority.medium:
        return _t(context, en: 'Medium', sw: 'Wastani');
      case TaskPriority.low:
        return _t(context, en: 'Low', sw: 'Chini');
    }
  }
}

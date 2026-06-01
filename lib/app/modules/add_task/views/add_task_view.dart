import 'package:flutter/material.dart';
import 'package:host_bora/app/core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/loading_button.dart';
import '../controllers/add_task_controller.dart';

class AddTaskView extends BaseView<AddTaskController> {
  AddTaskView({super.key});

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: 'Add Task', isCentered: true);
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final labelColor = c.headline;
    final valueColor = c.headline;
    final hintColor = c.isDark
        ? const Color(0xFF8E8E93)
        : AppColors.designPlaceholder;
    final containerBg = c.isDark ? context.tokens.cardBackground : AppColors.colorWhite;
    final borderColor = c.isDark
        ? context.tokens.elevatedSurface
        : AppColors.designInputBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Title',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.titleController,
              style: TextStyle(color: valueColor),
              decoration: _decoration(context, hint: 'e.g. Clean Beach House'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Description (optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.descriptionController,
              maxLines: 3,
              style: TextStyle(color: valueColor),
              decoration: _decoration(context, hint: 'Add details...'),
            ),
            const SizedBox(height: 20),
            Text(
              'Due date (optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final label = controller.dueDateLabel ?? 'Pick date';
              return InkWell(
                onTap: () => controller.pickDueDate(context),
                borderRadius: BorderRadius.circular(AppValues.radius_6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: containerBg,
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: hintColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          color: controller.dueDate.value != null
                              ? valueColor
                              : hintColor,
                        ),
                      ),
                      const Spacer(),
                      if (controller.dueDate.value != null)
                        IconButton(
                          onPressed: controller.clearDueDate,
                          icon: const Icon(Icons.close, size: 20),
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.textColorSecondary,
                            padding: const EdgeInsets.all(4),
                            minimumSize: const Size(36, 36),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            Obx(
              () => LoadingButton(
                label: 'Add Task',
                onPressed: controller.submit,
                isLoading: controller.saving.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, {required String hint}) {
    final c = FormSurfaceColors.of(context);
    final borderColor = c.isDark
        ? context.tokens.elevatedSurface
        : AppColors.designInputBorder;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: c.isDark ? const Color(0xFF8E8E93) : AppColors.designPlaceholder,
      ),
      filled: true,
      fillColor: c.isDark ? context.tokens.cardBackground : AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/feedback_controller.dart';

class FeedbackView extends BaseView<FeedbackController> {
  FeedbackView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.sendFeedback,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final l10n = appLocalization;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : AppColors.textColorSecondary;
    final labelColor = isDark ? Colors.white : AppColors.textColorPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppValues.padding),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppValues.margin_20),
            Text(
              l10n.sendFeedbackIntro,
              style: TextStyle(fontSize: 16, height: 1.5, color: bodyColor),
            ),
            const SizedBox(height: AppValues.largePadding),
            Text(
              l10n.feedbackCategoryLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.feedbackCategoryOptional,
              style: TextStyle(fontSize: 13, color: bodyColor),
            ),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<FeedbackCategory>(
                key: ValueKey(controller.selectedCategory.value),
                initialValue: controller.selectedCategory.value,
                decoration: InputDecoration(
                  hintText: l10n.feedbackCategoryHint,
                  border: const OutlineInputBorder(),
                ),
                items: FeedbackCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(controller.categoryLabel(c)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => controller.selectedCategory.value = v,
              ),
            ),
            const SizedBox(height: AppValues.largePadding),
            Text(
              l10n.feedbackMessageLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.messageController,
              maxLines: 6,
              validator: controller.validateMessage,
              decoration: InputDecoration(
                hintText: l10n.feedbackMessageHint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppValues.largePadding),
            Text(
              l10n.feedbackEmailLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.feedbackEmailOptional,
              style: TextStyle(fontSize: 13, color: bodyColor),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
              decoration: InputDecoration(
                hintText: l10n.feedbackEmailHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppValues.largePadding),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.submit,
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.feedbackSubmitButton),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

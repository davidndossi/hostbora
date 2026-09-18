import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/feedback_controller.dart';

class FeedbackView extends BaseView<FeedbackController> {
  FeedbackView({super.key});

  Color _accent(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return c.isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.colorPrimary;
  }

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
    final c = FormSurfaceColors.of(context);
    final accent = _accent(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hero(l10n, c, accent),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.feedbackCategoryLabel, c.headline),
                  const SizedBox(height: 2),
                  Text(
                    l10n.feedbackCategoryOptional,
                    style: TextStyle(fontSize: 13, color: c.secondary),
                  ),
                  const SizedBox(height: 12),
                  _categoryGrid(c, accent),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.feedbackMessageLabel, c.headline),
                  const SizedBox(height: 10),
                  _messageField(l10n, c, accent),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.feedbackEmailLabel, c.headline),
                  const SizedBox(height: 2),
                  Text(
                    l10n.feedbackEmailOptional,
                    style: TextStyle(fontSize: 13, color: c.secondary),
                  ),
                  const SizedBox(height: 10),
                  _emailField(l10n, c, accent),
                ],
              ),
            ),
          ),
        ),
        _submitBar(context, l10n, c, accent),
      ],
    );
  }

  Widget _hero(AppLocalizations l10n, FormSurfaceColors c, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: c.isDark ? c.card : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.isDark ? c.border : accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: c.isDark ? 0.22 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rate_review_outlined, color: accent, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.sendFeedback,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.headline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sendFeedbackIntro,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: c.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryGrid(FormSurfaceColors c, Color accent) {
    return Obx(() {
      final selected = controller.selectedCategory.value;
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.35,
        children: FeedbackCategory.values.map((category) {
          final isOn = selected == category;
          return Material(
            color: isOn
                ? accent.withValues(alpha: c.isDark ? 0.22 : 0.12)
                : c.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => controller.selectCategory(category),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOn ? accent : c.border,
                    width: isOn ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isOn ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        controller.categoryIcon(category),
                        size: 18,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.categoryLabel(category),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.headline,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _messageField(
    AppLocalizations l10n,
    FormSurfaceColors c,
    Color accent,
  ) {
    return TextFormField(
      controller: controller.messageController,
      maxLines: 7,
      minLines: 5,
      validator: controller.validateMessage,
      textCapitalization: TextCapitalization.sentences,
      decoration: _fieldDecoration(
        c,
        accent,
        hint: l10n.feedbackMessageHint,
      ).copyWith(
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _emailField(
    AppLocalizations l10n,
    FormSurfaceColors c,
    Color accent,
  ) {
    return TextFormField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      validator: controller.validateEmail,
      decoration: _fieldDecoration(
        c,
        accent,
        hint: l10n.feedbackEmailHint,
        prefix: Icons.mail_outline_rounded,
      ),
    );
  }

  InputDecoration _fieldDecoration(
    FormSurfaceColors c,
    Color accent, {
    required String hint,
    IconData? prefix,
  }) {
    final radius = BorderRadius.circular(14);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.hint, fontSize: 14),
      prefixIcon: prefix == null ? null : Icon(prefix, color: c.hint),
      filled: true,
      fillColor: c.inputFill,
      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: c.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: c.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.errorColor, width: 1.4),
      ),
    );
  }

  Widget _submitBar(
    BuildContext context,
    AppLocalizations l10n,
    FormSurfaceColors c,
    Color accent,
  ) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Obx(() {
            final busy = controller.isSubmitting.value;
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: busy ? null : controller.submit,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  l10n.feedbackSubmitButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: accent.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

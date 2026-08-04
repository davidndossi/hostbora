import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordView extends BaseView<ResetPasswordController> {
  ResetPasswordView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : AppColors.pageBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: controller.goBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
        color: isDark
            ? theme.colorScheme.onSurface
            : AppColors.textColorPrimary,
        style: IconButton.styleFrom(
          backgroundColor: isDark
              ? theme.colorScheme.surfaceContainerHigh
              : AppColors.colorWhite,
          foregroundColor: isDark
              ? theme.colorScheme.onSurface
              : AppColors.textColorPrimary,
          shape: const CircleBorder(),
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      _t(context, 'Reset Password', 'Weka Upya Nenosiri'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : AppColors.textColorPrimary,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _t(
                        context,
                        'Enter your registered phone number and we will send you a verification code.',
                        'Weka namba yako ya simu iliyosajiliwa, tutakutumia msimbo wa uthibitisho.',
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.textColorSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _t(context, 'Phone Number', 'Namba ya Simu'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : AppColors.textColorPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.msisdnController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : AppColors.textColorPrimary,
                      ),
                      decoration: _inputDecoration(
                        context,
                        hint: _t(context, 'e.g. 0712345678', 'mf. 0712345678'),
                      ),
                      validator: controller.validateMsisdn,
                    ),
                    const SizedBox(height: 32),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.isTrue
                              ? null
                              : controller.sendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colorPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppValues.radius_6,
                              ),
                            ),
                          ),
                          child: controller.isLoading.isTrue
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _t(context, 'Send Code', 'Tuma Msimbo'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: TextButton.icon(
              onPressed: controller.backToLogin,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.colorPrimary,
              ),
              label: Text(
                _t(context, 'Back to Login', 'Rudi Kuingia'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? const Color(0xFF8E8E93)
            : AppColors.designPlaceholder,
      ),
      filled: true,
      fillColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: isDark ? theme.colorScheme.primary : AppColors.colorPrimary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }
}

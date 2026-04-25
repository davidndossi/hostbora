import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/new_password_controller.dart';

class NewPasswordView extends GetView<NewPasswordController> {
  const NewPasswordView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? theme.colorScheme.surface
            : AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: controller.goBack,
          icon: const Icon(Icons.chevron_left),
          color: isDark
              ? theme.colorScheme.onSurface
              : AppColors.textColorPrimary,
        ),
        centerTitle: true,
        title: Text(
          '${_t(context, en: 'STEP', sw: 'HATUA')} ${NewPasswordController.step} ${_t(context, en: 'OF', sw: 'KATI YA')} ${NewPasswordController.totalSteps}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark
                ? theme.colorScheme.onSurfaceVariant
                : AppColors.textColorSecondary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                _t(context, en: 'New Password', sw: 'Nenosiri Jipya'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? theme.colorScheme.onSurface
                      : AppColors.textColorPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _t(
                  context,
                  en: 'Your new password must be different from previously used passwords to keep your host account secure.',
                  sw: 'Nenosiri lako jipya lazima litofautiane na manenosiri yaliyotumika awali ili kulinda akaunti yako ya mwenyeji.',
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : AppColors.textColorSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel(
                context,
                _t(context, en: 'New Password', sw: 'Nenosiri Jipya'),
              ),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.newPasswordController,
                  obscureText: controller.obscureNewPassword.value,
                  onChanged: (_) => controller.refreshPasswordUi(),
                  decoration: _inputDecoration(
                    context: context,
                    hint: 'StrongPassword123!',
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureNewPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.designPlaceholder,
                        size: 22,
                      ),
                      onPressed: controller.toggleNewPasswordVisibility,
                    ),
                  ),
                  validator: controller.validateNewPassword,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => _buildStrengthSection(context)),
              const SizedBox(height: 20),
              _buildLabel(
                context,
                _t(
                  context,
                  en: 'Confirm New Password',
                  sw: 'Thibitisha Nenosiri Jipya',
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.confirmPasswordController,
                  obscureText: controller.obscureConfirmPassword.value,
                  onChanged: (_) => controller.refreshPasswordUi(),
                  decoration: _inputDecoration(
                    context: context,
                    hint: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureConfirmPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.designPlaceholder,
                        size: 22,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                  validator: controller.validateConfirm,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => _buildValidationRules(context)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.isLoading.isTrue
                        ? null
                        : controller.resetAndLogin,
                    icon: controller.isLoading.isTrue
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: Colors.white,
                          ),
                    label: Text(
                      controller.isLoading.isTrue
                          ? _t(context, en: 'Updating...', sw: 'Inasasisha...')
                          : _t(
                              context,
                              en: 'Reset and Login',
                              sw: 'Weka Upya na Ingia',
                            ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? theme.colorScheme.primary
                          : AppColors.designAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppValues.radius_6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  _t(
                    context,
                    en: 'By resetting your password, you will be logged out of all other active sessions on different devices.',
                    sw: 'Kwa kuweka upya nenosiri lako, utaondolewa kwenye vipindi vyote vingine vinavyoendelea kwenye vifaa vingine.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : AppColors.textColorSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? theme.colorScheme.onSurfaceVariant
            : AppColors.designPlaceholder,
      ),
      filled: true,
      fillColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : AppColors.colorWhite,
      suffixIcon: suffixIcon,
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
          color: isDark ? theme.colorScheme.primary : AppColors.designAccent,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }

  Widget _buildStrengthSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, en: 'PASSWORD STRENGTH', sw: 'NGUVU YA NENOSIRI'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark
                ? theme.colorScheme.onSurfaceVariant
                : AppColors.textColorSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: controller.strength,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : AppColors.lightGreyColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    controller.strength >= 0.75
                        ? AppColors.colorSuccessGreen
                        : AppColors.designAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.colorPrimaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.designAccent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: AppColors.designAccent),
                  const SizedBox(width: 6),
                  Text(
                    controller.strengthLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.designAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValidationRules(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ValidationRow(
          met: controller.hasMinLength,
          label: _t(
            context,
            en: 'At least 8 characters',
            sw: 'Angalau herufi 8',
          ),
        ),
        const SizedBox(height: 4),
        _ValidationRow(
          met: controller.hasNumberOrSymbol,
          label: _t(
            context,
            en: 'Contains a number or symbol',
            sw: 'Ina namba au alama',
          ),
        ),
      ],
    );
  }
}

class _ValidationRow extends StatelessWidget {
  final bool met;
  final String label;

  const _ValidationRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: met
              ? AppColors.colorSuccessGreen
              : AppColors.designPlaceholder,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: met
                ? AppColors.colorSuccessGreen
                : AppColors.textColorSecondary,
          ),
        ),
      ],
    );
  }
}

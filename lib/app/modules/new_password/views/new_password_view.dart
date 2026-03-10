import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/new_password_controller.dart';

class NewPasswordView extends GetView<NewPasswordController> {
  const NewPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: controller.goBack,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textColorPrimary,
        ),
        centerTitle: true,
        title: Text(
          'STEP ${NewPasswordController.step} OF ${NewPasswordController.totalSteps}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textColorSecondary,
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
                'New Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColorPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your new password must be different from previously used passwords to keep your host account secure.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textColorSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('New Password'),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.newPasswordController,
                  obscureText: controller.obscureNewPassword.value,
                  onChanged: (_) => controller.refreshPasswordUi(),
                  decoration: _inputDecoration(
                    hint: 'StrongPassword123!',
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureNewPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.designPlaceholder,
                        size: 22,
                      ),
                      onPressed: controller.toggleNewPasswordVisibility,
                    ),
                  ),
                  validator: controller.validateNewPassword,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => _buildStrengthSection()),
              const SizedBox(height: 20),
              _buildLabel('Confirm New Password'),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.confirmPasswordController,
                  obscureText: controller.obscureConfirmPassword.value,
                  onChanged: (_) => controller.refreshPasswordUi(),
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureConfirmPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.designPlaceholder,
                        size: 22,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                  validator: controller.validateConfirm,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => _buildValidationRules()),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isLoading.isTrue ? null : controller.resetAndLogin,
                  icon: controller.isLoading.isTrue
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                  label: Text(controller.isLoading.isTrue ? 'Updating...' : 'Reset and Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.designAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppValues.radius_6),
                    ),
                    elevation: 0,
                  ),
                )),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'By resetting your password, you will be logged out of all other active sessions on different devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textColorSecondary,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textColorPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.designPlaceholder),
      filled: true,
      fillColor: AppColors.colorWhite,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
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

  Widget _buildStrengthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASSWORD STRENGTH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textColorSecondary,
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
                  backgroundColor: AppColors.lightGreyColor,
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
                  Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.designAccent,
                  ),
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

  Widget _buildValidationRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ValidationRow(
          met: controller.hasMinLength,
          label: 'At least 8 characters',
        ),
        const SizedBox(height: 4),
        _ValidationRow(
          met: controller.hasNumberOrSymbol,
          label: 'Contains a number or symbol',
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
          color: met ? AppColors.colorSuccessGreen : AppColors.designPlaceholder,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: met ? AppColors.colorSuccessGreen : AppColors.textColorSecondary,
          ),
        ),
      ],
    );
  }
}

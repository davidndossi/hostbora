import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../routes/app_pages.dart';
import '../controllers/auth_controller.dart';

class AuthView extends BaseView<AuthController> {
  AuthView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                'images/paa_yangu_logo.png',
                width: 100,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.home_work_rounded,
                  size: 80,
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Sign in',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use your phone and password, or sign in with PIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColorSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildFormCard(context),
            const SizedBox(height: 24),
            _buildOrDivider(),
            const SizedBox(height: 24),
            _buildUsePinButton(context),
            const SizedBox(height: 32),
            _buildFooterLinks(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: controller.authFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => TextFormField(
                controller: controller.msisdnController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  label: appLocalization.msisdn,
                  hint: 'e.g. 0712345678',
                  errorText: controller.errorText.value,
                ),
                validator: controller.validator,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              decoration: _inputDecoration(
                label: appLocalization.password,
                hint: '••••••••',
              ),
              validator: controller.passwordValidator,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed(Routes.RESET_PASSWORD),
                child: Text(
                  appLocalization.forgotPassword,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isLoading.isTrue ? null : controller.login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.colorPrimary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppValues.radius_6),
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
                      : Text(
                          appLocalization.login,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.colorPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.designInputBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.designInputBorder)),
      ],
    );
  }

  Widget _buildUsePinButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Get.toNamed(Routes.WELCOME_BACK),
      icon: const Icon(Icons.pin_rounded, size: 22, color: AppColors.colorPrimary),
      label: const Text(
        'Use PIN to sign in',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.colorPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppColors.colorPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
        ),
      ),
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => Get.toNamed(Routes.CREATE_HOST_ACCOUNT),
          child: const Text(
            'Create host account',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.colorPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/utils/password_policy.dart';
import '../../../core/values/text_styles.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordView extends BaseView<ChangePasswordController> {
  ChangePasswordView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(
        context,
        en: 'Change Password',
        sw: 'Badili Nenosiri',
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, en: 'Current password', sw: 'Nenosiri la sasa'),
                style: blackText16.copyWith(color: c.headline),
              ),
              const SizedBox(height: 10),
              Obx(
                () => TextFormField(
                  controller: controller.currentPasswordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: controller.obscureCurrentPassword.value,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(color: c.headline),
                  decoration: _inputDecoration(
                    context,
                    hint: '••••••••',
                    obscure: controller.obscureCurrentPassword.value,
                    onToggleVisibility:
                        controller.toggleCurrentPasswordVisibility,
                  ),
                  validator: controller.validateCurrentPassword,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _t(context, en: 'New password', sw: 'Nenosiri jipya'),
                style: blackText16.copyWith(color: c.headline),
              ),
              const SizedBox(height: 4),
              Text(
                PasswordPolicy.requirementsHint(
                  isSw: Localizations.localeOf(context).languageCode == 'sw',
                ),
                style: TextStyle(fontSize: 13, color: c.hint, height: 1.35),
              ),
              const SizedBox(height: 10),
              Obx(
                () => TextFormField(
                  controller: controller.newPasswordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: controller.obscureNewPassword.value,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(color: c.headline),
                  decoration: _inputDecoration(
                    context,
                    hint: '••••••••',
                    obscure: controller.obscureNewPassword.value,
                    onToggleVisibility: controller.toggleNewPasswordVisibility,
                  ),
                  validator: controller.validateNewPassword,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _t(
                  context,
                  en: 'Re-enter new password',
                  sw: 'Ingiza tena nenosiri jipya',
                ),
                style: blackText16.copyWith(color: c.headline),
              ),
              const SizedBox(height: 10),
              Obx(
                () => TextFormField(
                  controller: controller.reenterNewPasswordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: controller.obscureReenterPassword.value,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(color: c.headline),
                  decoration: _inputDecoration(
                    context,
                    hint: '••••••••',
                    obscure: controller.obscureReenterPassword.value,
                    onToggleVisibility:
                        controller.toggleReenterPasswordVisibility,
                  ),
                  validator: controller.validateReenterNewPassword,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 316,
                  height: 48,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.changePassword,
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                          : Text(
                              _t(
                                context,
                                en: appLocalization.changePassword,
                                sw: 'Badili nenosiri',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    final c = FormSurfaceColors.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.hint, fontSize: 15),
      filled: true,
      fillColor: c.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: IconButton(
        tooltip: obscure
            ? _t(context, en: 'Show password', sw: 'Onyesha nenosiri')
            : _t(context, en: 'Hide password', sw: 'Ficha nenosiri'),
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: c.hint,
          size: 22,
        ),
        onPressed: onToggleVisibility,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

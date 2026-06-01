import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../routes/app_pages.dart';
import '../controllers/registration_controller.dart';

class RegistrationView extends BaseView<RegistrationController> {
  RegistrationView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    String? hint,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 15),
      hintStyle: const TextStyle(fontSize: 14),
      filled: true,
      fillColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : AppColors.colorWhite,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          width: 1,
          color: isDark ? theme.colorScheme.outlineVariant : Colors.black54,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.colorPrimary, width: 1),
      ),
    );
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(horizontal: AppValues.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Image.asset('images/host_bora_logo.png', width: 100),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                appLocalization.registerYourAccount,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? theme.colorScheme.onSurface : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: controller.registerFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextFormField(
                      autofocus: true,
                      controller: controller.nameController,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(fontSize: 16),
                      decoration: _decoration(
                        context,
                        label: appLocalization.name,
                      ),
                      validator: controller.nameValidator,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.msisdnController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16),
                      decoration: _decoration(
                        context,
                        label: appLocalization.msisdn,
                      ),
                      validator: controller.msisdnValidator,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 16),
                      decoration: _decoration(
                        context,
                        label: _t(
                          context,
                          'Email (optional)',
                          'Barua pepe (si lazima)',
                        ),
                        hint: _t(
                          context,
                          'e.g. you@example.com',
                          'mf. jina@mfano.com',
                        ),
                      ),
                      validator: controller.emailValidator,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        _t(context, 'Gender', 'Jinsia'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? theme.colorScheme.onSurface : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => RadioGroup(
                              groupValue: controller.selectedGender.value,
                              onChanged: (String? value) {
                                controller.selectedGender(value);
                              },
                              child: RadioListTile<String>(
                                title: Text(
                                  _t(context, 'Male', 'Mwanaume'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? theme.colorScheme.onSurface
                                        : null,
                                  ),
                                ),
                                value: 'male',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Obx(
                            () => RadioGroup(
                              groupValue: controller.selectedGender.value,
                              onChanged: (String? value) {
                                controller.selectedGender(value);
                              },
                              child: RadioListTile<String>(
                                title: Text(
                                  _t(context, 'Female', 'Mwanamke'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? theme.colorScheme.onSurface
                                        : null,
                                  ),
                                ),
                                value: 'female',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      style: const TextStyle(fontSize: 16),
                      decoration: _decoration(
                        context,
                        label: appLocalization.password,
                      ),
                      obscureText: true,
                      validator: controller.passwordValidator,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        width: 316,
                        height: 48,
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: controller.isLoading.isTrue
                                ? null
                                : controller.register,
                            style: ButtonStyle(
                              fixedSize: WidgetStateProperty.all(
                                const Size(
                                  AppValues.size_200,
                                  AppValues.size_48,
                                ),
                              ),
                            ),
                            child: controller.isLoading.isTrue
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 1.5,
                                    ),
                                  )
                                : Text(
                                    appLocalization.register,
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
            const SizedBox(height: 20),
            Align(
              alignment: FractionalOffset.bottomCenter,
              child: InkWell(
                onTap: () => Get.offAllNamed(Routes.AUTH),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    appLocalization.login,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.colorPrimary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.colorPrimary,
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
}

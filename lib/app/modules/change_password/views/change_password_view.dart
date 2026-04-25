import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/text_styles.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordView extends BaseView<ChangePasswordController> {
  ChangePasswordView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, en: 'Current password', sw: 'Nenosiri la sasa'),
                style: blackText16.copyWith(
                  color: _isDark(context) ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.currentPasswordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: _t(
                    context,
                    en: appLocalization.currentPassword,
                    sw: 'Nenosiri la sasa',
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: controller.validateCurrentPassword,
              ),
              const SizedBox(height: 20),
              Text(
                _t(context, en: 'New password', sw: 'Nenosiri jipya'),
                style: blackText16.copyWith(
                  color: _isDark(context) ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.newPasswordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  hintText: _t(
                    context,
                    en: appLocalization.newPassword,
                    sw: 'Nenosiri jipya',
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: controller.validateNewPassword,
              ),
              const SizedBox(height: 20),
              Text(
                _t(
                  context,
                  en: 'Re-enter new password',
                  sw: 'Ingiza tena nenosiri jipya',
                ),
                style: blackText16.copyWith(
                  color: _isDark(context) ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.reenterNewPasswordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  hintText: _t(
                    context,
                    en: appLocalization.reenterNewPassword,
                    sw: 'Ingiza tena nenosiri jipya',
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: controller.validateReenterNewPassword,
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
}

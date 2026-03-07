import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/text_styles.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordView extends BaseView<ChangePasswordController> {
  ChangePasswordView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: 'Change Password'
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
              const Text(
                'Current password',
                style: blackText16,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.currentPasswordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: appLocalization.currentPassword,
                  border: OutlineInputBorder(),
                ),
                validator: controller.validateCurrentPassword,
              ),
              const SizedBox(height: 20),
              const Text(
                'New password',
                style: blackText16,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.newPasswordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  hintText: appLocalization.newPassword,
                  border: OutlineInputBorder(),
                ),
                validator: controller.validateNewPassword,
              ),
              const SizedBox(height: 20),
              const Text(
                'Re-enter New password',
                style: blackText16,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.reenterNewPasswordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  hintText: appLocalization.reenterNewPassword,
                  border: OutlineInputBorder(),
                ),
                validator: controller.validateReenterNewPassword
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 316,
                  height: 48,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.changePassword,
                    child: controller.isLoading.value
                        ?
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 1.5,
                      )
                    )
                        :
                    Text(
                      appLocalization.changePassword,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

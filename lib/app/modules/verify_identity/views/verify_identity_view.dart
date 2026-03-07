import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/verify_identity_controller.dart';

class VerifyIdentityView extends BaseView<VerifyIdentityController> {
  VerifyIdentityView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.verifyIdentity,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              appLocalization.verifyIdentity,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
                appLocalization.enterCodeSentToEmail,
                style: TextStyle(
                fontSize: 15,
                color: AppColors.textColorSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.maskedEmail,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textColorSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: controller.codeController,
              keyboardType: TextInputType.number,
              obscureText: false,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(AppValues.radius_6),
                fieldHeight: 52,
                fieldWidth: 48,
                activeColor: AppColors.colorSecondary,
                activeFillColor: AppColors.colorWhite,
                selectedColor: AppColors.colorSecondary,
                selectedFillColor: AppColors.colorWhite,
                inactiveColor: AppColors.designInputBorder,
                inactiveFillColor: AppColors.colorWhite,
              ),
              // activeFillColor: AppColors.colorWhite,
              enableActiveFill: true,
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textColorPrimary,
              ),
              onCompleted: (_) => controller.verify(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 28),
            Text(
              appLocalization.noCode,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.colorPrimaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.timerFormatted,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.designAccentDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                          Text(
                            appLocalization.secondsLeft,
                            style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (controller.canResend)
                    GestureDetector(
                      onTap: controller.resendCode,
                        child: Text(
                          appLocalization.resendCode,
                          style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colorSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.designAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppValues.radius_6),
                  ),
                  elevation: 0,
                ),
                child: Text(appLocalization.verify),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    appLocalization.havingTrouble,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.contactSupport,
                    child: Text(
                      appLocalization.contactSupport,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colorSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

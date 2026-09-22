import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/otp_controller.dart';

class OtpView extends BaseView<OtpController> {
  OtpView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final isSw = Get.locale?.languageCode == 'sw';
    return CustomAppBar(
      appBarTitleText: isSw ? 'Uthibitisho wa OTP' : 'OTP Verification',
      isCentered: true,
      // Explicit leading so back works even when the route stack was cleared
      // (registration / reset-password use offAllNamed).
      leading: IconButton(
        tooltip: isSw ? 'Rudi nyuma' : 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: controller.goBack,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Get.key.currentState?.canPop() ?? false;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.goBack();
      },
      // Sticky footer keeps Terms / Privacy fully visible; pin fields scroll above.
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    appLocalization.enterYourOtp,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    controller.otpSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250,
                    child: PinCodeTextField(
                      appContext: context,
                      pastedTextStyle: const TextStyle(
                        color: AppColors.textColorPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      length: 4,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      validator: (v) {
                        if (v!.length < 4) {
                          return appLocalization.requiredDigits;
                        }
                        return null;
                      },
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.underline,
                        selectedColor: AppColors.colorPrimary,
                        activeFillColor: isDark
                            ? theme.colorScheme.onSurface
                            : Colors.black,
                        inactiveColor: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : Colors.black54,
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      textStyle: TextStyle(
                        fontSize: 20,
                        height: 1.6,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : Colors.black,
                      ),
                      cursorColor: isDark
                          ? theme.colorScheme.onSurface
                          : Colors.black,
                      backgroundColor: Colors.transparent,
                      enableActiveFill: false,
                      errorAnimationController: controller.errorController,
                      controller: controller.otpController,
                      keyboardType: TextInputType.number,
                      onCompleted: (v) {
                        debugPrint(v);
                      },
                      onChanged: (value) {
                        controller.otp(value);
                      },
                      beforeTextPaste: (text) {
                        debugPrint('Allowing to paste $text');
                        return true;
                      },
                      onTap: () => {},
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final canResend = controller.canResend;
                    final muted = isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.black54;
                    return RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: appLocalization.noCode,
                            style: TextStyle(
                              color: isDark
                                  ? theme.colorScheme.onSurface
                                  : Colors.black,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 6)),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: canResend
                                ? InkWell(
                                    onTap: controller.resendOtp,
                                    child: Text(
                                      appLocalization.resendOtp,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.colorPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : Text(
                                    Get.locale?.languageCode == 'sw'
                                        ? 'Tuma tena baada ya ${controller.resendCooldownLabel}'
                                        : 'Resend in ${controller.resendCooldownLabel}',
                                    style: TextStyle(
                                      color: muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(
                  () => SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: controller.otp.value.length == 4
                          ? controller.validateOtp
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.colorPrimary,
                        disabledBackgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              controller.appLocalization.verify,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? theme.colorScheme.onSurface
                          : Colors.black,
                    ),
                    children: [
                      TextSpan(text: appLocalization.acceptStatement),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(Routes.TERMS),
                          child: Text(
                            appLocalization.terms,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              color: AppColors.colorPrimary,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(text: appLocalization.andOur),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(Routes.PRIVACY),
                          child: Text(
                            appLocalization.privacyPolicy,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              color: AppColors.colorPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

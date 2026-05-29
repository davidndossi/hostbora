import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/welcome_back_controller.dart';

class WelcomeBackView extends BaseView<WelcomeBackController> {
  WelcomeBackView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
  }

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Obx(() {
            if (controller.fromPasswordLogin.value) {
              return _buildContinueContent(context);
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.padding),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    appLocalization.welcomeBackTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: FormSurfaceColors.of(context).isDark ? Colors.white : AppColors.designSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Text(
                      controller.setupPinMode.value
                          ? controller.setupPrompt.value
                          : controller.canUseBiometrics.value
                              ? appLocalization.enterPasswordContinue
                              : appLocalization.welcomeAuthenticatingBiometrics,
                      style: TextStyle(
                        fontSize: 15,
                        color: FormSurfaceColors.of(context).isDark
                            ? Colors.white70
                            : AppColors.designPlaceholder,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(
                    () => controller.setupPinMode.value ||
                            !controller.canUseBiometrics.value
                        ? const SizedBox.shrink()
                        : _buildBiometricCircle(context),
                  ),
                  Obx(
                    () => controller.setupPinMode.value ||
                            !controller.canUseBiometrics.value
                        ? const SizedBox(height: 32)
                        : const SizedBox(height: 28),
                  ),
                  Obx(
                    () => controller.setupPinMode.value ||
                            !controller.canUseBiometrics.value
                        ? const SizedBox.shrink()
                        : Text(
                            appLocalization.orEnterSecurePin,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FormSurfaceColors.of(context).isDark
                                  ? Colors.white70
                                  : AppColors.designPlaceholder,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _buildPinDots(),
                  const SizedBox(height: 12),
                  Obx(
                    () => controller.lockoutMessage.value.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              controller.lockoutMessage.value,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                  Obx(
                    () => GestureDetector(
                      onTap: controller.forgotPin,
                      child: Text(
                        controller.setupPinMode.value
                            ? appLocalization.resetLabel
                            : appLocalization.forgotPassword,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.designAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildKeypad(context),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildContinueContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.colorPrimaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: AppColors.designAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              appLocalization.welcomeBackTitle,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: FormSurfaceColors.of(context).isDark ? Colors.white : AppColors.designSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              appLocalization.welcomeSignedInContinueMessage,
              style: TextStyle(
                fontSize: 15,
                color: FormSurfaceColors.of(context).hint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: controller.continueToApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.designAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                  ),
                ),
                child: Text(
                  appLocalization.proceed,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Obx(() {
      final fromPassword = controller.fromPasswordLogin.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            fromPassword
                ? const SizedBox(width: 48, height: 48)
                : IconButton(
                    onPressed: controller.close,
                    icon: const Icon(Icons.close),
                    color: FormSurfaceColors.of(context).isDark ? Colors.white : AppColors.designSecondaryText,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
            GestureDetector(
              onTap: controller.help,
              child: Text(
                appLocalization.help,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.designAccent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBiometricCircle(BuildContext context) {
    return Obx(() {
      final inProgress = controller.isBiometricAuthInProgress.value;
      final icon = controller.biometricIcon;
      return GestureDetector(
        onTap: inProgress ? null : controller.authenticateWithBiometrics,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.designAccent,
              width: 2,
            ),
            color: FormSurfaceColors.of(context).inputFill,
            boxShadow: [
              BoxShadow(
                color: AppColors.designAccent.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: inProgress
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: AppColors.designAccent,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  icon,
                  size: 72,
                  color: AppColors.designAccent,
                ),
        ),
      );
    });
  }

  Widget _buildPinDots() {
    return Obx(() {
      final count = controller.enteredPin.value.length;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(controller.pinLength, (index) {
          final filled = index < count;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.designAccent : Colors.transparent,
              border: Border.all(
                color: AppColors.designAccent,
                width: 1.5,
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildKeypad(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: FormSurfaceColors.of(context).isDark ? const Color(0xFF1B1B1B) : Colors.white,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: FormSurfaceColors.of(context).isDark ? const Color(0xFF333333) : AppColors.designInputBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: FormSurfaceColors.of(context).isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildKeypadRow(context, ['1', '2', '3']),
          const SizedBox(height: 16),
          _buildKeypadRow(context, ['4', '5', '6']),
          const SizedBox(height: 16),
          _buildKeypadRow(context, ['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 56, height: 56),
              _buildKeypadButton(context, '0'),
              _buildBackspaceButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(BuildContext context, List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(context, key)).toList(),
    );
  }

  Widget _buildKeypadButton(BuildContext context, String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.lockoutMessage.value.isNotEmpty
            ? null
            : () => controller.onKeyTap(digit),
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: FormSurfaceColors.of(context).isDark ? Colors.white : AppColors.designSecondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.lockoutMessage.value.isNotEmpty
            ? null
            : controller.onBackspace,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 56,
          height: 56,
          // decoration: const BoxDecoration(
          //   color: AppColors.designAccent,
          //   shape: BoxShape.circle,
          // ),
          child: Icon(
            Icons.backspace_outlined,
            color: FormSurfaceColors.of(context).isDark ? Colors.white70 : AppColors.designAccent,
            size: 20,
          ),
        ),
      ),
    );
  }
}

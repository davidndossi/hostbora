import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
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
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.designSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Authenticating via Biometrics.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.designPlaceholder,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildBiometricCircle(context),
                  const SizedBox(height: 28),
                  Text(
                    'OR ENTER SECURE PIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.designPlaceholder,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPinDots(),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: controller.forgotPin,
                    child: const Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.designAccent,
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
                color: AppColors.colorPrimaryLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: AppColors.designAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.designSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You’re signed in. Tap below to continue to the app.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.designPlaceholder,
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
                child: const Text(
                  'Continue',
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
                    color: AppColors.designSecondaryText,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
            GestureDetector(
              onTap: controller.help,
              child: const Text(
                'HELP',
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
    return GestureDetector(
      onTap: controller.authenticateWithBiometrics,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.designAccent,
            width: 2,
          ),
          color: Colors.white,
        ),
        child: const Icon(
          Icons.fingerprint_rounded,
          size: 72,
          color: AppColors.designAccent,
        ),
      ),
    );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 56, height: 56),
              _buildKeypadButton('0'),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.onKeyTap(digit),
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.designSecondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.onBackspace,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.designAccent,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

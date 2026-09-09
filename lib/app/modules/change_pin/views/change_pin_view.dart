import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/button_of_numpad.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/pin_sphere.dart';
import '../controllers/change_pin_controller.dart';

class ChangePinView extends BaseView<ChangePinController> {
  ChangePinView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.appBarIconColor;
    return CustomAppBar(
      appBarTitleText: controller.remoteConfirmMode.value
          ? _t(context, en: 'Confirm Your PIN', sw: 'Thibitisha PIN Yako')
          : controller.changePinMode.value
              ? _t(context, en: 'Change PIN', sw: 'Badilisha PIN')
              : _t(context, en: 'Setup New PIN', sw: 'Weka PIN Mpya'),
      isBackButtonEnabled: false,
      leading: IconButton(
        tooltip: _t(context, en: 'Back', sw: 'Rudi'),
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: controller.goBack,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    ever(controller.pinStatus, (callback) {
      if (controller.pinStatus.value == PINStatus.equals) {
        controller.changePin();
      } else if (controller.pinStatus.value == PINStatus.unequals) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            title: Text(
              _t(
                context,
                en: 'PIN codes do not match!',
                sw: 'Namba za PIN hazilingani!',
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => controller.reset(),
                child: Text(_t(context, en: 'OK', sw: 'SAWA')),
              ),
            ],
          ),
        );
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Image.asset(
                    'images/host_bora_logo.png',
                    width: 50,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.home_work_rounded,
                      size: 40,
                      color: isDark
                          ? theme.colorScheme.primary
                          : AppColors.colorPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 35.0,
                    vertical: 8.0,
                  ),
                  child: Obx(
                    () => Text(
                      controller.pinStatus.value == PINStatus.confirmRemote
                          ? _t(
                              context,
                              en: 'Enter your PIN to continue',
                              sw: 'Weka PIN yako ili kuendelea',
                            )
                          : controller.pinStatus.value ==
                                  PINStatus.verifyCurrent
                              ? appLocalization.enterCurrentPin
                              : controller.pinStatus.value ==
                                      PINStatus.enterFirst
                                  ? _t(
                                      context,
                                      en: 'Create PIN',
                                      sw: 'Tengeneza PIN',
                                    )
                                  : _t(
                                      context,
                                      en: 'Re-enter your PIN',
                                      sw: 'Weka PIN yako tena',
                                    ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : AppColors.textColorPrimary,
                      ),
                    ),
                  ),
                ),
                Obx(() {
                  if (!controller.remoteConfirmMode.value) {
                    return const SizedBox.shrink();
                  }
                  if (controller.isVerifyingRemotePin.value) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final error = controller.remoteConfirmError.value;
                  if (error != null && error.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Obx(
                        () => PinSphere(
                          input: index < controller.getCountsOfPIN(),
                          color: const Color(0xFFFBCA07),
                          borderColor: isDark
                              ? theme.colorScheme.onSurface
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 280,
                  height: 340,
                  child: Column(
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "1",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(1),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "2",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(2),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "3",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Flexible(
                        child: Row(
                          children: [
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "4",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(4),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "5",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(5),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "6",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Flexible(
                        child: Row(
                          children: [
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "7",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(7),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "8",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(8),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "9",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Flexible(
                        child: Row(
                          children: [
                            const Expanded(child: SizedBox()),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ButtonOfNumPad(
                                num: "0",
                                backgroundColor: AppColors.colorPrimary,
                                onPressed: () => controller.setPIN(0),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: IconButton(
                                icon: Icon(
                                  Icons.backspace,
                                  color: isDark
                                      ? theme.colorScheme.onSurface
                                      : Colors.black,
                                ),
                                onPressed: () => controller.erase(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => controller.remoteConfirmMode.value
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: TextButton(
                            onPressed: controller.forgotRemotePin,
                            child: Text(
                              _t(
                                context,
                                en: 'Forgot PIN? Set a new one',
                                sw: 'Umesahau PIN? Weka mpya',
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

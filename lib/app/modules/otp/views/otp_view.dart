import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/widget/custom_app_bar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/text_styles.dart';
import '../controllers/otp_controller.dart';

class OtpView extends BaseView<OtpController> {
  OtpView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: '');
  }

  @override
  Widget body(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children:[
            const SizedBox(height: 40),
            Text(
              appLocalization.enterYourOtp,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              )
            ),
            const SizedBox(height: 20),
            Text(
              appLocalization.otpSubtitle,
              style: blackSubTitleTextStyle,
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 250,
              child: PinCodeTextField(
                appContext: context,
                pastedTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                length: 4,
                obscureText: false,
                animationType: AnimationType.fade,
                validator: (v) {
                  if (v!.length < 4) {
                    return appLocalization.requiredDigits;
                  } else {
                    return null;
                  }
                },
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.underline,
                  selectedColor: AppColors.colorPrimary,
                  activeFillColor: Colors.black,
                  inactiveColor: Colors.black54
                ),
                animationDuration: const Duration(milliseconds: 300),
                textStyle: const TextStyle(
                  fontSize: 20,
                  height: 1.6
                ),
                backgroundColor: Colors.transparent,
                enableActiveFill: false,
                errorAnimationController: controller.errorController,
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                onCompleted: (v) {
                  print(v);
                },
                onChanged: (value) {
                  controller.otp(value);
                },
                beforeTextPaste: (text) {
                  debugPrint('Allowing to paste $text');
                  //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                  //but you can show anything you want here, like your pop up saying wrong paste format or etc
                  return true;
                },
                onTap: () => {},
              )
            ),
            // Obx(
            //   () => Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: List.generate(4, (index) {
            //       final hasDigit = index < controller.enteredPin.length;
            //       return GestureDetector(
            //         onTap: () => controller.selectDigit(index),
            //         child: Container(
            //           width: 50,
            //           height: 50,
            //           margin: const EdgeInsets.all(8),
            //           decoration: BoxDecoration(
            //             border: Border.all(
            //               color: controller.selectedIndex.value == index
            //                   ? AppColors.colorPrimary
            //                   : Colors.grey,
            //               width: 2,
            //             ),
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           child: Center(
            //             child: Text(
            //               hasDigit ? controller.enteredPin[index] : '',
            //               style: const TextStyle(fontSize: 24),
            //             ),
            //           ),
            //         ),
            //       );
            //     }),
            //   ),
            // ),
            const SizedBox(height: 20),
            RichText(text: TextSpan(
              children: [
                TextSpan(
                  text: appLocalization.noCode,
                  style: const TextStyle(
                    color: Colors.black
                  )
                ),
                const WidgetSpan(child: SizedBox(width: 6)),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: InkWell(
                    onTap: () => controller.resendOtp(),
                    child: Text(
                      appLocalization.resendOtp,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.colorPrimary,
                        fontWeight: FontWeight.bold
                      )
                    ),
                  )
                )
              ]
            )),
            const SizedBox(height: 40),
            // // Number Pad
            // GridView.count(
            //   shrinkWrap: true,
            //   crossAxisCount: 3,
            //   childAspectRatio: 1.5,
            //   padding: const EdgeInsets.symmetric(horizontal: 40),
            //   children: [
            //     // Digits 1-9
            //     for (int i = 1; i <= 9; i++)
            //       _buildDigitButton(i.toString()),
            //     // Empty space
            //     const SizedBox.shrink(),
            //     // Digit 0
            //     _buildDigitButton('0'),
            //     // Delete button
            //     IconButton(
            //       icon: const Icon(Icons.backspace),
            //       onPressed: controller.deleteDigit,
            //       color: Colors.red,
            //     ),
            //   ],
            // ),
            // // Clear All Button
            // TextButton(
            //   onPressed: controller.clearAll,
            //   child: const Text('Clear All'),
            // ),
            Expanded(
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => MaterialButton(
                        minWidth: 316,
                        onPressed: controller.otp.value.length == 4
                            ?
                        controller.validateOtp
                            :
                        null,
                        color: AppColors.colorPrimary,
                        disabledColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        child: Obx(() => controller.isLoading.value
                            ?
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.white,
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                            :
                        Text(controller.appLocalization.verify, style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black
                        ),
                        children: [
                          TextSpan(
                            text: appLocalization.acceptStatement,
                            style: const TextStyle(
                              fontSize: 10
                            )
                          ),
                          TextSpan(
                            text: appLocalization.terms,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline
                            )
                          ),
                          TextSpan(
                            text: appLocalization.andOur,
                            style: const TextStyle(
                              fontSize: 10
                            )
                          ),
                          TextSpan(
                            text: appLocalization.privacyPolicy,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline
                            )
                          ),
                        ]
                    ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitButton(String digit) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Colors.grey[200],
        onPressed: () => controller.addDigit(digit),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
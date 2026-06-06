import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/values/text_styles.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/change_password_request.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class ChangePasswordController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());
  final PreferenceManager _preferenceManager =
      Get.find<PreferenceManager>(tag: (PreferenceManager).toString());

  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController reenterNewPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final msisdn = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsernameFromPrefs();
    if (Get.arguments != null) {
      if (Get.arguments['msisdn'] != null) {
        String msisdn = Get.arguments['msisdn'];
        this.msisdn(msisdn);
        Future.microtask(() {
          showOtpDialog();
        });
      }
    }
  }

  Future<void> _loadUsernameFromPrefs() async {
    if (msisdn.value.isNotEmpty) return;
    final saved = await _preferenceManager.getString(
      PreferenceManager.keyUsername,
      defaultValue: '',
    );
    if (saved.isNotEmpty) {
      msisdn(saved);
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    reenterNewPasswordController.dispose();
    super.onClose();
  }

  String? validateCurrentPassword(String? value) {
    if (value != null && value.isEmpty) {
      return appLocalization.requiredField;
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value != null && value.isEmpty) {
      return appLocalization.requiredField;
    }
    return null;
  }

  String? validateReenterNewPassword(String? value) {
    if (value != null && value.isEmpty) {
      return appLocalization.requiredField;
    } else if (value != newPasswordController.text) {
      return appLocalization.passwordNotMatch;
    }
    return null;
  }

  void _handleQueryResponseError(Exception e) {
    if (e is ApiException && e.message.isNotEmpty) {
      showErrorMessage(e.message);
      return;
    }
    showErrorMessage(
      e.toString().replaceFirst('Exception: ', ''),
    );
  }

  void _handleChangePasswordResponseSuccess(GeneralResponse res) {
    if (res.responseCode == '0') {
      Get.offAllNamed(Routes.PASSWORD_UPDATED);
    } else {
      showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(15))),
          title: const Text('Error!'),
          content: SelectableText(res.message!),
          icon: SizedBox(
            height: 50,
            width: 50,
            child: SvgPicture.asset(
              'images/error-round.svg',
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Get.back(closeOverlays: true),
              child: const Text('OK'),
            )
          ],
        )
      );
    }
  }

  void changePassword() {
    if (formKey.currentState!.validate()) {
      ChangePasswordRequest changePasswordRequest = ChangePasswordRequest(
        username: msisdn.value,
        password: currentPasswordController.text,
        newPassword1: newPasswordController.text,
        newPassword2: reenterNewPasswordController.text
      );
      callDataService(
        _repository.changePassword(changePasswordRequest),
        onSuccess: _handleChangePasswordResponseSuccess,
        onError: _handleQueryResponseError
      );
    }
  }

  void _handleOtpResponseSuccess(GeneralResponse res) async {
    Get.back(closeOverlays: true);
    if (res.responseCode == '0') {
      showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(15))),
          title: const Text('Success!'),
          content: SelectableText(res.message!),
          icon: SizedBox(
            height: 50,
            width: 50,
            child: SvgPicture.asset(
              'images/tick-circle.svg',
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Get.back(closeOverlays: true),
              child: const Text('OK'),
            )
          ],
        )
      );
    } else {
      Get.toNamed(Routes.CREATE_HOST_ACCOUNT);
    }
  }

  void getOtp() {
    OtpRequest otpRequest = OtpRequest(msisdn: msisdn.value);
    callDataService(
      _repository.getOtpForgotPassword(otpRequest),
      onSuccess: _handleOtpResponseSuccess,
      onError: _handleQueryResponseError
    );
  }

  Future<void> showOtpDialog() async {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))
        ),
        icon: SvgPicture.asset('images/info.svg'),
        title: const Center(
          child: Text('You are about to change your password...')
        ),
        titleTextStyle: titleTextStyle,
        content: Text('A one time password will be sent to your email/phone no. '
            'which will be used as the current password.'
            '\nDo you wish to continue?',
        textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => getOtp(),
            child: Text(appLocalization.yes),
          ),
          TextButton(
            onPressed: () {
              Get.back(closeOverlays: true);
              Future.microtask(() => Get.back());
            },
            child: Text(appLocalization.cancel),
          )
        ],
      ));
  }

}

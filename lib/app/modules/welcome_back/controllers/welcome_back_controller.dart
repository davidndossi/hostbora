import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/model/login_request.dart';
import '../../../data/model/login_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class WelcomeBackController extends BaseController {
  WelcomeBackController()
      : _preferenceManager =
            Get.find<PreferenceManager>(tag: (PreferenceManager).toString());

  final Rx<LoginResponse> _loginResponse = LoginResponse().obs;
  LoginResponse get loginResponse => _loginResponse.value;

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final PreferenceManager _preferenceManager;
  final pinLength = 4;
  final maxPinAttempts = 5;
  final lockoutDuration = const Duration(minutes: 5);
  final enteredPin = ''.obs;
  final setupPinMode = false.obs;
  final changePinMode = false.obs;
  final setupStep = 1.obs;
  final setupPrompt = 'Create a 4-digit PIN'.obs;
  final lockoutMessage = ''.obs;
  final msisdn = ''.obs;
  final password = ''.obs;
  String _storedPin = '';
  final faceIdEnabledPref = false.obs;

  late String firebaseToken;

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  /// True when user just logged in with phone+password; show Continue instead of PIN.
  final fromPasswordLogin = false.obs;

  /// True when device has biometrics available (fingerprint or face).
  final canUseBiometrics = false.obs;

  /// True while fingerprint/face auth is in progress.
  final isBiometricAuthInProgress = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    fromPasswordLogin.value = args?['from_password_login'] == true;
    setupPinMode.value = args?['setup_pin'] == true;
    changePinMode.value = args?['change_pin'] == true;
    if (changePinMode.value) {
      setupPinMode.value = true;
      setupPrompt.value = _t('Enter current PIN', 'Weka PIN ya sasa');
    }
    _loadFaceIdPref();
    _checkBiometricsAvailable();
    _loadPin();
    _refreshLockState();
  }

  Future<void> _loadFaceIdPref() async {
    faceIdEnabledPref.value = await _preferenceManager.getBool(
      PreferenceManager.keyFaceIdEnabled,
      defaultValue: false,
    );
  }

  bool get biometricsOffered =>
      canUseBiometrics.value && faceIdEnabledPref.value;

  Future<void> _loadPin() async {
    _storedPin = await _preferenceManager.getString(
      PreferenceManager.keyPinCode,
      defaultValue: '',
    );
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(PreferenceManager.keyFirebaseToken);
  }

  Future<void> _checkBiometricsAvailable() async {
    try {
      final auth = LocalAuthentication();
      final available = await auth.getAvailableBiometrics();
      final supported = await auth.isDeviceSupported();
      canUseBiometrics.value = supported &&
          (available.contains(BiometricType.strong) ||
              available.contains(BiometricType.weak) ||
              available.contains(BiometricType.fingerprint) ||
              available.contains(BiometricType.face));
    } catch (_) {
      canUseBiometrics.value = false;
    }
  }

  void onKeyTap(String digit) async {
    await _refreshLockState();
    if (_isLocked()) {
      return;
    }
    if (enteredPin.value.length >= pinLength) return;
    enteredPin.value = enteredPin.value + digit;
    if (enteredPin.value.length == pinLength) {
      setupPinMode.value ? _setupPin() : _validateAndNavigate();
    }
  }

  void onBackspace() {
    if (enteredPin.value.isNotEmpty) {
      enteredPin.value = enteredPin.value.substring(0, enteredPin.value.length - 1);
    }
  }

  void _handleLoginResponseSuccess(LoginResponse res) async {
    _loginResponse(res);
    proceedToLogin(res);
  }

  void _handleLoginResponseError(Exception? e) {
    if (e is ApiException && (e.message).isNotEmpty) {
      showErrorMessage(e.message);
    }
  }

  Future<void> proceedToLogin(LoginResponse res) async {
    if (res.message == 'expired_version') {
      showErrorMessage(appLocalization.expiredVersion);
    } else if (res.message == 'auth_success') {
      final expiresIn = res.expiresIn ?? 0;
      final expiryTime = DateTime.now().add(Duration(minutes: expiresIn)).toIso8601String();
      await _preferenceManager.setString(
          PreferenceManager.keyToken, loginResponse.token!);
      await _preferenceManager.setString(
          PreferenceManager.keyExpiryTime, expiryTime);
      await _preferenceManager.setBool('isAdmin', loginResponse.user?.isAdmin ?? false);

      await _preferenceManager.setUser('user', loginResponse.user);
      if (res.token != null) {
        await Get.find<WorkspaceContextService>().offAllToPreferredWorkspace(
          arguments: {
            'initialMenu': 'home',
            'from_password_login': true,
            WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true,
          },
        );
      } else {
        showErrorMessage(appLocalization.loginFailed);
      }
    } else {
      showErrorMessage(appLocalization.loginFailed);
    }
  }

  void loginUsingSavedCredentials() {
    final loginRequest = LoginRequest(
      username: msisdn.value,
      password: password.value,
      verified: true,
      firebaseToken: firebaseToken.isNotEmpty ? firebaseToken : null,
    );
    callDataService<LoginResponse>(
      _repository.signIn(loginRequest),
      onError: _handleLoginResponseError,
      onSuccess: _handleLoginResponseSuccess,
    );
  }

  void loadCredentials() async {
    var phone = await _preferenceManager.getString(PreferenceManager.keyUsername);
    // TODO(security): replace plaintext userApp storage with a secure token/credential API.
    var a = await _preferenceManager.getString('userApp');
    msisdn(phone);
    password(a.toString());
    loginUsingSavedCredentials();
  }

  void _validateAndNavigate() {
    if (_storedPin.isEmpty) {
      showErrorMessage(_t('PIN is not set yet. Sign in first.', 'PIN bado haijawekwa. Ingia kwanza.'));
      Get.offAllNamed(Routes.AUTH);
      return;
    }
    if (enteredPin.value != _storedPin) {
      _handleFailedPinAttempt();
      enteredPin.value = '';
      return;
    }
    _resetFailedAttempts();
    enteredPin.value = '';
    loadCredentials();
  }

  Future<void> _handleFailedPinAttempt() async {
    var attempts = await _preferenceManager.getInt(
      PreferenceManager.keyPinFailedAttempts,
      defaultValue: 0,
    );
    attempts += 1;
    await _preferenceManager.setInt(PreferenceManager.keyPinFailedAttempts, attempts);

    if (attempts >= maxPinAttempts) {
      final lockUntil = DateTime.now().add(lockoutDuration).millisecondsSinceEpoch;
      await _preferenceManager.setInt(PreferenceManager.keyPinLockedUntilMs, lockUntil);
      await _preferenceManager.setInt(PreferenceManager.keyPinFailedAttempts, 0);
      _refreshLockState();
      showErrorMessage(_t(
        'Too many incorrect PIN attempts. Try again in 5 minutes.',
        'Umejaribu PIN isiyo sahihi mara nyingi. Jaribu tena baada ya dakika 5.',
      ));
      return;
    }

    final remaining = maxPinAttempts - attempts;
    showErrorMessage(_t(
      'Incorrect PIN. $remaining attempt(s) left.',
      'PIN si sahihi. Umebakiwa na jaribio $remaining.',
    ));
  }

  Future<void> _resetFailedAttempts() async {
    await _preferenceManager.setInt(PreferenceManager.keyPinFailedAttempts, 0);
    await _preferenceManager.setInt(PreferenceManager.keyPinLockedUntilMs, 0);
    lockoutMessage.value = '';
  }

  bool _isLockedSync(int lockedUntilMs) {
    if (lockedUntilMs <= 0) return false;
    return DateTime.now().millisecondsSinceEpoch < lockedUntilMs;
  }

  bool _isLocked() {
    // Optimistic check from latest message state.
    return lockoutMessage.value.isNotEmpty;
  }

  Future<void> _refreshLockState() async {
    final lockedUntilMs = await _preferenceManager.getInt(
      PreferenceManager.keyPinLockedUntilMs,
      defaultValue: 0,
    );
    if (!_isLockedSync(lockedUntilMs)) {
      lockoutMessage.value = '';
      await _preferenceManager.setInt(PreferenceManager.keyPinLockedUntilMs, 0);
      getFirebaseToken();
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = (lockedUntilMs - now).clamp(0, 1 << 31);
    final remainingMinutes = (remainingMs / 60000).ceil();
    lockoutMessage.value = _t(
      'PIN locked. Try again in $remainingMinutes minute(s).',
      'PIN imefungwa. Jaribu tena baada ya dakika $remainingMinutes.',
    );
  }

  Future<void> _setupPin() async {
  //   if (changePinMode.value && setupStep.value == 1) {
  //     if (_storedPin.isEmpty || enteredPin.value != _storedPin) {
  //       showErrorMessage(_t('Current PIN is incorrect', 'PIN ya sasa si sahihi'));
  //       enteredPin.value = '';
  //       return;
  //     }
  //     enteredPin.value = '';
  //     setupStep.value = 2;
  //     setupPrompt.value = _t('Create a new 4-digit PIN', 'Tengeneza PIN mpya ya tarakimu 4');
  //     return;
  //   }
  //
  //   if (_firstPin.isEmpty) {
  //     _firstPin = enteredPin.value;
  //     enteredPin.value = '';
  //     setupStep.value = changePinMode.value ? 3 : 2;
  //     setupPrompt.value = _t('Confirm your 4-digit PIN', 'Thibitisha PIN yako ya tarakimu 4');
  //     return;
  //   }
  //   if (enteredPin.value != _firstPin) {
  //     showErrorMessage(_t('PINs do not match. Try again.', 'PIN hazifanani. Jaribu tena.'));
  //     _firstPin = '';
  //     enteredPin.value = '';
  //     setupStep.value = 1;
  //     setupPrompt.value = _t('Create a 4-digit PIN', 'Tengeneza PIN ya tarakimu 4');
  //     return;
  //   }
  //   await _preferenceManager.setString(PreferenceManager.keyPinCode, _firstPin);
  //   await _preferenceManager.setBool(PreferenceManager.keyPinEnabled, true);
  //   await _preferenceManager.setBool(PreferenceManager.keyFirstLogin, false);
  //   await _resetFailedAttempts();
  //   showSuccessMessage(
  //     changePinMode.value
  //         ? _t('PIN changed successfully', 'PIN imebadilishwa kwa mafanikio')
  //         : _t('PIN set successfully', 'PIN imewekwa kwa mafanikio'),
  //   );
  //   Get.offAllNamed(Routes.MAIN, arguments: {'initialMenu': 'home'});
    Get.toNamed(
      Routes.CHANGE_PIN,
      arguments: {
        WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true,
      },
    );
  }

  void close() => Get.back();

  Future<void> continueToApp() async {
    await Get.find<WorkspaceContextService>().offAllToPreferredWorkspace(
      arguments: {
        'initialMenu': 'home',
        WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true,
      },
    );
  }

  void help() => Get.toNamed(Routes.SUPPORT);

  void forgotPin() {
    if (setupPinMode.value) {
      enteredPin.value = '';
      setupStep.value = 1;
      setupPrompt.value = changePinMode.value
          ? _t('Enter current PIN', 'Weka PIN ya sasa')
          : _t('Create a 4-digit PIN', 'Tengeneza PIN ya tarakimu 4');
      return;
    }
    _preferenceManager.setBool(PreferenceManager.keyPinEnabled, false);
    _preferenceManager.setString(PreferenceManager.keyPinCode, '');
    _preferenceManager.setInt(PreferenceManager.keyPinFailedAttempts, 0);
    _preferenceManager.setInt(PreferenceManager.keyPinLockedUntilMs, 0);
    Get.offAllNamed(Routes.AUTH);
  }

  Future<void> authenticateWithBiometrics() async {
    if (!biometricsOffered) {
      showErrorMessage(_t(
        'Biometric sign-in is disabled in Security settings.',
        'Kuingia kwa biometria kumezimwa katika mipangilio ya Usalama.',
      ));
      return;
    }
    if (!canUseBiometrics.value) {
      showErrorMessage(_t('Biometrics not available. Use PIN to sign in.', 'Biometria haipatikani. Tumia PIN kuingia.'));
      return;
    }
    isBiometricAuthInProgress.value = true;
    try {
      final auth = LocalAuthentication();
      final didAuthenticate = await auth.authenticate(
        localizedReason: _t(
          'Sign in with fingerprint to continue',
          'Ingia kwa alama ya kidole ili kuendelea',
        ),
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        loadCredentials();
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        showErrorMessage(_t('Biometrics not available', 'Biometria haipatikani'));
      } else if (e.code == auth_error.notEnrolled) {
        showErrorMessage(_t(
          'No fingerprint or face enrolled. Use PIN.',
          'Hakuna alama ya kidole au uso uliohifadhiwa. Tumia PIN.',
        ));
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        showErrorMessage(_t(
          'Too many attempts. Use PIN or try again later.',
          'Majaribio ni mengi sana. Tumia PIN au jaribu tena baadaye.',
        ));
      } else if (e.code != auth_error.passcodeNotSet &&
          e.code != 'UserCanceled' &&
          e.code != 'Canceled') {
        showErrorMessage(_t('Biometric sign in failed. Use PIN.', 'Kuingia kwa biometria kumeshindikana. Tumia PIN.'));
      }
    } catch (e) {
      showErrorMessage(_t('Biometric sign in failed. Use PIN.', 'Kuingia kwa biometria kumeshindikana. Tumia PIN.'));
    } finally {
      isBiometricAuthInProgress.value = false;
    }
  }
}

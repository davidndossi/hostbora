import 'package:dio/dio.dart';

import '/flavors/build_config.dart';

/// AzamPay mobile money providers (Tanzania). Use for push-to-pay provider selection.
const List<String> azamPayProviders = <String>[
  'Mpesa',
  'Airtel',
  'Tigo',
  'Halopesa',
  'Azampesa',
];

/// AzamPay mobile push-to-pay (mobile checkout).
/// Sends a push USSD to the customer's phone for payment.
/// Docs: https://developerdocs.azampay.co.tz/introduction
class AzamPayService {
  AzamPayService() : _dio = Dio(_dioOptions);

  static const _authSandbox = 'https://authenticator-sandbox.azampay.co.tz';
  static const _authProd = 'https://authenticator.azampay.co.tz';
  static const _checkoutSandbox = 'https://sandbox.azampay.co.tz';
  static const _checkoutProd = 'https://checkout.azampay.co.tz';

  final Dio _dio;
  static final BaseOptions _dioOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  );

  String get _authBase =>
      BuildConfig.instance.config.azamPaySandbox ? _authSandbox : _authProd;
  String get _checkoutBase =>
      BuildConfig.instance.config.azamPaySandbox
          ? _checkoutSandbox
          : _checkoutProd;

  /// Returns a bearer token from AzamPay authenticator.
  Future<String?> _getToken() async {
    final c = BuildConfig.instance.config;
    if (!c.isAzamPayConfigured) return null;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_authBase/app/Register/GetToken',
        data: <String, String>{
          'appName': c.azamPayAppName!,
          'clientId': c.azamPayClientId!,
          'clientSecret': c.azamPayClientSecret!,
        },
      );
      final token = res.data?['data'] ?? res.data?['token'];
      if (token is String) return token;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sends a push-to-pay request to the customer's phone (mobile checkout).
  /// [customerPhone] – recipient phone (e.g. 255712345678).
  /// [amount] – amount in TZS.
  /// [provider] – e.g. Mpesa, Airtel, Tigo, Halopesa, Azampesa.
  /// [externalId] – your reference (e.g. booking id).
  Future<AzamPayCheckoutResult> sendPushToPay({
    required String customerPhone,
    required String amount,
    required String provider,
    required String externalId,
    Map<String, dynamic>? additionalProperties,
  }) async {
    if (!BuildConfig.instance.config.isAzamPayConfigured) {
      return AzamPayCheckoutResult(
        success: false,
        message: 'AzamPay is not configured. Add credentials in env config.',
      );
    }
    final token = await _getToken();
    if (token == null) {
      return const AzamPayCheckoutResult(
        success: false,
        message: 'Could not get AzamPay token. Check credentials.',
      );
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_checkoutBase/api/v1/checkout/mobile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: <String, dynamic>{
          'merchantMobileNumber': _normalizePhone(customerPhone),
          'amount': amount,
          'currency': 'TZS',
          'provider': provider,
          'externalId': externalId,
          'additionalProperties': additionalProperties ?? <String, dynamic>{},
        },
      );
      final data = res.data;
      final success = data?['success'] == true;
      return AzamPayCheckoutResult(
        success: success,
        message: data?['message'] as String? ?? (success ? 'Request sent.' : 'Request failed.'),
        transactionId: data?['transactionId'] as String?,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return AzamPayCheckoutResult(
        success: false,
        message: msg ?? e.message ?? 'AzamPay request failed.',
      );
    } catch (e) {
      return AzamPayCheckoutResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  static String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255')) return digits;
    if (digits.length == 9 && !digits.startsWith('0')) return '255$digits';
    if (digits.length >= 9) return '255${digits.substring(digits.length - 9)}';
    return phone;
  }
}

class AzamPayCheckoutResult {
  const AzamPayCheckoutResult({
    required this.success,
    required this.message,
    this.transactionId,
  });
  final bool success;
  final String message;
  final String? transactionId;
}

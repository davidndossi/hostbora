import 'dart:convert';
import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as g;
import 'package:pointycastle/export.dart';

import '../data/local/preference/preference_manager.dart';
import '../data/local/service/session_service.dart';
import '../data/model/body_request.dart';
import '../routes/app_pages.dart';
import 'dio_request_retrier.dart';

class RequestHeaderInterceptor extends InterceptorsWrapper {
  final PreferenceManager _preferenceManager = g.Get.find(tag: (PreferenceManager)
      .toString());

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final customHeaders = await getCustomHeaders(
        requestPath: options.path,
      );
      options.headers.addAll(customHeaders);

      if (!isNullEmptyOrFalse(options.data)) {
        final encoded = _encodeRequestBody(options.data);
        final secret = generateSecret();
        const pub =
            'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2O88unHPsxwcQYB8+ax815DDNiRrSscfex0nohZ8Sb3HvmX1H6Ehiu8HPcPPDWHKVPkyZs63zKmQlh1tNqXyitj2Ql8fd8w/SKQL9UmAu6Lv4GcSdOWBqaJRPcrFmNKA8RCNpvMNGkzJMTJtoFV40p6LyXZtl1o3RMqLiVu7eRIOsGDjEK0efssQSpLt56Pd9Y30Wz7cI9j6vCcQGdbuzn4TmFpFZptG0s5i+PDn60iIKG5/5rTfhFI1zA80DgVgqW6OGNeNXY8mWB0Q1DmECsTUS0Ox/PHry94H5SvM20CAxu3RjCdXPH99uEr+8+nYpyN9sqzuR0dfscLXu34qnQIDAQAB';
        final encryptedSecret = encryptSecret(pub, secret);
        final payload = encryptPayload(encoded, secret);
        options.data = BodyRequest(
          transactionDate: encryptedSecret,
          data: payload,
        ).toJson();
      }

      handler.next(options);
    } catch (error, stack) {
      if (kDebugMode) {
        print('Request encryption failed: $error\n$stack');
      }
      handler.reject(
        DioException(
          requestOptions: options,
          message: 'Failed to encrypt request payload',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  /// Normalizes Dio body data to JSON text before AES/RSA encryption.
  String _encodeRequestBody(dynamic data) {
    if (data is String) return data;
    if (data is Map || data is List) return jsonEncode(data);
    try {
      return jsonEncode(data);
    } catch (_) {
      final dynamic encoded = (data as dynamic).toJson();
      return jsonEncode(encoded);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isRefreshCall = path.contains('/api/auth/refresh');
    final alreadyRetried = err.requestOptions.extra['authRetried'] == true;

    if ((statusCode == 401 || statusCode == 403) &&
        !isRefreshCall &&
        !alreadyRetried) {
      var recovered = false;
      if (g.Get.isRegistered<SessionService>()) {
        // Force refresh: local access expiry can still look valid when the
        // server has already rejected the JWT.
        recovered = await g.Get.find<SessionService>().ensureValidSession(
          forceRefresh: true,
        );
      }
      if (recovered) {
        try {
          final response = await DioRequestRetrier(
            requestOptions: err.requestOptions,
          ).retry();
          handler.resolve(response);
          return;
        } catch (_) {
          // Fall through to session clear / reject.
        }
      }
      await _preferenceManager.clearSession();
      // Do not interrupt registration / OTP / forgot-password with a Login redirect.
      if (!AppPages.isPublicAuthRoute()) {
        g.Get.offAllNamed(AppPages.auth);
      }
      handler.reject(err);
      return;
    }

    handler.next(err);
  }

  Future<Map<String, String>> getCustomHeaders({String? requestPath}) async {
    if (requestPath != null && requestPath.contains('/api/auth/refresh')) {
      return {'content-type': 'application/json'};
    }
    var token = await _preferenceManager.getString(PreferenceManager.keyToken);
    var customHeaders = {
      'content-type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    return customHeaders;
  }

  bool isNullEmptyOrFalse(dynamic o) {
    if (o is Map<String, dynamic> || o is List<dynamic>) {
      return o.length == 0;
    }
    return o == null || false == o || '' == o;
  }

  String generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final key = Uint8List.fromList(bytes);
    return base64Encode(key);
  }

  String encryptSecret(String base64PublicKey, String aesKeyBase64) {
    final pem = '''-----BEGIN PUBLIC KEY-----\n$base64PublicKey\n-----END PUBLIC KEY-----''';
    final RSAPublicKey publicKey = CryptoUtils.rsaPublicKeyFromPem(pem);

    final cipher = PKCS1Encoding(RSAEngine());
    cipher.init(true, PublicKeyParameter<RSAPublicKey>(publicKey)); // true = encrypt

    // final aesKeyBytes = base64Decode(aesKeyBase64); // Decode AES key from Base64 to bytes
    final aesKeyBytes = Uint8List.fromList(utf8.encode(aesKeyBase64));
    final encryptedBytes = cipher.process(aesKeyBytes);

    return base64Encode(encryptedBytes);
  }

  String encryptPayload(String payload, String secret) {
    final kb = Uint8List.fromList(base64Decode(secret));
    final nonce = Uint8List.fromList(
        List.generate(12, (_) => Random.secure().nextInt(256)));

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(kb),
          128,
          nonce,
          Uint8List(0),
        ),
      );

    final payloadBytes = Uint8List.fromList(utf8.encode(payload));
    final ciphertextWithTag = cipher.process(payloadBytes);

    final result = Uint8List(nonce.length + ciphertextWithTag.length);
    result.setRange(0, nonce.length, nonce);
    result.setRange(nonce.length, result.length, ciphertextWithTag);

    return base64Encode(result);
  }
}
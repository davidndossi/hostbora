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

      final skipEncrypt = options.path.contains('/api/auth/refresh');
      if (!skipEncrypt && !isNullEmptyOrFalse(options.data)) {
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

  /// Mark requests that must not clear the session on 401/403
  /// (best-effort sync where local data is source of truth).
  static const softAuthFailureExtra = 'softAuthFailure';

  /// Sign-in, registration, and OTP verify must not carry a session token.
  /// A leftover bearer turns "account not found" into HTTP 401, and refreshing
  /// that 401 on the same Dio client never completes the login call.
  bool _isCredentiallessAuth(String path) {
    if (path.contains('/api/auth/refresh')) return false;
    return path.contains('/api/auth/login') ||
        path.contains('/api/auth/reg') ||
        path.contains('/api/auth/verify');
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _handleAuthError(err, handler).catchError((Object _) {
      if (!handler.isCompleted) handler.next(err);
    });
  }

  Future<void> _handleAuthError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isRefreshCall = path.contains('/api/auth/refresh');
    final alreadyRetried = err.requestOptions.extra['authRetried'] == true;

    // Let the login screen show the server error. Do not refresh or navigate.
    if (_isCredentiallessAuth(path)) {
      handler.next(err);
      return;
    }

    // Refresh token was rejected. End the session instead of retrying it.
    if (statusCode == 401 && isRefreshCall) {
      await _endRejectedSession();
      handler.next(err);
      return;
    }
    final softAuth =
        err.requestOptions.extra[softAuthFailureExtra] == true;

    // Soft-fail calls (e.g. preference sync): never end the session.
    if (softAuth &&
        (statusCode == 401 || statusCode == 403) &&
        !isRefreshCall) {
      handler.next(err);
      return;
    }

    // 401 = authentication (invalid/expired JWT). Refresh, retry, or log out.
    if (statusCode == 401 && !isRefreshCall && !alreadyRetried) {
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
          // Fall through to reject without wiping a still-valid refresh token.
        }
      }
      if (!await SessionService.hasLocalSession(_preferenceManager)) {
        await _endRejectedSession();
      }
      handler.reject(err);
      return;
    }

    // 403 = authorization (e.g. staff permission denial). Do not clear the
    // session — that is what was logging staff out right after a successful
    // login when post-login sync hit owner-only routes.
    //
    // Legacy: some older backends returned 403 for bad JWTs. Try one refresh
    // + retry; if it still fails, pass the error through without logging out.
    if (statusCode == 403 && !isRefreshCall && !alreadyRetried) {
      var recovered = false;
      if (g.Get.isRegistered<SessionService>()) {
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
          // Permission still denied (or other failure) — keep the session.
        }
      }
      handler.next(err);
      return;
    }

    handler.next(err);
  }

  Future<void> _endRejectedSession() async {
    if (g.Get.isRegistered<SessionService>()) {
      await g.Get.find<SessionService>().clearFullSession();
    } else {
      await _preferenceManager.clearSession();
    }
    if (!AppPages.isPublicAuthRoute()) {
      g.Get.offAllNamed(AppPages.auth);
    }
  }

  Future<Map<String, String>> getCustomHeaders({String? requestPath}) async {
    if (requestPath != null &&
        (requestPath.contains('/api/auth/refresh') ||
            _isCredentiallessAuth(requestPath))) {
      return {'content-type': 'application/json'};
    }
    var token = await _preferenceManager.getString(PreferenceManager.keyToken);
    final customHeaders = <String, String>{
      'content-type': 'application/json',
    };
    if (token.trim().isNotEmpty) {
      customHeaders['Authorization'] = 'Bearer $token';
    }
    final actingAs = await _preferenceManager.getString(
      PreferenceManager.keyActingAsHostUserId,
      defaultValue: '',
    );
    if (actingAs.trim().isNotEmpty) {
      customHeaders['X-Acting-As-Host'] = actingAs.trim();
    }

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
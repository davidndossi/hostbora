import 'dart:convert';
import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as g;
import 'package:pointycastle/export.dart';

import '../data/local/preference/preference_manager.dart';
import '../data/model/body_request.dart';
import '../routes/app_pages.dart';

class RequestHeaderInterceptor extends InterceptorsWrapper {
  final PreferenceManager _preferenceManager = g.Get.find(tag: (PreferenceManager)
      .toString());
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    getCustomHeaders().then((customHeaders) async {
      options.headers.addAll(customHeaders);
      try {
        if (!isNullEmptyOrFalse(options.data)) {
          String request = jsonEncode(options.data);
          String secret = generateSecret();
          String pub = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2O88unHPsxwcQYB8+ax815DDNiRrSscfex0nohZ8Sb3HvmX1H6Ehiu8HPcPPDWHKVPkyZs63zKmQlh1tNqXyitj2Ql8fd8w/SKQL9UmAu6Lv4GcSdOWBqaJRPcrFmNKA8RCNpvMNGkzJMTJtoFV40p6LyXZtl1o3RMqLiVu7eRIOsGDjEK0efssQSpLt56Pd9Y30Wz7cI9j6vCcQGdbuzn4TmFpFZptG0s5i+PDn60iIKG5/5rTfhFI1zA80DgVgqW6OGNeNXY8mWB0Q1DmECsTUS0Ox/PHry94H5SvM20CAxu3RjCdXPH99uEr+8+nYpyN9sqzuR0dfscLXu34qnQIDAQAB';
          String encryptedSecret = encryptSecret(pub, secret);
          String payload = encryptPayload(request, secret);
          var bodyRequest = BodyRequest(transactionDate: encryptedSecret, data: payload);
          options.data = bodyRequest.toJson();
        }
      } catch (error) {
        if (kDebugMode) {
          print(error);
        }
      }
      super.onRequest(options, handler);
    });
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      await _preferenceManager.clearSession();
      if (g.Get.currentRoute != AppPages.auth) {
        g.Get.offAllNamed(AppPages.auth);
      }
      handler.reject(err);
    } else {
      handler.next(err);
    }
  }

  Future<Map<String, String>> getCustomHeaders() async {
    var token = await _preferenceManager.getString(PreferenceManager.keyToken);
    var customHeaders = {'content-type': 'application/json', 'Authorization': 'Bearer $token'};

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
    Uint8List iv = utf8.encode('d41cd772-cb57-412c-a864-6e40b2bd3e12'.substring(0, 16));
    Uint8List kb = base64Decode(secret);
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    final params = PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
      ParametersWithIV<KeyParameter>(KeyParameter(kb), iv),
      null,
    );

    cipher.init(true, params);

    final payloadBytes = utf8.encode(payload);
    final encryptedBytes = cipher.process(Uint8List.fromList(payloadBytes));

    return base64Encode(encryptedBytes);
  }
}
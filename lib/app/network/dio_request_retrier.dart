import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;

import '/app/data/local/preference/preference_manager.dart';
import '/app/network/dio_provider.dart';

/// Retries a failed request with a fresh Authorization header.
///
/// Uses a bare [Dio] (no [RequestHeaderInterceptor]) so an already-encrypted
/// body is not encrypted a second time.
class DioRequestRetrier {
  DioRequestRetrier({required this.requestOptions});

  final RequestOptions requestOptions;

  final PreferenceManager _preferenceManager =
      getx.Get.find(tag: (PreferenceManager).toString());

  Future<Response<T>> retry<T>() async {
    final header = await getCustomHeaders();
    final dio = Dio(
      BaseOptions(
        baseUrl: DioProvider.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return dio.request<T>(
      requestOptions.path,
      cancelToken: requestOptions.cancelToken,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      options: Options(
        headers: header,
        method: requestOptions.method,
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
        extra: {
          ...requestOptions.extra,
          'authRetried': true,
        },
      ),
    );
  }

  Future<Map<String, String>> getCustomHeaders() async {
    final accessToken =
        await _preferenceManager.getString(PreferenceManager.keyToken);
    final customHeaders = <String, String>{
      'content-type': 'application/json',
    };
    if (accessToken.trim().isNotEmpty) {
      customHeaders['Authorization'] = 'Bearer $accessToken';
    }
    return customHeaders;
  }
}

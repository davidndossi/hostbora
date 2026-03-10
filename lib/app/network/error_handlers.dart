import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '/app/network/exceptions/api_exception.dart';
import '/app/network/exceptions/app_exception.dart';
import '/app/network/exceptions/network_exception.dart';
import '/app/network/exceptions/not_found_exception.dart';
import '/app/network/exceptions/service_unavailable_exception.dart';
import '/flavors/build_config.dart';
import 'exceptions/unauthorize_exception.dart';

Exception handleError(String error) {
  final logger = BuildConfig.instance.config.logger;
  logger.e('Generic exception: $error');

  return AppException(message: error);
}

Exception handleDioError(DioException dioError) {
  switch (dioError.type) {
    case DioExceptionType.cancel:
      return AppException(message: 'Request to API server was cancelled');
    case DioExceptionType.connectionTimeout:
      return AppException(message: 'Connection timeout with API server');
    case DioExceptionType.unknown:
      return AppException(message: 'Service is temporarily unavailable, please try again later');
    case DioExceptionType.receiveTimeout:
      return TimeoutException('Receive timeout in connection with API server');
    case DioExceptionType.sendTimeout:
      return TimeoutException('Send timeout in connection with API server');
    case DioExceptionType.badCertificate:
      return AppException(message: 'Invalid certificate in request');
    case DioExceptionType.connectionError:
      return NetworkException('There is no internet connection');
    case DioExceptionType.badResponse:
      return _parseDioErrorResponse(dioError);
  }
}

Exception _parseDioErrorResponse(DioException dioError) {
  final logger = BuildConfig.instance.config.logger;

  int statusCode = dioError.response?.statusCode ?? -1;
  String? status;
  String? serverMessage;

  try {
    final data = dioError.response?.data;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message']?.toString();
    }
    if (serverMessage == null || serverMessage.isEmpty) {
      if (statusCode == -1 || statusCode == HttpStatus.ok) {
        statusCode = int.parse(dioError.response?.data['statusCode']?.toString() ?? '$statusCode');
      } else {
        serverMessage = dioError.response?.statusMessage;
      }
    }
    if (serverMessage == null || serverMessage.isEmpty) {
      serverMessage = 'Something went wrong. Please try again later.';
    }
  } catch (e, s) {
    logger.i('$e');
    logger.i(s.toString());
    serverMessage = serverMessage ?? 'Something went wrong. Please try again later.';
  }

  switch (statusCode) {
    //case to define http
    case HttpStatus.serviceUnavailable:
      return ServiceUnavailableException('Service Temporarily Unavailable');
    case HttpStatus.notFound:
      return NotFoundException(serverMessage ?? '', status ?? '');
    case HttpStatus.unauthorized:
      return UnauthorizedException(serverMessage?.isNotEmpty == true ? serverMessage! : 'Invalid username or password');
    case HttpStatus.forbidden:
      return UnauthorizedException('Access token expired, please login...');
    case HttpStatus.internalServerError:
      return ServiceUnavailableException('Service not available... Please try again later!');
    default:
      return ApiException(
          httpCode: statusCode,
          status: status ?? '',
          message: serverMessage ?? '');
  }
}

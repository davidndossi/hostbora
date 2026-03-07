import 'dart:io';

import 'package:flutter/services.dart';

class AppPlugin {
  static const MethodChannel _channel = MethodChannel('app_plugin');

  // get multi imei numbers (dual-sim, tri-sim) @return List<String>
  static Future<List<String>> getImeiMulti(
      {bool shouldShowRequestPermissionRationale = false}) async {
    final List<String> imeis = await _channel.invokeListMethod(
        'getImeiMulti', {'ssrpr': shouldShowRequestPermissionRationale}) as List<String>;

    return imeis;
  }

  static Future<String> setThumbOptions(String selectedThumb, String name) async {
    return await _channel.invokeMethod('setThumbOption', {
      'thumb': selectedThumb,
      'name': name
    });
  }

  static Future<String> encryptRequest(String request, String date) async {
    return await _channel.invokeMethod('encryptRequest', {
      'request': request,
      'date': date
    });
  }

  static Future<String> decryptResponse(String response, String date) async {
    return await _channel.invokeMethod('decryptResponse', {
      'response': response,
      'date': date
    });
  }

  static Future<bool> hookDetection() async {
    return await _channel.invokeMethod('hookDetection');
  }

  static Future<String?> decodeFrom(String filePath) {
    return _channel.invokeMethod('decoder', {'file': filePath});
  }

  static Future<String?> getMobileNo() {
    return _channel.invokeMethod('getMobileNo');
  }

  static Future<String?> openWebView(String url) async {
    try {
      return await _channel.invokeMethod('openWebView', {"url": url});
    } on PlatformException catch (_) {
      return null;
    }
  }

  static Future<bool> openFileManager() async {
    final data = <String, dynamic>{};
    if (Platform.isAndroid) {
      data['folderType'] = 'download';
    } else if (Platform.isIOS) {
      data['subFolderPath'] = 'Downloads';
    }
    return await _channel.invokeMethod<bool?>('openFileManager', data) ?? false;
  }
}

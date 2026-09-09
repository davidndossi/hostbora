import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/community.dart';
import '../../model/login_response.dart';
import '/app/data/local/preference/preference_manager.dart';

class PreferenceManagerImpl implements PreferenceManager {
  final storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );

  @override
  Future<String> getString(String key, {String defaultValue = ''}) {
    return storage.read(key: key).then((val) => val ?? defaultValue);
  }

  @override
  Future<bool> setString(String key, String value) {
    return storage.write(key: key, value: value).then((_) => true);
  }

  @override
  Future<int> getInt(String key, {int defaultValue = 0}) {
    return storage.read(key: key).then((val) => int.tryParse(val.toString()) ?? defaultValue);
  }

  @override
  Future<bool> setInt(String key, int value) {
    return storage.write(key: key, value: value.toString()).then((_) => true);
  }

  @override
  Future<double> getDouble(String key, {double defaultValue = 0.0}) {
    return storage.read(key: key).then((val) => double.tryParse(val.toString()) ?? defaultValue);
  }

  @override
  Future<bool> setDouble(String key, double value) {
    return storage.write(key: key, value: value.toString()).then((_) => true);
  }

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) {
    return storage.read(key: key).then((val) => bool.tryParse(val.toString()) ?? defaultValue);
  }

  @override
  Future<bool> setBool(String key, bool value) {
    return storage.write(key: key, value: value.toString()).then((_) => true);
  }

  @override
  Future<List<String>> getStringList(String key,
      {List<String> defaultValue = const []}) async {
    final value = await storage.read(key: key);
    if (value == null) return defaultValue;

    try {
      final list = jsonDecode(value) as List;
      return list.map((item) => item.toString()).toList();
    } catch (e) {
      print('Error parsing list: $e');
      return defaultValue;
    }
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    return storage.write(key: key, value: jsonEncode(value)).then((_) => true);
  }

  @override
  Future<bool> setUser(String key, User? value) {
    return storage.write(key: key, value: jsonEncode(value)).then((_) => true);
  }

  @override
  Future<User> getUser() async {
    final data = await storage.read(key: 'user');
    return User.fromJson(jsonDecode(data as String));
  }

  @override
  Future<bool> remove(String key) {
    return storage.delete(key: key).then((_) => true);
  }

  @override
  Future<bool> clear() {
    return storage.deleteAll().then((_) => true);
  }

  @override
  void saveUserCommunities(List<Community> items) {
    final jsonList = items.map((e) => e.toJson()).toList();
    storage.write(key: 'communities', value: jsonEncode(jsonList));
  }

  @override
  Future<List<Community>> getUserCommunities() async {
    final data = await storage.read(key: 'communities');
    final List<dynamic> decoded = jsonDecode(data as String);
    return decoded.map((e) => Community.fromJson(e)).toList();
  }

  @override
  Future<void> clearSession() async {
    await storage.delete(key: PreferenceManager.keyToken);
    await storage.delete(key: PreferenceManager.keyExpiryTime);
    await storage.delete(key: PreferenceManager.keyRefreshToken);
    await storage.delete(key: PreferenceManager.keyRefreshExpiryTime);
    await storage.delete(key: PreferenceManager.keyActingAsHostUserId);
    await storage.delete(key: PreferenceManager.keyManagedHostName);
    await storage.delete(key: PreferenceManager.keyIsPortfolioManager);
  }
}

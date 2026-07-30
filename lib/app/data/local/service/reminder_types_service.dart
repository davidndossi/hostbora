import 'dart:async';

import 'package:get/get.dart';

import '../preference/preference_manager.dart';

/// User-defined reminder categories. Defaults: Pay rent, Service charge.
class ReminderTypesService extends GetxService {
  ReminderTypesService({
    required PreferenceManager preferenceManager,
  }) : _preferenceManager = preferenceManager;

  static const _customTypesKey = 'rent_reminder_custom_types';

  static const defaultPayRentId = 'pay_rent';
  static const defaultServiceChargeId = 'service_charge';

  final PreferenceManager _preferenceManager;
  final customTypes = <String>[].obs;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void onInit() {
    super.onInit();
    unawaited(loadCustomTypes());
  }

  Future<void> loadCustomTypes() async {
    final raw = await _preferenceManager.getStringList(_customTypesKey);
    customTypes.assignAll(raw.where((e) => e.trim().isNotEmpty));
  }

  List<ReminderTypeOption> get allTypes {
    final defaults = [
      ReminderTypeOption(
        id: defaultPayRentId,
        label: _isSw ? 'Lipa Kodi' : 'Pay rent',
        isDefault: true,
      ),
      ReminderTypeOption(
        id: defaultServiceChargeId,
        label: _isSw ? 'Ada ya Huduma' : 'Service charge',
        isDefault: true,
      ),
    ];
    final custom = customTypes
        .map(
          (name) => ReminderTypeOption(
            id: _slug(name),
            label: name,
            isDefault: false,
          ),
        )
        .toList();
    return [...defaults, ...custom];
  }

  Future<void> addCustomType(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    final existing = allTypes.map((e) => e.label.toLowerCase()).toSet();
    if (existing.contains(cleaned.toLowerCase())) return;
    final updated = [...customTypes, cleaned];
    await _preferenceManager.setStringList(_customTypesKey, updated);
    customTypes.assignAll(updated);
  }

  String labelForId(String id) {
    for (final t in allTypes) {
      if (t.id == id) return t.label;
    }
    return id;
  }

  String _slug(String raw) => raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class ReminderTypeOption {
  const ReminderTypeOption({
    required this.id,
    required this.label,
    required this.isDefault,
  });

  final String id;
  final String label;
  final bool isDefault;
}

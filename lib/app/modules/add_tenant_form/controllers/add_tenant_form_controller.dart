import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../add_listing/models/apartment_unit_draft.dart';

class AddTenantFormController extends BaseController {
  AddTenantFormController()
      : _tenantLocal = Get.find<TenantLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        );

  final TenantLocalDataSource _tenantLocal;
  final PropertyLocalDataSource _propertyLocal;
  final PreferenceManager _preferenceManager;

  final propertyContextLabel = ''.obs;
  final propertyRef = ''.obs;
  final availableUnitDrafts = <ApartmentUnitDraft>[].obs;
  /// Selected [ApartmentUnitDraft.selectionKey], or null until user picks.
  final selectedUnitKey = RxnString();
  final formKey = GlobalKey<FormState>();

  final tenantNameController = TextEditingController();
  final rentAmountController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final gender = 'Female'.obs;
  final rentFrequency = 'Per Day'.obs;
  final isWhatsapp = false.obs;

  final leaseStart = Rx<DateTime?>(null);
  final leaseEnd = Rx<DateTime?>(null);

  static const genderOptions = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];

  List<String> get unitSelectionKeys =>
      availableUnitDrafts.map((u) => u.selectionKey).toList();

  String unitDisplayLabel(String selectionKey) {
    for (final u in availableUnitDrafts) {
      if (u.selectionKey == selectionKey) {
        final rent = u.unitRent.trim();
        if (rent.isEmpty) return u.unitName;
        return '${u.unitName} (Tshs $rent)';
      }
    }
    return selectionKey;
  }

  ApartmentUnitDraft? _draftForKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final u in availableUnitDrafts) {
      if (u.selectionKey == key) return u;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    final ref = Get.parameters['propertyRef']?.trim();
    if (ref != null && ref.isNotEmpty) {
      propertyRef.value = ref;
    }
    final fromRoute = Get.parameters['property']?.trim();
    if (fromRoute != null && fromRoute.isNotEmpty) {
      propertyContextLabel.value = fromRoute;
    }
    final paramUnitId = Get.parameters['unitId']?.trim() ?? '';
    final paramUnitName = Get.parameters['unitName']?.trim() ?? '';
    _loadPropertyUnits(
      preferredUnitId: paramUnitId,
      preferredUnitName: paramUnitName,
    );
  }

  Future<void> _loadPropertyUnits({
    String preferredUnitId = '',
    String preferredUnitName = '',
  }) async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final properties = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: 'bnb',
    );

    PropertyRecord? selected;
    if (propertyRef.value.isNotEmpty) {
      for (final p in properties) {
        if (p.propertyRef == propertyRef.value ||
            'legacy_${p.id}' == propertyRef.value ||
            'local_${p.id}' == propertyRef.value) {
          selected = p;
          break;
        }
      }
    }
    if (selected == null && propertyContextLabel.value.isNotEmpty) {
      final wanted = propertyContextLabel.value.trim();
      for (final p in properties) {
        final composed = p.propertyName.trim().isNotEmpty
            ? '${p.propertyLocation.trim()} · ${p.propertyName.trim()}'
            : p.propertyLocation.trim();
        final matches = composed == wanted ||
            p.propertyLocation.trim() == wanted ||
            p.propertyName.trim() == wanted;
        if (matches) {
          selected = p;
          break;
        }
      }
    }
    if (selected == null) {
      availableUnitDrafts.clear();
      selectedUnitKey.value = null;
      return;
    }

    propertyRef.value =
        selected.propertyRef.isNotEmpty ? selected.propertyRef : 'legacy_${selected.id}';
    final composed = selected.propertyName.trim().isNotEmpty
        ? '${selected.propertyName.trim()} · ${selected.propertyLocation.trim()}'
        : selected.propertyLocation.trim();
    if (composed.isNotEmpty) {
      propertyContextLabel.value = composed;
    }

    final drafts = _parseUnitDrafts(selected.unitsJson);
    availableUnitDrafts.assignAll(drafts);

    if (drafts.isEmpty) {
      selectedUnitKey.value = null;
      return;
    }

    if (preferredUnitId.isNotEmpty) {
      for (final u in drafts) {
        if (u.unitId == preferredUnitId) {
          selectedUnitKey.value = u.selectionKey;
          _prefillRentFromUnit(u);
          return;
        }
      }
    }
    if (preferredUnitName.isNotEmpty) {
      for (final u in drafts) {
        if (u.unitName.trim() == preferredUnitName) {
          selectedUnitKey.value = u.selectionKey;
          _prefillRentFromUnit(u);
          return;
        }
      }
    }
    selectedUnitKey.value = drafts.length == 1 ? drafts.first.selectionKey : null;
    if (drafts.length == 1) {
      _prefillRentFromUnit(drafts.first);
    }
  }

  void _prefillRentFromUnit(ApartmentUnitDraft u) {
    final raw = u.unitRent.trim().replaceAll(',', '');
    if (raw.isEmpty) return;
    final n = double.tryParse(raw);
    if (n != null && n > 0) {
      rentAmountController.text = raw;
    }
  }

  List<ApartmentUnitDraft> _parseUnitDrafts(String unitsJson) {
    if (unitsJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(unitsJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(m)))
          .where((u) => u.unitName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void setSelectedUnitKey(String? key) {
    if (key == null || key.isEmpty) {
      selectedUnitKey.value = null;
      return;
    }
    selectedUnitKey.value = key;
    final d = _draftForKey(key);
    if (d != null) {
      _prefillRentFromUnit(d);
    }
  }

  void setGender(String? value) {
    if (value != null && value.isNotEmpty) {
      gender.value = value;
    }
  }

  void setRentFrequency(String? value) {
    if (value != null && value.isNotEmpty) {
      rentFrequency.value = value;
    }
  }

  void setWhatsapp(bool? value) {
    if (value != null) {
      isWhatsapp.value = value;
    }
  }

  void setLeaseDateRange(DateTimeRange range) {
    leaseStart.value = DateTime(range.start.year, range.start.month, range.start.day);
    leaseEnd.value = DateTime(range.end.year, range.end.month, range.end.day);
  }

  Future<void> saveTenant() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (leaseStart.value == null || leaseEnd.value == null) {
      showErrorMessage('Lease period is required');
      return;
    }
    if (availableUnitDrafts.isNotEmpty) {
      if (selectedUnitKey.value == null || selectedUnitKey.value!.isEmpty) {
        showErrorMessage('Please select a unit');
        return;
      }
    }

    final amountRaw = rentAmountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountRaw);
    if (amount == null || amount <= 0) {
      showErrorMessage('Enter a valid rent amount');
      return;
    }

    final draft = _draftForKey(selectedUnitKey.value);
    final unitLabel = draft?.unitName.trim() ?? '';
    final apartmentUnitId = draft?.unitId.trim() ?? '';

    await _tenantLocal.insert(
      propertyLabel: propertyContextLabel.value.trim(),
      propertyRef: propertyRef.value.trim(),
      apartmentUnitId: apartmentUnitId,
      unitLabel: unitLabel,
      tenantName: tenantNameController.text.trim(),
      gender: gender.value,
      rentAmountValue: amount,
      rentFrequency: rentFrequency.value,
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      isWhatsapp: isWhatsapp.value,
      leaseStartIso: DateFormat('yyyy-MM-dd').format(leaseStart.value!),
      leaseEndIso: DateFormat('yyyy-MM-dd').format(leaseEnd.value!),
    );

    showSuccessMessage('Tenant saved offline');
    Get.back(result: true);
  }

  String? validateTenantName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Tenant name is required';
    if (v.length < 2) return 'Enter a valid name';
    return null;
  }

  String? validateRentAmount(String? value) {
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Rent amount is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  String? validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required';
    if (v.length < 7) return 'Enter a valid phone number';
    return null;
  }

  String? validateEmailOptional(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final ok = GetUtils.isEmail(v);
    return ok ? null : 'Enter a valid email';
  }

  @override
  void onClose() {
    tenantNameController.dispose();
    rentAmountController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }
}

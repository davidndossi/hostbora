import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../routes/app_pages.dart';
import '../../add_new_listing/models/apartment_unit_draft.dart';
import '../../listing_details/controllers/rent_listing_details_controller.dart';
import '../../expected_payment_schedule/controllers/rent_expected_payment_schedule_controller.dart';
import '../../tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';

class RentAddTenantFormController extends BaseController {
  RentAddTenantFormController()
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
  final rentFrequency = 'Per Month'.obs;
  final isWhatsapp = false.obs;
  final saving = false.obs;

  final leaseStart = Rx<DateTime?>(null);
  final leaseEnd = Rx<DateTime?>(null);

  PropertyRecord? _linkedProperty;

  static const genderOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];
  static const rentFrequencyOptions = ['Per Month', 'Per Year'];

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
      workspaceType: 'rent',
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
        final matches =
            composed == wanted ||
            p.propertyLocation.trim() == wanted ||
            p.propertyName.trim() == wanted;
        if (matches) {
          selected = p;
          break;
        }
      }
    }
    if (selected == null) {
      _linkedProperty = null;
      availableUnitDrafts.clear();
      selectedUnitKey.value = null;
      return;
    }

    _linkedProperty = selected;
    propertyRef.value = selected.propertyRef.isNotEmpty
        ? selected.propertyRef
        : 'legacy_${selected.id}';
    final composed = selected.propertyName.trim().isNotEmpty
        ? '${selected.propertyLocation.trim()} · ${selected.propertyName.trim()}'
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
    selectedUnitKey.value = drafts.length == 1
        ? drafts.first.selectionKey
        : null;
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
    leaseStart.value = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    leaseEnd.value = DateTime(range.end.year, range.end.month, range.end.day);
  }

  Future<void> saveTenant() async {
    if (saving.value) return;
    if (!(formKey.currentState?.validate() ?? false)) {
      hapticValidationError();
      return;
    }

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

    saving.value = true;
    try {
      final draft = _draftForKey(selectedUnitKey.value);
      final unitLabel = draft?.unitName.trim() ?? '';
      final apartmentUnitId = draft?.unitId.trim() ?? '';
      await _markUnitOccupied(
        unitId: apartmentUnitId,
        unitName: unitLabel,
        tenantName: tenantNameController.text.trim(),
      );

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
        contractFilePath: '',
        contractFileName: '',
      );

      await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
      await RentListingDetailsController.refreshIfRegistered();
      await RentExpectedPaymentScheduleController.refreshIfRegistered();

      hapticPrimaryConfirm();
      showSuccessMessage('Tenant saved offline');

      final addIncome = await _promptAddIncomeAfterTenant();
      if (addIncome == true) {
        final nav = _incomeNavigationArgs();
        Get.back(result: true);
        await Get.toNamed(
          Routes.RENT_ADD_INCOME_FORM,
          parameters: {
            if (nav['property'] != null) 'property': nav['property'] as String,
            if (nav['propertyRef'] != null)
              'propertyRef': nav['propertyRef'] as String,
          },
          arguments: nav,
        );
        return;
      }

      Get.back(result: true);
    } finally {
      saving.value = false;
    }
  }

  Future<bool?> _promptAddIncomeAfterTenant() {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(appLocalization.rentAddTenantIncomePromptTitle),
        content: Text(appLocalization.rentAddTenantIncomePromptBody),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(appLocalization.rentAddTenantIncomePromptLater),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(appLocalization.rentAddTenantIncomePromptAdd),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Map<String, dynamic> _incomeNavigationArgs() {
    final p = _linkedProperty;
    final propertyOption = p == null
        ? propertyContextLabel.value.trim()
        : (p.propertyName.trim().isNotEmpty
              ? p.propertyName.trim()
              : p.propertyLocation.trim());
    return {
      'property': propertyOption,
      'propertyRef': propertyRef.value.trim(),
      'prefillIncome': {
        'tenantName': tenantNameController.text.trim(),
        'amount': rentAmountController.text.trim().replaceAll(',', ''),
        'unitSelectionKey': selectedUnitKey.value,
        'categoryIndex': 0,
      },
    };
  }

  Future<void> _markUnitOccupied({
    required String unitId,
    required String unitName,
    required String tenantName,
  }) async {
    final ref = propertyRef.value.trim();
    if (ref.isEmpty) return;
    final property =
        await _propertyLocal.findByHubId(ref) ??
        await _propertyLocal.getByPropertyRef(ref);
    if (property == null) return;
    if (property.unitsJson.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(property.unitsJson);
      if (decoded is! List) return;
      var changed = false;
      final updated = decoded.map((entry) {
        if (entry is! Map) return entry;
        final unit = Map<String, dynamic>.from(entry);
        final existingId = (unit['unitId'] ?? unit['id'] ?? '')
            .toString()
            .trim();
        final existingName = (unit['unitName'] ?? unit['name'] ?? '')
            .toString()
            .trim();
        final idMatches =
            unitId.isNotEmpty && existingId.isNotEmpty && existingId == unitId;
        final nameMatches =
            unitName.isNotEmpty &&
            existingName.isNotEmpty &&
            existingName.toLowerCase() == unitName.toLowerCase();
        if (!idMatches && !nameMatches) return unit;
        changed = true;
        unit['status'] = 'occupied';
        unit['occupied'] = true;
        if (tenantName.isNotEmpty) {
          unit['tenantName'] = tenantName;
        }
        return unit;
      }).toList();
      if (!changed) return;
      await _propertyLocal.update(
        PropertyRecord(
          id: property.id,
          propertyLocation: property.propertyLocation,
          propertyName: property.apartmentSuite,
          propertyType: property.propertyType,
          propertyRef: property.propertyRef,
          tenants: property.tenants,
          units: property.units,
          ownerUserId: property.ownerUserId,
          workspaceType: property.workspaceType,
          createdAtMs: property.createdAtMs,
          rentAmount: property.rentAmount,
          rentFrequency: property.rentFrequency,
          minRentalDuration: property.minRentalDuration,
          unitsJson: jsonEncode(updated),
          floorCount: property.floorCount,
        ),
      );
    } catch (_) {}
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

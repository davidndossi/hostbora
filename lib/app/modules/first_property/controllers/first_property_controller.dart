import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../routes/app_pages.dart';
import '../../add_listing/bindings/add_listing_binding.dart';
import '../../add_listing/controllers/add_listing_controller.dart';
import '../../add_listing/models/apartment_unit_draft.dart';

/// Post sign-up step that invites the host to add their first property.
///
/// Deliberately a condensed form rather than the full seven-step Add Property:
/// the aim is that the host finishes with something of their own in the app,
/// which is what makes the account feel worth coming back to. A Base unit
/// at rent 0 is written with the property so it is already tenantable;
/// photos and the real rent stay a later edit from My Properties.
///
/// Two fields, down from six. Property type, listing mode, rent frequency and
/// minimum stay follow Add Property defaults (`both`, Per Day, BnB minimum)
/// so the first listing is not Rent-only. All four stay editable afterwards.
class FirstPropertyController extends BaseController {
  final isSaving = false.obs;

  final hostFirstName = ''.obs;

  /// Wording matches the Add/Edit Property screens so these round-trip when
  /// the host later edits the property.
  static const _defaultPropertyType = 'Apartment';
  /// Same default as Add Property so the first listing is BnB + Rent, not Rent-only.
  static const _defaultListingMode = 'both';
  static const _defaultRentFrequency = 'Per Day';
  static const _defaultMinDuration = ApartmentUnitDraft.minDurationBnb;

  final nameController = TextEditingController();
  final locationController = TextEditingController();

  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _t(String en, String sw) => _isSw ? sw : en;

  @override
  void onInit() {
    super.onInit();
    _loadHostName();
  }

  Future<void> _loadHostName() async {
    var name = await _preferenceManager.getString(
      PreferenceManager.keySignupFirstName,
      defaultValue: '',
    );
    if (name.trim().isEmpty) {
      final full = await _preferenceManager.getString(
        PreferenceManager.keyFullName,
        defaultValue: '',
      );
      final parts =
          full.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
      name = parts.isEmpty ? '' : parts.first;
    }
    hostFirstName.value = name.trim();
    _seedPropertyName();
  }

  /// Pre-fills "{name}'s Apartment" so the host is editing something that is
  /// already theirs rather than filling a blank field.
  void _seedPropertyName() {
    if (nameController.text.trim().isNotEmpty) return;
    final name = hostFirstName.value;
    if (name.isEmpty) return;
    nameController.text = _isSw
        ? 'Apartment ya $name'
        : "$name's Apartment";
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Leaves the step without adding anything. The flag is cleared either way so
  /// this never reappears on the next sign-in.
  Future<void> skip() async {
    await _clearPendingFlag();
    await _goHome();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  String? validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return _t('Give the property a name', 'Ipe mali jina');
    }
    return null;
  }

  String? validateLocation(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return _t('Where is it?', 'Iko wapi?');
    }
    return null;
  }

  /// Writes the property through the same path as Add Property, so it lands in
  /// the local database and the offline sync queue identically.
  Future<void> complete() async {
    if (isSaving.value) return;
    final nameError = validateName(nameController.text);
    final locationError = validateLocation(locationController.text);
    if (nameError != null || locationError != null) {
      showErrorMessage(nameError ?? locationError!);
      return;
    }

    isSaving.value = true;
    final listing = _resolveAddListingController();
    try {
      listing.propertyNameController.text = nameController.text.trim();
      listing.propertyLocationController.text = locationController.text.trim();
      listing.selectedPropertyType.value = _defaultPropertyType;
      listing.propertyType.value = _defaultPropertyType;
      listing.listingMode.value = _defaultListingMode;
      listing.rentFrequency.value = _defaultRentFrequency;
      listing.minRentalDuration.value = _defaultMinDuration;
      // One unit so the property is already tenantable. Rent stays 0 —
      // the host sets the real figure later — and the description names
      // the unit so it is not an anonymous row in the unit list.
      listing.apartmentUnits.assignAll([
        ApartmentUnitDraft(
          unitName: 'Unit 1',
          unitDescription: 'First unit',
          unitRent: '0',
          unitRentFrequency: _defaultRentFrequency,
          operationMode: 'bnb',
          unitRentCurrency: listing.selectedCurrency.value,
        ),
      ]);

      final saved = await listing.saveProperty(
        skipRentAmountRequirement: true,
        skipUnitRequirement: false,
        popOnSuccess: false,
        analyticsSource: 'first_property',
      );
      if (!saved) return;

      await _clearPendingFlag();
      await _goHome();
      // Get.snackbar rather than showSuccessMessage: the latter renders inside
      // this view, which _goHome has just torn down.
      Get.snackbar(
        _t('Added', 'Imeongezwa'),
        _t(
          '${nameController.text.trim()} is now yours to manage. Add units and rent from My Properties.',
          '${nameController.text.trim()} sasa ni yako kusimamia. Ongeza uniti na kodi kutoka Mali Zangu.',
        ),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isSaving.value = false;
      Get.delete<AddListingController>(force: true);
    }
  }

  /// Built on demand and torn down after the save so the first-property step
  /// does not keep the full Add Property controller alive behind home.
  AddListingController _resolveAddListingController() {
    if (Get.isRegistered<AddListingController>()) {
      Get.delete<AddListingController>(force: true);
    }
    AddListingBinding().dependencies();
    final listing = Get.find<AddListingController>();
    // Assigned synchronously after onInit and before onReady's post-frame
    // callback, so the draft prompt never runs for this flow.
    listing.suppressDraftResume = true;
    return listing;
  }

  Future<void> _clearPendingFlag() => _preferenceManager.setBool(
        PreferenceManager.keyPendingFirstProperty,
        false,
      );

  Future<void> _goHome() async {
    await Get.offAllNamed(Routes.MAIN);
  }

  @override
  void onClose() {
    nameController.dispose();
    locationController.dispose();
    super.onClose();
  }
}

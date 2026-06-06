import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/base/feedback_extensions.dart';
import '../../../core/utils/property_listing_image_assigner.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_listing_units_sync.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/draft_listing_store.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/model/add_listing_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/service/nominatim_service.dart';
import '../../../routes/app_pages.dart';
import '../../../core/values/property_unit_floor.dart';
import '../models/apartment_unit_draft.dart';

class AddListingController extends BaseController {
  AddListingController()
    : _nominatim = Get.find<NominatimService>(),
      _local = Get.find<PropertyLocalDataSource>(),
      _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
      _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      ),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>(),
      _draftStore = DraftListingStore();

  final NominatimService _nominatim;
  final PropertyLocalDataSource _local;
  final PropertyUnitLocalDataSource _unitLocal;
  final AppRepository _repository;
  final PreferenceManager _preferenceManager;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final DraftListingStore _draftStore;

  final formKey = GlobalKey<FormState>();
  final propertyNameController = TextEditingController();
  final streetAddressController = TextEditingController();
  final propertyLocationController = TextEditingController();
  final apartmentSuiteController = TextEditingController();
  final rentAmountController = TextEditingController();

  final propertyType = 'Apartment'.obs;
  final rentFrequency = 'Per Day'.obs;
  final minRentalDuration = '2 Days'.obs;
  final listingMode = 'bnb'.obs;
  final propertyTypeOptions = const [
    'Apartment',
    'House',
    'Office space',
    'Room',
    'Storage',
    'Other',
  ];
  final listingModeOptions = const ['bnb', 'rent', 'both'];
  final minRentalDurationOptions = const [
    '1 Day',
    '2 Days',
    '1 Week',
    '1 Month',
  ];

  static const int minFloorCount = 1;
  static const int maxFloorCount = 200;
  final floorCount = 1.obs;

  final apartmentUnits = <ApartmentUnitDraft>[].obs;
  final draftUnitNameController = TextEditingController();
  final draftUnitRentController = TextEditingController();
  final draftUnitDescriptionController = TextEditingController();
  final draftUnitRentFrequency = 'Per Day'.obs;
  final draftUnitFloor = PropertyUnitFloor.defaultIndex.obs;
  final draftUnitMode = 'bnb'.obs;

  static const int totalSteps = 7;
  final currentStep = 1.obs;

  bool get fromFirstLogin => Get.arguments?['from_first_login'] == true;

  bool get isApartmentProperty {
    final t = _effectivePropertyType.trim();
    return t == 'Apartment';
  }

  /// Dropdown selection when set; otherwise legacy [propertyType] (kept in sync in [selectPropertyType]).
  String get _effectivePropertyType =>
      (selectedPropertyType.value?.trim().isNotEmpty == true
      ? selectedPropertyType.value!.trim()
      : propertyType.value.trim());

  // bool get hideListingRentAmount => isApartmentProperty && apartmentUnits.isNotEmpty;
  bool get hideListingRentAmount => isApartmentProperty;

  /// Edit mode: when opening from My Properties Manage.
  final isEditMode = false.obs;
  String? get listingId => _listingId;
  String? _listingId;
  final loadingListing = true.obs;
  final isEditing = false.obs;
  final awaitingEditLoad = false.obs;

  PropertyRecord? _editingOriginal;

  /// When true, remote/API merge must not overwrite values taken from local [PropertyRecord].
  bool _rentFreqLockedFromLocal = false;
  bool _minDurLockedFromLocal = false;
  bool _rentAmountLockedFromLocal = false;
  bool _propertyTypeLockedFromLocal = false;
  bool _unitsLockedFromLocal = false;

  static const _rentFrequencyChoices = ['Per Day'];

  final selectedPropertyType = Rx<String?>(null);

  final selectedCurrency = CurrencyService.defaultBaseCurrency.obs;

  /// Selected location from OSM autocomplete (null until user picks an address).
  final selectedLat = Rxn<double>();
  final selectedLon = Rxn<double>();
  final addressSuggestions = <NominatimPlace>[].obs;
  final addressSuggestionsLoading = false.obs;
  Timer? _searchDebounce;

  static const _searchDebounceDuration = Duration(milliseconds: 400);

  String? validateRentAmount(String? value) {
    if (hideListingRentAmount) return null;
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Rent amount is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  void updateMinRentalDuration(String? value) {
    if (value != null && value.isNotEmpty) {
      minRentalDuration.value = value;
    }
  }

  void updateListingMode(String? value) {
    final mode = _normalizeListingMode(value ?? '');
    listingMode.value = mode;
    if (mode != 'both') {
      draftUnitMode.value = mode;
    }
  }

  void incrementFloorCount() {
    if (floorCount.value < maxFloorCount) floorCount.value++;
  }

  void decrementFloorCount() {
    if (floorCount.value > minFloorCount) floorCount.value--;
  }

  void onAddressQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      addressSuggestions.clear();
      return;
    }
    _searchDebounce = Timer(
      _searchDebounceDuration,
      () => _fetchSuggestions(query),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    addressSuggestionsLoading.value = true;
    addressSuggestions.clear();
    try {
      final list = await _nominatim.search(query);
      addressSuggestions.assignAll(list);
    } finally {
      addressSuggestionsLoading.value = false;
    }
  }

  void selectAddress(NominatimPlace place) {
    streetAddressController.text = place.displayName;
    selectedLat.value = place.lat;
    selectedLon.value = place.lon;
    addressSuggestions.clear();
  }

  void clearAddressSelection() {
    selectedLat.value = null;
    selectedLon.value = null;
  }

  /// Called when user taps on the map to set exact location. Updates lat/lon and optionally address.
  Future<void> updateLocationFromMap(double lat, double lon) async {
    selectedLat.value = lat;
    selectedLon.value = lon;
    try {
      final place = await _nominatim.reverseGeocode(lat, lon);
      if (place != null) {
        streetAddressController.text = place.displayName;
      }
    } catch (_) {
      // Keep current address text if reverse geocode fails
    }
  }

  final propertyTypes = [
    'Apartment',
    'House',
    'Villa',
    'Cabin',
    'Studio',
    'Other',
  ];

  /// Step 2: photos per room. Keys: livingRoom, bedroom, kitchen, bathroom. Value: list of file paths.
  final roomPhotos = <String, List<String>>{
    roomKeyLivingRoom: [],
    roomKeyBedroom: [],
    roomKeyKitchen: [],
    roomKeyBathroom: [],
  }.obs;

  static const String roomKeyLivingRoom = 'LIVING ROOM';
  static const String roomKeyBedroom = 'BEDROOM';
  static const String roomKeyKitchen = 'KITCHEN';
  static const String roomKeyBathroom = 'BATHROOM';
  static const int photoSlotsCount = 4;

  /// Step 2: single cover photo for listing preview
  final propertyCoverPhotoPath = Rxn<String>();

  Future<void> pickCoverPhoto({required bool fromGallery}) async {
    try {
      final source = fromGallery ? ImageSource.gallery : ImageSource.camera;
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null && picked.path.isNotEmpty) {
        propertyCoverPhotoPath.value = picked.path;
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not pick image: $e');
    }
  }

  void clearCoverPhoto() {
    propertyCoverPhotoPath.value = null;
  }

  /// Step 3: capacity (rooms, baths, guests)
  final numberOfBedroomsController = TextEditingController(text: '1');
  final numberOfBathsController = TextEditingController(text: '1');
  final maxGuestsController = TextEditingController(text: '2');

  final ImagePicker _imagePicker = ImagePicker();

  final _photoSlotsFilled = 0.obs;
  int get photoSlotsFilled => _photoSlotsFilled.value;
  set photoSlotsFilled(int value) => _photoSlotsFilled.value = value;

  void _updatePhotoSlotsFilled() {
    _photoSlotsFilled.value = roomPhotos.values
        .where((list) => list.isNotEmpty)
        .length;
  }

  List<String> getRoomPhotos(String roomKey) => roomPhotos[roomKey] ?? [];

  Future<void> pickPhotoForRoom(
    String roomKey, {
    required bool fromGallery,
  }) async {
    try {
      final source = fromGallery ? ImageSource.gallery : ImageSource.camera;
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null && picked.path.isNotEmpty) {
        if (!roomPhotos.containsKey(roomKey)) roomPhotos[roomKey] = [];
        roomPhotos[roomKey]!.add(picked.path);
        roomPhotos.refresh();
        _updatePhotoSlotsFilled();
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not pick image: $e');
    }
  }

  void removeRoomPhoto(String roomKey, int index) {
    final list = roomPhotos[roomKey];
    if (list != null && index >= 0 && index < list.length) {
      list.removeAt(index);
      roomPhotos.refresh();
      _updatePhotoSlotsFilled();
    }
  }

  void clearRoomPhotos(String roomKey) {
    roomPhotos[roomKey] = [];
    roomPhotos.refresh();
    _updatePhotoSlotsFilled();
  }

  /// Step 3: Initial investment (individual items or total cost)
  /// 'individual' = list of items (Item, Type, Units, Cost/Unit); 'total' = single approximate total
  final initialInvestmentMode = 'individual'.obs;
  final investmentItems = <InvestmentItem>[].obs;
  final approximateTotalCostController = TextEditingController(text: '0.00');

  void setInitialInvestmentMode(String mode) {
    initialInvestmentMode.value = mode;
  }

  void addInvestmentItem() {
    investmentItems.add(
      InvestmentItem(item: '', type: '', units: '', costPerUnit: ''),
    );
    _investmentItemControllers.add([
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ]);
    investmentItems.refresh();
  }

  final List<List<TextEditingController>> _investmentItemControllers = [];

  List<TextEditingController>? getInvestmentItemControllers(int index) {
    if (index >= 0 && index < _investmentItemControllers.length) {
      return _investmentItemControllers[index];
    }
    return null;
  }

  void removeInvestmentItem(int index) {
    if (index >= 0 && index < investmentItems.length) {
      investmentItems.removeAt(index);
      final controllers = _investmentItemControllers[index];
      for (final c in controllers) {
        c.dispose();
      }
      _investmentItemControllers.removeAt(index);
      investmentItems.refresh();
    }
  }

  void syncInvestmentItemFromControllers(int index) {
    if (index >= 0 &&
        index < _investmentItemControllers.length &&
        index < investmentItems.length) {
      final cs = _investmentItemControllers[index];
      if (cs.length >= 4) {
        investmentItems[index] = InvestmentItem(
          item: cs[0].text.trim(),
          type: cs[1].text.trim(),
          units: cs[2].text.trim(),
          costPerUnit: cs[3].text.trim(),
        );
        investmentItems.refresh();
      }
    }
  }

  void updateInvestmentItem(
    int index, {
    String? item,
    String? type,
    String? units,
    String? costPerUnit,
  }) {
    if (index >= 0 && index < investmentItems.length) {
      final i = investmentItems[index];
      investmentItems[index] = InvestmentItem(
        item: item ?? i.item,
        type: type ?? i.type,
        units: units ?? i.units,
        costPerUnit: costPerUnit ?? i.costPerUnit,
      );
      final cs = index < _investmentItemControllers.length
          ? _investmentItemControllers[index]
          : null;
      if (cs != null && cs.length >= 4) {
        if (item != null) cs[0].text = item;
        if (type != null) cs[1].text = type;
        if (units != null) cs[2].text = units;
        if (costPerUnit != null) cs[3].text = costPerUnit;
      }
      investmentItems.refresh();
    }
  }

  /// Step 4: Pricing & Rules
  final baseNightlyRateController = TextEditingController(text: '0.00');
  final cleaningFeeController = TextEditingController(text: '0.00');
  final instantBook = true.obs;
  final petsAllowed = false.obs;

  void goBack() {
    if (currentStep.value > 1) {
      currentStep.value--;
    } else {
      if (fromFirstLogin) {
        Get.offAllNamed(Routes.MAIN, arguments: {'initialMenu': 'home'});
      } else {
        Get.back();
      }
    }
  }

  Future<void> saveDraft() async {
    if (isEditMode.value) {
      Get.snackbar(
        'Draft',
        'Editing an existing listing. Use Update to save changes.',
      );
      return;
    }
    final request = AddListingRequest(
      propertyName: propertyNameController.text.trim().isEmpty
          ? null
          : propertyNameController.text.trim(),
      propertyType: selectedPropertyType.value,
      streetAddress: streetAddressController.text.trim().isEmpty
          ? null
          : streetAddressController.text.trim(),
      latitude: selectedLat.value,
      longitude: selectedLon.value,
      numberOfBedrooms: _parseInt(numberOfBedroomsController.text.trim()),
      numberOfBaths: _parseDouble(numberOfBathsController.text.trim()),
      maxGuests: _parseInt(maxGuestsController.text.trim()),
      baseNightlyRate: _parseDouble(baseNightlyRateController.text.trim()),
      cleaningFee: _parseDouble(cleaningFeeController.text.trim()),
      instantBook: instantBook.value,
      petsAllowed: petsAllowed.value,
    );
    final listingJson = request.toJson()
      ..['listingMode'] = listingMode.value
      ..['workspaceType'] = listingMode.value;
    final roomPhotoPaths = <String, List<String>>{
      for (final e in roomPhotos.entries) e.key: List<String>.from(e.value),
    };
    final coverPath = propertyCoverPhotoPath.value;
    await _draftStore.save(
      listingJson: listingJson,
      roomPhotoPaths: roomPhotoPaths,
      coverPhotoPath: coverPath,
      currentStep: currentStep.value,
    );
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      'Draft saved',
      'You can resume this listing later from Add Listing.',
    );
    if (fromFirstLogin) {
      Get.offAllNamed(Routes.MAIN, arguments: {'initialMenu': 'home'});
    } else {
      Get.back();
    }
  }

  void nextStep() {
    if (currentStep.value == 1) {
      if (formKey.currentState?.validate() ?? false) {
        currentStep.value = 2;
      }
    } else if (currentStep.value == 2) {
      if (propertyCoverPhotoPath.value != null &&
          propertyCoverPhotoPath.value!.isNotEmpty) {
        currentStep.value = 3;
      } else {
        Get.snackbar('Required', 'Please add a cover photo for your listing.');
      }
    } else if (currentStep.value == 3) {
      if (_parseInt(numberOfBedroomsController.text) != null &&
          _parseDouble(numberOfBathsController.text) != null &&
          _parseInt(maxGuestsController.text) != null) {
        currentStep.value = 4;
      } else {
        Get.snackbar('Required', 'Please enter rooms, baths, and max guests.');
      }
    } else if (currentStep.value == 4) {
      currentStep.value = 5;
    } else if (currentStep.value == 5) {
      currentStep.value = 6;
    } else if (currentStep.value == 6) {
      currentStep.value = 7;
    } else {
      Get.back();
    }
  }

  String? validateDraftUnitRent(String? value) {
    if (apartmentUnits.isNotEmpty) return null;
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Unit rent is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  Future<void> saveProperty() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final location = propertyLocationController.text.trim();
    if (location.isEmpty) {
      Get.snackbar('Error', 'Please enter a property location');
      return;
    }
    if (isApartmentProperty && apartmentUnits.isEmpty) {
      Get.snackbar('Error', 'Add at least one apartment unit');
      return;
    }
    if (!hideListingRentAmount) {
      final rentRaw = rentAmountController.text.trim().replaceAll(',', '');
      final rentValue = double.tryParse(rentRaw);
      if (rentValue == null || rentValue <= 0) {
        Get.snackbar('Error', 'Please enter a valid rent amount');
        return;
      }
    }
    await runBusy(() async {
      try {
        final original = _editingOriginal;
        final unitMaps = _apartmentUnitMapsForSave();
        final unitsJson = unitMaps.isEmpty ? '' : jsonEncode(unitMaps);
        if (original != null) {
          final rentOut = hideListingRentAmount
              ? ''
              : rentAmountController.text.trim();
          await _local.update(
            PropertyRecord(
              id: original.id,
              propertyLocation: location,
              propertyName: propertyNameController.text.trim(),
              propertyType: _effectivePropertyType,
              propertyRef: original.propertyRef,
              tenants: original.tenants,
              units: _listedUnitCount(),
              ownerUserId: original.ownerUserId,
              workspaceType: listingMode.value,
              createdAtMs: original.createdAtMs,
              rentAmount: rentOut,
              rentFrequency: rentFrequency.value,
              minRentalDuration: minRentalDuration.value,
              unitsJson: unitsJson,
              floorCount: floorCount.value,
              coverPhotoPath: PropertyListingImageAssigner.coverPathForSave(
                propertyRef: original.propertyRef,
                userSelectedPath: propertyCoverPhotoPath.value,
                existingStoredPath: original.coverPhotoPath,
                localPropertyId: original.id,
                propertyName: propertyNameController.text.trim(),
              ),
            ),
          );
          await syncPropertyUnitsForListingSave(
            unitLocal: _unitLocal,
            propertyRef: original.propertyRef,
            isApartment: isApartmentProperty,
            apartmentUnitMaps: unitMaps,
            minRentalDuration: minRentalDuration.value,
            listingRentFrequency: rentFrequency.value,
            listingRentRaw: rentAmountController.text.trim(),
            singleUnitName: propertyNameController.text.trim(),
            rooms: int.tryParse(numberOfBedroomsController.text.trim()) ?? 0,
            maxGuests: int.tryParse(maxGuestsController.text.trim()) ?? 0,
            listingMode: listingMode.value,
          );
          Get.back(result: true);
          showSuccessWithHaptic('Property updated on this device');
        } else {
          final propertyRef = 'local_${DateTime.now().millisecondsSinceEpoch}';
          final coverPath = PropertyListingImageAssigner.coverPathForSave(
            propertyRef: propertyRef,
            userSelectedPath: propertyCoverPhotoPath.value,
            propertyName: propertyNameController.text.trim(),
          );
          await _local.insert(
            PropertyRecord(
              id: 0,
              propertyLocation: location,
              propertyName: propertyNameController.text.trim(),
              propertyType: _effectivePropertyType,
              propertyRef: propertyRef,
              tenants: 0,
              units: _listedUnitCount(),
              ownerUserId: (await _preferenceManager.getUser()).id ?? '',
              workspaceType: listingMode.value,
              createdAtMs: DateTime.now().millisecondsSinceEpoch,
              rentAmount: rentAmountController.text.trim(),
              rentFrequency: rentFrequency.value,
              minRentalDuration: minRentalDuration.value,
              unitsJson: unitsJson,
              floorCount: floorCount.value,
              coverPhotoPath: coverPath,
            ),
          );
          await syncPropertyUnitsForListingSave(
            unitLocal: _unitLocal,
            propertyRef: propertyRef,
            isApartment: isApartmentProperty,
            apartmentUnitMaps: unitMaps,
            minRentalDuration: minRentalDuration.value,
            listingRentFrequency: rentFrequency.value,
            listingRentRaw: rentAmountController.text.trim(),
            singleUnitName: propertyNameController.text.trim(),
            rooms: int.tryParse(numberOfBedroomsController.text.trim()) ?? 0,
            maxGuests: int.tryParse(maxGuestsController.text.trim()) ?? 0,
            listingMode: listingMode.value,
          );
          Get.back(result: true);
          showSuccessWithHaptic('Property saved on this device');
        }
      } catch (e, st) {
        logger.e('saveProperty $e $st');
        Get.snackbar('Error', 'Could not save property');
      }
    });
  }

  String _newApartmentUnitId() =>
      'u_${DateTime.now().microsecondsSinceEpoch}_${apartmentUnits.length}';

  /// Ensures every unit has a persistent [ApartmentUnitDraft.unitId] in JSON.
  void _ensureApartmentUnitIds() {
    if (!isApartmentProperty || apartmentUnits.isEmpty) return;
    final next = <ApartmentUnitDraft>[];
    var changed = false;
    for (final u in apartmentUnits) {
      if (u.unitId.trim().isEmpty) {
        next.add(
          ApartmentUnitDraft(
            unitId: _newApartmentUnitId(),
            unitName: u.unitName,
            unitRent: u.unitRent,
            unitRentFrequency: rentFrequency.value,
            unitFloor: u.unitFloor,
            operationMode: _unitModeForSave(u),
            unitDescription: u.unitDescription,
          ),
        );
        changed = true;
      } else {
        next.add(u);
      }
    }
    if (changed) apartmentUnits.assignAll(next);
  }

  void addApartmentUnit() {
    final name = draftUnitNameController.text.trim();
    final rent = draftUnitRentController.text.trim();
    if (name.isEmpty || rent.isEmpty) {
      Get.snackbar('Error', 'Unit name and rent are required');
      return;
    }
    apartmentUnits.add(
      ApartmentUnitDraft(
        unitId: _newApartmentUnitId(),
        unitName: name,
        unitRent: rent,
        unitRentFrequency: rentFrequency.value,
        unitFloor: draftUnitFloor.value,
        operationMode: listingMode.value == 'both'
            ? _normalizeUnitMode(draftUnitMode.value)
            : _normalizeListingMode(listingMode.value),
        unitDescription: draftUnitDescriptionController.text.trim(),
      ),
    );
    draftUnitNameController.clear();
    draftUnitRentController.clear();
    draftUnitDescriptionController.clear();
    draftUnitRentFrequency.value = rentFrequency.value;
    draftUnitFloor.value = PropertyUnitFloor.defaultIndex;
    draftUnitMode.value = listingMode.value == 'rent' ? 'rent' : 'bnb';
  }

  void updateDraftUnitFloor(int? value) {
    if (value != null && PropertyUnitFloor.indices.contains(value)) {
      draftUnitFloor.value = value;
    }
  }

  void updateDraftUnitMode(String? value) {
    draftUnitMode.value = _normalizeUnitMode(value ?? '');
  }

  void removeApartmentUnit(int index) {
    if (index >= 0 && index < apartmentUnits.length) {
      apartmentUnits.removeAt(index);
    }
  }

  List<Map<String, dynamic>> _apartmentUnitMapsForSave() {
    if (!isApartmentProperty || apartmentUnits.isEmpty) {
      return const [];
    }
    _ensureApartmentUnitIds();
    return apartmentUnits
        .map((u) => {...u.toJson(), 'operationMode': _unitModeForSave(u)})
        .toList();
  }

  int _listedUnitCount() {
    if (isApartmentProperty && apartmentUnits.isNotEmpty) {
      return apartmentUnits.length;
    }
    return 1;
  }

  final publishing = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    final rawListingId = args?['listing_id'];
    final id = rawListingId == null ? '' : rawListingId.toString().trim();
    if (id.isNotEmpty) {
      _listingId = id;
      isEditMode.value = true;
    }
    if (args?['isEditMode'] == true) {
      isEditMode.value = true;
    }
    if (isEditMode.value) {
      isEditing.value = true;
    }
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
  }

  @override
  void onReady() {
    super.onReady();
    if (isEditMode.value) {
      if (_listingId != null && _listingId!.isNotEmpty) {
        _loadListingForEdit();
      } else {
        _loadEditFromArgumentsOnly();
      }
    } else {
      _checkAndOfferResumeDraft();
    }
  }

  /// When not in edit mode, if a draft exists show a dialog to resume or start fresh.
  Future<void> _checkAndOfferResumeDraft() async {
    if (!_draftStore.hasDraft) {
      loadingListing.value = false;
      return;
    }
    final resume = await _showResumeDraftDialog();
    if (resume == true) {
      final draft = _draftStore.load();
      if (draft != null) _applyDraft(draft);
    } else if (resume == false) {
      await _draftStore.clear();
    }
    loadingListing.value = false;
  }

  /// Returns true to resume, false to start fresh, null if dismissed.
  Future<bool?> _showResumeDraftDialog() async {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Resume draft?'),
        content: const Text(
          'You have a saved draft. Would you like to resume where you left off or start a new listing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Start fresh'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Resume'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _applyDraft(Map<String, dynamic> draft) {
    final listing = draft['listing'] as Map<String, dynamic>?;
    if (listing != null) _prefillFromMap(listing);
    final pathsRaw = draft['roomPhotoPaths'];
    final paths = _parseRoomPhotoPaths(pathsRaw);
    for (final key in roomPhotos.keys) {
      roomPhotos[key] = List<String>.from(paths[key] ?? []);
    }
    roomPhotos.refresh();
    _updatePhotoSlotsFilled();
    final coverPath = draft['coverPhotoPath'] as String?;
    if (coverPath != null && coverPath.isNotEmpty) {
      propertyCoverPhotoPath.value = coverPath;
    }
    final step = draft['currentStep'] as int?;
    if (step != null && step >= 1 && step <= totalSteps) {
      currentStep.value = step;
    }
  }

  Map<String, List<String>> _parseRoomPhotoPaths(dynamic raw) {
    final map = <String, List<String>>{};
    if (raw is! Map) return map;
    for (final e in raw.entries) {
      if (e.value is List) {
        map[e.key.toString()] = (e.value as List)
            .map((x) => x.toString())
            .toList();
      }
    }
    return map;
  }

  Future<void> _loadEditFromArgumentsOnly() async {
    loadingListing.value = true;
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      final listingData = args?['listing_data'] as Map<String, dynamic>?;
      if (listingData != null) {
        _prefillFromMap(listingData);
        _mergeRentFieldsFromListingMap(listingData, respectLocalLocks: false);
      }
    } finally {
      loadingListing.value = false;
    }
  }

  Future<void> _loadListingForEdit() async {
    loadingListing.value = true;
    _rentFreqLockedFromLocal = false;
    _minDurLockedFromLocal = false;
    _rentAmountLockedFromLocal = false;
    _propertyTypeLockedFromLocal = false;
    _unitsLockedFromLocal = false;
    try {
      PropertyRecord? local;
      try {
        local = await _local.findByHubId(_listingId!);
      } catch (_) {}

      if (local != null) {
        _prefillFromPropertyRecord(local);
      }

      Map<String, dynamic>? remoteMap;
      try {
        final res = await _repository.getListing(_listingId!);
        final ok =
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (ok && res.data != null) {
          remoteMap = _unwrapListingPayload(res.data);
        }
      } catch (_) {}

      if (remoteMap != null) {
        _prefillFromMap(remoteMap);
        _mergeRentFieldsFromListingMap(
          remoteMap,
          respectLocalLocks: local != null,
        );
      } else {
        final args = Get.arguments as Map<String, dynamic>?;
        final listingData = args?['listing_data'] as Map<String, dynamic>?;
        if (listingData != null) {
          _prefillFromMap(listingData);
          _mergeRentFieldsFromListingMap(
            listingData,
            respectLocalLocks: local != null,
          );
        }
      }

      final args = Get.arguments as Map<String, dynamic>?;
      final listingData = args?['listing_data'] as Map<String, dynamic>?;
      if (listingData != null) {
        _prefillFromMap(listingData);
        _mergeRentFieldsFromListingMap(listingData, respectLocalLocks: false);
      }
    } catch (_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final listingData = args?['listing_data'] as Map<String, dynamic>?;
      if (listingData != null) {
        _prefillFromMap(listingData);
        _mergeRentFieldsFromListingMap(listingData, respectLocalLocks: false);
      }
    } finally {
      loadingListing.value = false;
    }
  }

  Map<String, dynamic>? _unwrapListingPayload(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map && data['listing'] is Map) {
      return Map<String, dynamic>.from(data['listing'] as Map);
    }
    return null;
  }

  void _prefillFromPropertyRecord(PropertyRecord r) {
    _editingOriginal = r;
    _rentFreqLockedFromLocal = r.rentFrequency.trim().isNotEmpty;
    _minDurLockedFromLocal = r.minRentalDuration.trim().isNotEmpty;
    _rentAmountLockedFromLocal = r.rentAmount.trim().isNotEmpty;
    _propertyTypeLockedFromLocal = r.propertyType.trim().isNotEmpty;
    _unitsLockedFromLocal = r.unitsJson.trim().isNotEmpty;

    propertyLocationController.text = r.propertyLocation;
    streetAddressController.text = r.propertyLocation;
    propertyNameController.text = r.propertyName;
    listingMode.value = _normalizeListingMode(r.workspaceType);
    _applyPropertyTypeSelection(r.propertyType);
    rentAmountController.text = r.rentAmount.trim();
    if (_rentFreqLockedFromLocal) {
      rentFrequency.value = _coerceRentFrequency(r.rentFrequency);
    }
    if (_minDurLockedFromLocal) {
      minRentalDuration.value = _coerceMinRentalDuration(r.minRentalDuration);
    }
    floorCount.value = r.floorCount.clamp(minFloorCount, maxFloorCount);
    _loadApartmentUnitsFromJson(r.unitsJson);
    isEditing.value = true;
  }

  String _coerceRentFrequency(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return rentFrequency.value;
    for (final o in _rentFrequencyChoices) {
      if (o.toLowerCase() == t.toLowerCase()) return o;
    }
    return t;
  }

  String _coerceMinRentalDuration(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return minRentalDuration.value;
    for (final o in minRentalDurationOptions) {
      if (o.toLowerCase() == t.toLowerCase()) return o;
    }
    final lower = t.toLowerCase();
    if (lower.contains('month')) return '1 Month';
    if (lower.contains('week')) return '1 Week';
    if (lower.contains('1') && lower.contains('day')) return '1 Day';
    if (lower.contains('2') && lower.contains('day')) return '2 Days';
    return minRentalDuration.value;
  }

  String _normalizeListingMode(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'rent') return 'rent';
    if (v == 'both') return 'both';
    return 'bnb';
  }

  String _normalizeUnitMode(String raw) {
    final v = raw.trim().toLowerCase();
    return v == 'rent' ? 'rent' : 'bnb';
  }

  String _unitModeForSave(ApartmentUnitDraft unit) {
    final propertyMode = _normalizeListingMode(listingMode.value);
    if (propertyMode == 'both') {
      return _normalizeUnitMode(unit.operationMode);
    }
    return propertyMode;
  }

  void _applyPropertyTypeSelection(String rawType) {
    final t = rawType.trim();
    if (t.isEmpty) return;
    for (final o in propertyTypes) {
      if (o.toLowerCase() == t.toLowerCase()) {
        selectedPropertyType.value = o;
        propertyType.value = o;
        return;
      }
    }
    for (final o in propertyTypeOptions) {
      if (o.toLowerCase() == t.toLowerCase()) {
        final mapped = _mapLegacyPropertyTypeToFormOption(o);
        selectedPropertyType.value = mapped;
        propertyType.value = mapped;
        return;
      }
    }
    selectedPropertyType.value = 'Other';
    propertyType.value = 'Other';
  }

  String _mapLegacyPropertyTypeToFormOption(String legacy) {
    switch (legacy) {
      case 'Office space':
      case 'Room':
      case 'Storage':
        return 'Other';
      default:
        return propertyTypes.contains(legacy) ? legacy : 'Other';
    }
  }

  void _loadApartmentUnitsFromJson(String raw) {
    apartmentUnits.clear();
    final s = raw.trim();
    if (s.isEmpty) return;
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return;
      final list = <ApartmentUnitDraft>[];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          list.add(ApartmentUnitDraft.fromJson(e));
        } else if (e is Map) {
          list.add(ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      apartmentUnits.assignAll(list);
    } catch (_) {}
  }

  void _loadApartmentUnitsFromList(List<dynamic> rows) {
    final list = <ApartmentUnitDraft>[];
    for (final e in rows) {
      if (e is Map<String, dynamic>) {
        list.add(ApartmentUnitDraft.fromJson(e));
      } else if (e is Map) {
        list.add(ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    if (list.isEmpty) return;
    apartmentUnits.assignAll(list);
  }

  String? _readStr(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  String _formatRentFromDynamic(dynamic n) {
    if (n is num) {
      final d = n.toDouble();
      if (d == d.roundToDouble()) return d.toInt().toString();
      return d.toString();
    }
    return n.toString().trim();
  }

  /// Fills rent-first form fields from API/snake_case maps (and BnB-style keys where useful).
  void _mergeRentFieldsFromListingMap(
    Map<String, dynamic> m, {
    required bool respectLocalLocks,
  }) {
    bool allowRentAmount() => !respectLocalLocks || !_rentAmountLockedFromLocal;
    bool allowRentFreq() => !respectLocalLocks || !_rentFreqLockedFromLocal;
    bool allowMinDur() => !respectLocalLocks || !_minDurLockedFromLocal;
    bool allowType() => !respectLocalLocks || !_propertyTypeLockedFromLocal;
    bool allowUnits() => !respectLocalLocks || !_unitsLockedFromLocal;

    final loc = _readStr(m, [
      'propertyLocation',
      'streetAddress',
      'location',
      'propertyLocationText',
    ]);
    if (loc != null) {
      if (!respectLocalLocks ||
          propertyLocationController.text.trim().isEmpty) {
        propertyLocationController.text = loc;
      }
      if (!respectLocalLocks || streetAddressController.text.trim().isEmpty) {
        streetAddressController.text = loc;
      }
    }

    final name = _readStr(m, [
      'propertyName',
      'property_name',
      'title',
      'name',
    ]);
    if (name != null &&
        (!respectLocalLocks || propertyNameController.text.trim().isEmpty)) {
      propertyNameController.text = name;
    }

    final type = _readStr(m, ['propertyType', 'property_type', 'type']);
    if (type != null && allowType()) {
      _applyPropertyTypeSelection(type);
    }

    if (allowRentAmount()) {
      final rentStr = _readStr(m, ['rentAmount', 'monthlyRent', 'rent']);
      if (rentStr != null) {
        rentAmountController.text = rentStr;
      } else {
        final n = m['rentAmount'] ?? m['monthlyRent'] ?? m['baseNightlyRate'];
        if (n != null && n.toString().trim().isNotEmpty) {
          rentAmountController.text = _formatRentFromDynamic(n);
        }
      }
    }

    final freq = _readStr(m, ['rentFrequency', 'rent_frequency']);
    if (freq != null && allowRentFreq()) {
      rentFrequency.value = _coerceRentFrequency(freq);
    }

    final minD = _readStr(m, [
      'minRentalDuration',
      'min_rental_duration',
      'minimumStay',
    ]);
    if (minD != null && allowMinDur()) {
      minRentalDuration.value = _coerceMinRentalDuration(minD);
    }

    if (allowUnits()) {
      final uj = _readStr(m, ['unitsJson', 'units_json']);
      if (uj != null && uj.isNotEmpty) {
        _loadApartmentUnitsFromJson(uj);
      } else {
        final units = m['units'] ?? m['apartmentUnits'];
        if (units is List && units.isNotEmpty) {
          _loadApartmentUnitsFromList(units);
        }
      }
    }
  }

  void _prefillFromMap(Map<String, dynamic> data) {
    final name = data['propertyName'] as String?;
    if (name != null && name.isNotEmpty) propertyNameController.text = name;
    final type = data['propertyType'] as String?;
    if (type != null && type.isNotEmpty) selectedPropertyType.value = type;
    final mode =
        data['listingMode'] ?? data['workspaceType'] ?? data['workspace_type'];
    if (mode != null) {
      listingMode.value = _normalizeListingMode(mode.toString());
    }
    final address = data['streetAddress'] as String?;
    if (address != null && address.isNotEmpty) {
      streetAddressController.text = address;
    }
    final lat = (data['latitude'] as num?)?.toDouble();
    if (lat != null) selectedLat.value = lat;
    final lon = (data['longitude'] as num?)?.toDouble();
    if (lon != null) selectedLon.value = lon;
    final rate = (data['baseNightlyRate'] as num?)?.toDouble();
    if (rate != null) baseNightlyRateController.text = rate.toStringAsFixed(0);
    final fee = (data['cleaningFee'] as num?)?.toDouble();
    if (fee != null) cleaningFeeController.text = fee.toStringAsFixed(0);
    final instant = data['instantBook'] as bool?;
    if (instant != null) instantBook.value = instant;
    final pets = data['petsAllowed'] as bool?;
    if (pets != null) petsAllowed.value = pets;
    final beds = data['numberOfBedrooms'] as int?;
    if (beds != null) numberOfBedroomsController.text = beds.toString();
    final baths = (data['numberOfBaths'] as num?)?.toDouble();
    if (baths != null) numberOfBathsController.text = baths.toString();
    final guests = data['maxGuests'] as int?;
    if (guests != null) maxGuestsController.text = guests.toString();
  }

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any(
      (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile,
    );
  }

  Future<void> publishListing() async {
    if (publishing.value) return;

    final request = AddListingRequest(
      propertyName: propertyNameController.text.trim().isEmpty
          ? null
          : propertyNameController.text.trim(),
      propertyType: selectedPropertyType.value,
      streetAddress: streetAddressController.text.trim().isEmpty
          ? null
          : streetAddressController.text.trim(),
      latitude: selectedLat.value,
      longitude: selectedLon.value,
      numberOfBedrooms: _parseInt(numberOfBedroomsController.text.trim()),
      numberOfBaths: _parseDouble(numberOfBathsController.text.trim()),
      maxGuests: _parseInt(maxGuestsController.text.trim()),
      baseNightlyRate: _parseDouble(baseNightlyRateController.text.trim()),
      cleaningFee: _parseDouble(cleaningFeeController.text.trim()),
      instantBook: instantBook.value,
      petsAllowed: petsAllowed.value,
    );

    final roomPhotoPaths = <String, List<String>>{
      for (final e in roomPhotos.entries) e.key: List<String>.from(e.value),
    };
    final coverPath = propertyCoverPhotoPath.value;

    publishing.value = true;
    try {
      if (isEditMode.value && _listingId != null) {
        final online = await _isOnline();
        bool updated = false;
        if (online) {
          try {
            final response = await _repository.updateListing(
              _listingId!,
              request,
              roomPhotoPaths,
              coverPhotoPath: coverPath,
            );
            updated = response.responseCode == '200' ||
                response.responseCode == '201' ||
                response.responseCode == '0';
          } catch (_) {
            updated = false;
          }
        }
        if (!updated) {
          await _syncQueue.enqueue(
            entityType: 'listing',
            operation: 'update',
            payloadJson: jsonEncode({
              'listingId': _listingId,
              'listing': request.toJson(),
              'roomPhotoPaths': roomPhotoPaths,
              if (coverPath != null && coverPath.isNotEmpty)
                'coverPhotoPath': coverPath,
            }),
            dedupeKey: 'listing:update:$_listingId',
          );
          await _syncWorker.runNow(maxItems: 20);
          Get.back();
          Get.snackbar(
            online ? 'Update queued' : 'Saved offline',
            online
                ? 'Listing update will retry shortly.'
                : 'Listing will sync when you\'re back online.',
          );
        } else {
          Get.back();
          Get.snackbar('Updated', 'Listing updated successfully.');
        }
        return;
      }
      final online = await _isOnline();
      if (!online) {
        await _syncQueue.enqueue(
          entityType: 'listing',
          operation: 'create',
          payloadJson: jsonEncode({
            'listing': request.toJson(),
            'roomPhotoPaths': roomPhotoPaths,
            if (coverPath != null && coverPath.isNotEmpty)
              'coverPhotoPath': coverPath,
          }),
        );
        await _syncWorker.runNow(maxItems: 20);
        final pending = await _syncQueue.pendingCountByEntity(
          entityType: 'listing',
          operation: 'create',
        );
        await _draftStore.clear();
        Get.offNamed(Routes.LISTING_PUBLISHED);
        if (pending > 0) {
          Get.snackbar(
            'Saved offline',
            'Listing will sync when you\'re back online.',
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.snackbar('Published', 'Listing synced successfully.');
        }
        publishing.value = false;
        return;
      }
      await _syncQueue.enqueue(
        entityType: 'listing',
        operation: 'create',
        payloadJson: jsonEncode({
          'listing': request.toJson(),
          'roomPhotoPaths': roomPhotoPaths,
          if (coverPath != null && coverPath.isNotEmpty)
            'coverPhotoPath': coverPath,
        }),
      );
      await _syncWorker.runNow(maxItems: 20);
      final pending = await _syncQueue.pendingCountByEntity(
        entityType: 'listing',
        operation: 'create',
      );
      if (pending > 0) {
        Get.snackbar(
          'Saved offline',
          'Listing queued. Will sync when internet is available.',
        );
        return;
      }
      await _draftStore.clear();
      Get.offNamed(Routes.LISTING_PUBLISHED);
    } catch (e) {
      Get.snackbar(
        'Error',
        isEditMode.value
            ? 'Failed to update listing: $e'
            : 'Failed to publish listing: $e',
      );
    } finally {
      publishing.value = false;
    }
  }

  static double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
  }

  static int? _parseInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
  }

  void editListingDetails() {
    currentStep.value = 1;
  }

  void openHelp() {
    Get.snackbar('Help', 'Add listing help can be shown here.');
  }

  void selectPropertyType(String? value) {
    selectedPropertyType.value = value;
    if (value != null && value.trim().isNotEmpty) {
      propertyType.value = value.trim();
    }
  }

  String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    propertyNameController.dispose();
    streetAddressController.dispose();
    numberOfBedroomsController.dispose();
    numberOfBathsController.dispose();
    maxGuestsController.dispose();
    approximateTotalCostController.dispose();
    baseNightlyRateController.dispose();
    cleaningFeeController.dispose();
    for (final list in _investmentItemControllers) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.onClose();
  }
}

/// One line item for initial investment (individual items mode).
class InvestmentItem {
  InvestmentItem({
    required this.item,
    required this.type,
    required this.units,
    required this.costPerUnit,
  });
  String item;
  String type;
  String units;
  String costPerUnit;
}

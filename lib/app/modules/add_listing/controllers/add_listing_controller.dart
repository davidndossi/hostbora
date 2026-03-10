import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/pending_listings_store.dart';
import '../../../data/model/add_listing_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/service/nominatim_service.dart';
import '../../../routes/app_pages.dart';

class AddListingController extends BaseController {
  AddListingController()
      : _nominatim = Get.find<NominatimService>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _pendingStore = PendingListingsStore();

  final NominatimService _nominatim;
  final AppRepository _repository;
  final PendingListingsStore _pendingStore;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final formKey = GlobalKey<FormState>();
  final propertyNameController = TextEditingController();
  final streetAddressController = TextEditingController();

  static const int totalSteps = 5;
  final currentStep = 1.obs;

  bool get fromFirstLogin => Get.arguments?['from_first_login'] == true;

  final selectedPropertyType = Rx<String?>(null);

  /// Selected location from OSM autocomplete (null until user picks an address).
  final selectedLat = Rxn<double>();
  final selectedLon = Rxn<double>();
  final addressSuggestions = <NominatimPlace>[].obs;
  final addressSuggestionsLoading = false.obs;
  Timer? _searchDebounce;

  static const _searchDebounceDuration = Duration(milliseconds: 400);

  void onAddressQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      addressSuggestions.clear();
      return;
    }
    _searchDebounce = Timer(_searchDebounceDuration, () => _fetchSuggestions(query));
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

  final ImagePicker _imagePicker = ImagePicker();

  final _photoSlotsFilled = 0.obs;
  int get photoSlotsFilled => _photoSlotsFilled.value;
  set photoSlotsFilled(int value) => _photoSlotsFilled.value = value;

  void _updatePhotoSlotsFilled() {
    _photoSlotsFilled.value =
        roomPhotos.values.where((list) => list.isNotEmpty).length;
  }

  List<String> getRoomPhotos(String roomKey) =>
      roomPhotos[roomKey] ?? [];

  Future<void> pickPhotoForRoom(String roomKey, {required bool fromGallery}) async {
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
    investmentItems.add(InvestmentItem(item: '', type: '', units: '', costPerUnit: ''));
    _investmentItemControllers.add([
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ]);
    investmentItems.refresh();
  }

  List<List<TextEditingController>> _investmentItemControllers = [];

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
    if (index >= 0 && index < _investmentItemControllers.length && index < investmentItems.length) {
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

  void updateInvestmentItem(int index, {String? item, String? type, String? units, String? costPerUnit}) {
    if (index >= 0 && index < investmentItems.length) {
      final i = investmentItems[index];
      investmentItems[index] = InvestmentItem(
        item: item ?? i.item,
        type: type ?? i.type,
        units: units ?? i.units,
        costPerUnit: costPerUnit ?? i.costPerUnit,
      );
      final cs = index < _investmentItemControllers.length ? _investmentItemControllers[index] : null;
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

  void saveDraft() {
    // TODO: persist draft and optionally go back
    Get.back();
  }

  void nextStep() {
    if (currentStep.value == 1) {
      if (formKey.currentState?.validate() ?? false) {
        currentStep.value = 2;
      }
    } else if (currentStep.value == 2) {
      currentStep.value = 3;
    } else if (currentStep.value == 3) {
      currentStep.value = 4;
    } else if (currentStep.value == 4) {
      currentStep.value = 5;
    } else {
      Get.back();
    }
  }

  final publishing = false.obs;
  final syncing = false.obs;

  @override
  void onReady() {
    super.onReady();
    _syncPendingWhenOnline();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile)) {
        _syncPendingWhenOnline();
      }
    });
  }

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
  }

  Map<String, List<String>> _parseRoomPhotoPaths(dynamic raw) {
    final map = <String, List<String>>{};
    if (raw is! Map) return map;
    for (final e in raw.entries) {
      if (e.value is List) {
        map[e.key.toString()] = (e.value as List).map((x) => x.toString()).toList();
      }
    }
    return map;
  }

  Future<void> _syncPendingWhenOnline() async {
    if (syncing.value) return;
    if (!await _isOnline()) return;
    final list = _pendingStore.load();
    if (list.isEmpty) return;
    syncing.value = true;
    try {
      final toKeep = <Map<String, dynamic>>[];
      var synced = 0;
      for (final item in list) {
        try {
          final listingMap = item['listing'] as Map<String, dynamic>?;
          if (listingMap == null) continue;
          final request = AddListingRequest.fromJson(listingMap);
          final paths = _parseRoomPhotoPaths(item['roomPhotoPaths']);
          final res = await _repository.publishListing(request, paths);
          if (res.responseCode == '200' || res.responseCode == '201') {
            synced++;
          } else {
            toKeep.add(item);
          }
        } catch (_) {
          toKeep.add(item);
        }
      }
      await _pendingStore.save(toKeep);
      if (synced > 0) {
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.snackbar('Synced', synced == 1 ? 'Offline listing synced.' : '$synced offline listings synced.');
      }
    } finally {
      syncing.value = false;
    }
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
      baseNightlyRate: _parseDouble(baseNightlyRateController.text.trim()),
      cleaningFee: _parseDouble(cleaningFeeController.text.trim()),
      instantBook: instantBook.value,
      petsAllowed: petsAllowed.value,
    );

    final roomPhotoPaths = <String, List<String>>{
      for (final e in roomPhotos.entries) e.key: List<String>.from(e.value),
    };

    publishing.value = true;
    try {
      final online = await _isOnline();
      if (!online) {
        await _pendingStore.add(request.toJson(), roomPhotoPaths);
        Get.offNamed(Routes.LISTING_PUBLISHED);
        Get.snackbar(
          'Saved offline',
          'Listing will sync when you\'re back online.',
          duration: const Duration(seconds: 4),
        );
        publishing.value = false;
        return;
      }
      await _syncPendingWhenOnline();
      final response = await _repository.publishListing(request, roomPhotoPaths);
      if (response.responseCode == '200' || response.responseCode == '201') {
        Get.offNamed(Routes.LISTING_PUBLISHED);
      } else {
        Get.snackbar(
          'Publish failed',
          response.message ?? 'Could not publish listing.',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to publish listing: $e');
    } finally {
      publishing.value = false;
    }
  }

  static double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
  }

  void editListingDetails() {
    currentStep.value = 1;
  }

  void openHelp() {
    Get.snackbar('Help', 'Add listing help can be shown here.');
  }

  void selectPropertyType(String? value) {
    selectedPropertyType.value = value;
  }

  String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _searchDebounce?.cancel();
    propertyNameController.dispose();
    streetAddressController.dispose();
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

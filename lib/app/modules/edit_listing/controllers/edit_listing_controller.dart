import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/access/plan_agents.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/base/feedback_extensions.dart';
import '../../../core/utils/property_listing_image_assigner.dart';
import '../../../core/utils/property_name_rules.dart';
import '../../../core/utils/property_remote_rent.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_listing_units_sync.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../add_listing/models/apartment_unit_draft.dart';

class EditListingController extends BaseController {
  EditListingController()
      : _local = Get.find<PropertyLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final PropertyLocalDataSource _local;
  final PropertyUnitLocalDataSource _unitLocal;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final formKey = GlobalKey<FormState>();
  final propertyLocationController = TextEditingController();
  final propertyNameController = TextEditingController();

  final loading = true.obs;
  final loadError = ''.obs;

  PropertyRecord? _original;
  String _snapLocation = '';
  String _snapName = '';
  String _snapUnitsCanon = '';

  final apartmentUnits = <ApartmentUnitDraft>[].obs;

  /// Non-apartment properties with an empty `units_json` do not list stored units.
  final omitStoredUnitList = false.obs;
  final draftUnitNameController = TextEditingController();
  final draftUnitRentController = TextEditingController();
  final draftUnitDescriptionController = TextEditingController();
  final draftUnitFloor = PropertyUnitFloor.defaultIndex.obs;
  final draftUnitMode = 'bnb'.obs;
  final coverPhotoPath = ''.obs;

  static const _rentFrequencyOptions = ['Per Day', 'Per Week', 'Per Month', 'Per Year'];
  final ImagePicker _imagePicker = ImagePicker();
  String _snapCover = '';

  /// Every property has at least one unit, so the editor is always shown.

  @override
  void onInit() {
    super.onInit();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    loading.value = true;
    loadError.value = '';
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      final propertyRef = (args?['property_ref'] ??
              args?['property_id'] ??
              args?['listing_id'] ??
              '')
          .toString()
          .trim();
      if (propertyRef.isEmpty) {
        loadError.value = 'Missing property reference.';
        return;
      }
      PropertyRecord? row = await _local.getByPropertyRef(propertyRef);
      if (row == null) {
        const lp = 'local_';
        if (propertyRef.startsWith(lp)) {
          final n = int.tryParse(propertyRef.substring(lp.length));
          if (n != null) row = await _local.getById(n);
        }
      }
      if (row == null) {
        const lg = 'legacy_';
        if (propertyRef.startsWith(lg)) {
          final n = int.tryParse(propertyRef.substring(lg.length));
          if (n != null) row = await _local.getById(n);
        }
      }
      if (row == null) {
        loadError.value = 'Property not found on this device.';
        return;
      }
      _original = row;
      _snapLocation = row.propertyLocation;
      _snapName = row.propertyName;
      propertyLocationController.text = row.propertyLocation;
      propertyNameController.text = row.propertyName;
      coverPhotoPath.value = PropertyListingImageAssigner.resolveDisplayPath(
        storedPath: row.coverPhotoPath,
        propertyRef: row.propertyRef,
        localPropertyId: row.id,
        propertyName: row.propertyName,
      );
      _snapCover = coverPhotoPath.value;
      await _loadUnits(row, propertyRef);
      _snapUnitsCanon = apartmentUnits.isEmpty
          ? ''
          : _canonicalUnitsJsonFromDrafts(apartmentUnits);

      // Pre-set unit draft mode + frequency from caller context.
      final rawMode = (args?['default_unit_mode'] ?? '').toString().trim().toLowerCase();
      if (rawMode == 'rent' || rawMode == 'bnb') {
        draftUnitMode.value = rawMode;
      }
    } catch (e, st) {
      logger.e('EditListing load $e $st');
      loadError.value = 'Could not load property.';
    } finally {
      loading.value = false;
    }
  }

  /// Local `units_json`, then `property_units`, then the remote listing / property.
  /// Non-apartment properties with an empty `units_json` keep the list blank.
  Future<void> _loadUnits(PropertyRecord row, String routeRef) async {
    apartmentUnits.clear();
    omitStoredUnitList.value = false;
    final fromJson = _draftsFromUnitsPayload(row.unitsJson);
    if (fromJson.isNotEmpty) {
      apartmentUnits.assignAll(fromJson);
      return;
    }
    if (row.propertyType.trim().toLowerCase() != 'apartment') {
      omitStoredUnitList.value = true;
      return;
    }

    final fromTable = await _draftsFromPropertyUnitsTable(row, routeRef);
    if (fromTable.isNotEmpty) {
      apartmentUnits.assignAll(fromTable);
      return;
    }

    final fromRemote = await _draftsFromRemote(row, routeRef);
    if (fromRemote.isNotEmpty) {
      apartmentUnits.assignAll(fromRemote);
      return;
    }

    apartmentUnits.assignAll([_placeholderUnit(row)]);
  }

  List<ApartmentUnitDraft> _draftsFromUnitsPayload(dynamic raw) {
    final decoded = _decodeUnitsPayload(raw);
    if (decoded == null) return const [];
    return _draftsFromList(decoded);
  }

  dynamic _decodeUnitsPayload(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) return null;
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty || text == '[]' || text == 'null') return null;
    try {
      var decoded = jsonDecode(text);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is List) return decoded;
      if (decoded is Map) return _decodeUnitsPayload(decoded);
    } catch (_) {}
    return null;
  }

  List<ApartmentUnitDraft> _draftsFromList(List<dynamic> decoded) {
    final out = <ApartmentUnitDraft>[];
    final seen = <String>{};
    for (final e in decoded) {
      if (e is! Map) continue;
      final draft = _draftFromLooseMap(Map<String, dynamic>.from(e));
      if (draft.unitName.trim().isEmpty) continue;
      final key = draft.unitId.trim().isNotEmpty
          ? 'id:${draft.unitId.trim().toLowerCase()}'
          : 'name:${draft.unitName.trim().toLowerCase()}';
      if (!seen.add(key)) continue;
      out.add(draft);
    }
    return out;
  }

  ApartmentUnitDraft _draftFromLooseMap(Map<String, dynamic> m) {
    return ApartmentUnitDraft.fromJson(m);
  }

  Future<List<ApartmentUnitDraft>> _draftsFromPropertyUnitsTable(
    PropertyRecord row,
    String routeRef,
  ) async {
    final refs = <String>{
      row.propertyRef.trim(),
      routeRef.trim(),
      'local_${row.id}',
      'legacy_${row.id}',
    }..removeWhere((ref) => ref.isEmpty);
    final records = <PropertyUnitRecord>[];
    final seen = <String>{};
    for (final ref in refs) {
      final rows = await _unitLocal.getAllByPropertyRefNewestFirstChunked(
        propertyRef: ref,
      );
      for (final unit in rows) {
        final key = unit.propertyUnitRef.trim().isNotEmpty
            ? 'id:${unit.propertyUnitRef.trim().toLowerCase()}'
            : 'name:${unit.unitName.trim().toLowerCase()}';
        if (key == 'id:' || key == 'name:') continue;
        if (!seen.add(key)) continue;
        records.add(unit);
      }
    }
    return records
        .where((unit) => unit.unitName.trim().isNotEmpty)
        .map(
          (unit) => ApartmentUnitDraft(
            unitId: unit.propertyUnitRef.trim(),
            unitName: unit.unitName.trim(),
            unitRent: _amountLabel(unit.rentAmount),
            unitRentFrequency: unit.rentFrequency.trim().isNotEmpty
                ? unit.rentFrequency.trim()
                : _defaultFrequency(row),
            unitFloor: unit.floor,
            operationMode: unit.operationMode.trim().toLowerCase() == 'rent'
                ? 'rent'
                : 'bnb',
            unitDescription: unit.notes.trim(),
            unitRentCurrency: unit.rentCurrency.trim().isEmpty
                ? 'TZS'
                : unit.rentCurrency.trim().toUpperCase(),
          ),
        )
        .toList();
  }

  Future<List<ApartmentUnitDraft>> _draftsFromRemote(
    PropertyRecord row,
    String routeRef,
  ) async {
    final ids = <String>{
      routeRef.trim(),
      row.propertyRef.trim(),
      'local_${row.id}',
      'legacy_${row.id}',
    }..removeWhere((id) => id.isEmpty);
    for (final id in ids) {
      final listing = await _fetchRemoteListing(id);
      final units = listing == null ? const <ApartmentUnitDraft>[] : _draftsFromRemoteMap(listing);
      if (units.isNotEmpty) return units;
    }
    try {
      final res = await _repository.getMyProperties();
      for (final map in _extractMaps(res.data)) {
        if (!_remoteMapMatches(map, row, routeRef)) continue;
        final units = _draftsFromRemoteMap(map);
        if (units.isNotEmpty) return units;
      }
    } catch (e, st) {
      logger.e('EditListing remote properties $e $st');
    }
    return const [];
  }

  Future<Map<String, dynamic>?> _fetchRemoteListing(String listingId) async {
    try {
      final res = await _repository.getProperty(listingId);
      return _unwrapRemoteMap(res.data);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _unwrapRemoteMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map && data['property'] is Map) {
      return Map<String, dynamic>.from(data['property'] as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  List<Map<String, dynamic>> _extractMaps(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map) {
      for (final key in const [
        'properties',
        'content',
        'items',
        'data',
      ]) {
        final nested = data[key];
        if (nested is List) {
          return nested.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      return [Map<String, dynamic>.from(data)];
    }
    return const [];
  }

  bool _remoteMapMatches(
    Map<String, dynamic> map,
    PropertyRecord row,
    String routeRef,
  ) {
    final ref = PropertyRecord.remoteRef(map);
    final ids = {
      row.propertyRef.trim(),
      routeRef.trim(),
      'local_${row.id}',
      'legacy_${row.id}',
    };
    return ref.isNotEmpty && ids.contains(ref);
  }

  List<ApartmentUnitDraft> _draftsFromRemoteMap(Map<String, dynamic> map) {
    return _draftsFromUnitsPayload(PropertyRecord.remoteUnitsJson(map));
  }

  ApartmentUnitDraft _placeholderUnit(PropertyRecord row) {
    final name = row.propertyName.trim().isNotEmpty
        ? row.propertyName.trim()
        : 'Unit 1';
    return ApartmentUnitDraft(
      unitId: 'main',
      unitName: name,
      unitRent: row.rentAmount.trim(),
      unitRentFrequency: _defaultFrequency(row),
      operationMode: _defaultMode(row),
      unitDescription: '',
      unitRentCurrency: Get.isRegistered<CurrencyService>()
          ? Get.find<CurrencyService>().baseCurrency.value
          : 'TZS',
    );
  }

  String _defaultFrequency(PropertyRecord row) {
    final frequency = row.rentFrequency.trim();
    if (frequency.isNotEmpty) return frequency;
    return _defaultMode(row) == 'rent' ? 'Per Month' : 'Per Day';
  }

  String _defaultMode(PropertyRecord row) {
    return row.workspaceType.trim().toLowerCase() == 'rent' ? 'rent' : 'bnb';
  }

  String _amountLabel(num amount) {
    if (amount <= 0) return '';
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toString();
  }

  static String _canonicalUnitsJsonFromDrafts(List<ApartmentUnitDraft> drafts) {
    if (drafts.isEmpty) return '';
    final copies = drafts
        .map(
          (u) => ApartmentUnitDraft(
            unitId: u.unitId.trim(),
            unitName: u.unitName.trim(),
            unitRent: u.unitRent.trim(),
            unitRentFrequency: u.unitRentFrequency.trim(),
            unitFloor: u.unitFloor,
            operationMode: u.operationMode.trim().toLowerCase() == 'rent'
                ? 'rent'
                : 'bnb',
            unitDescription: u.unitDescription.trim(),
            unitRentCurrency: u.unitRentCurrency.trim().isEmpty
                ? 'TZS'
                : u.unitRentCurrency.trim().toUpperCase(),
          ),
        )
        .toList()
      ..sort((a, b) {
        final c = a.unitName.toLowerCase().compareTo(b.unitName.toLowerCase());
        if (c != 0) return c;
        return a.unitId.toLowerCase().compareTo(b.unitId.toLowerCase());
      });
    return jsonEncode(copies.map((u) => u.toJson()).toList());
  }

  String _newApartmentUnitId({int? floor}) =>
      ApartmentUnitDraft.newRef(floor: floor);

  void _ensureApartmentUnitIds() {
    if (apartmentUnits.isEmpty) return;
    final next = <ApartmentUnitDraft>[];
    var changed = false;
    for (final u in apartmentUnits) {
      if (u.unitId.trim().isEmpty) {
        next.add(
          ApartmentUnitDraft(
            unitId: _newApartmentUnitId(floor: u.unitFloor),
            unitName: u.unitName,
            unitRent: u.unitRent,
            unitRentFrequency: u.unitRentFrequency,
            unitFloor: u.unitFloor,
            operationMode: u.operationMode.trim().toLowerCase() == 'rent'
                ? 'rent'
                : 'bnb',
            unitDescription: u.unitDescription,
            unitRentCurrency: u.unitRentCurrency.trim().isEmpty
                ? 'TZS'
                : u.unitRentCurrency.trim().toUpperCase(),
          ),
        );
        changed = true;
      } else {
        next.add(u);
      }
    }
    if (changed) apartmentUnits.assignAll(next);
  }

  void updateDraftUnitFloor(int? value) {
    if (value != null && PropertyUnitFloor.indices.contains(value)) {
      draftUnitFloor.value = value;
    }
  }

  void updateDraftUnitMode(String mode) {
    if (mode == draftUnitMode.value) return;
    draftUnitMode.value = mode;
  }

  String? validateDraftUnitRent(String? value) {
    if (apartmentUnits.isNotEmpty) return null;
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Unit rent is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  Future<void> pickCoverPhoto({required bool fromGallery}) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null && picked.path.isNotEmpty) {
        coverPhotoPath.value = picked.path;
      }
    } catch (e, st) {
      logger.e('EditListing cover pick $e $st');
      Get.snackbar(
        'Error',
        Get.locale?.languageCode == 'sw'
            ? 'Imeshindwa kufungua picha. Angalia ruhusa za kamera na gallery.'
            : 'Could not open the photo picker. Check camera and gallery permissions.',
      );
    }
  }

  void selectCoverPhoto(String path) {
    final next = path.trim();
    if (next.isEmpty) return;
    coverPhotoPath.value = next;
  }

  String? validatePropertyName(String? value) => PropertyNameRules.validate(
        value,
        isSw: Get.locale?.languageCode == 'sw',
      );

  void addApartmentUnit() {
    final name = draftUnitNameController.text.trim();
    final rent = draftUnitRentController.text.trim();
    if (name.isEmpty || rent.isEmpty) {
      Get.snackbar('Error', 'Unit name and rent are required');
      return;
    }
    if (!PlanAccess.canAddUnit(currentUnitCount: apartmentUnits.length)) return;
    omitStoredUnitList.value = false;
    final mode = draftUnitMode.value.trim().toLowerCase() == 'rent'
        ? 'rent'
        : 'bnb';
    final defaultFreq = mode == 'rent' ? 'Per Month' : 'Per Day';
    // Prefer mode-appropriate frequency — don't force listing BnB "Per Day"
    // onto a Rent unit (that makes it look like a BnB unit in filters).
    final listingFreq = _original?.rentFrequency.trim() ?? '';
    final frequency = mode == 'rent'
        ? (listingFreq.toLowerCase().contains('day') ||
                listingFreq.toLowerCase().contains('night')
            ? 'Per Month'
            : (_rentFrequencyOptions.contains(listingFreq)
                ? listingFreq
                : defaultFreq))
        : (_rentFrequencyOptions.contains(listingFreq)
            ? listingFreq
            : defaultFreq);
    apartmentUnits.add(
      ApartmentUnitDraft(
        unitId: _newApartmentUnitId(floor: draftUnitFloor.value),
        unitName: name,
        unitRent: rent,
        unitRentFrequency: frequency,
        unitFloor: draftUnitFloor.value,
        operationMode: mode,
        unitDescription: draftUnitDescriptionController.text.trim(),
        unitRentCurrency: Get.isRegistered<CurrencyService>()
            ? Get.find<CurrencyService>().baseCurrency.value
            : 'TZS',
      ),
    );
    draftUnitNameController.clear();
    draftUnitRentController.clear();
    draftUnitDescriptionController.clear();
    draftUnitFloor.value = PropertyUnitFloor.defaultIndex;
  }

  void removeApartmentUnit(int index) {
    if (index >= 0 && index < apartmentUnits.length) {
      apartmentUnits.removeAt(index);
    }
  }

  String _unitsJsonForSave() {
    if (apartmentUnits.isEmpty) return '';
    _ensureApartmentUnitIds();
    return jsonEncode(apartmentUnits.map((u) => u.toJson()).toList());
  }

  int _listedUnitCount() {
    if (apartmentUnits.isNotEmpty) return apartmentUnits.length;
    return 1;
  }

  Future<void> save() async {
    final orig = _original;
    if (orig == null) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final newLoc = propertyLocationController.text.trim();
    final newName = propertyNameController.text.trim();

    // If the draft form is filled but not yet added to the list, commit it.
    final draftName = draftUnitNameController.text.trim();
    final draftRent = draftUnitRentController.text.trim();
    if (draftName.isNotEmpty && draftRent.isNotEmpty) {
      addApartmentUnit();
    }

    if (apartmentUnits.isEmpty && !omitStoredUnitList.value) {
      Get.snackbar(
        'Error',
        Get.locale?.languageCode == 'sw'
            ? 'Ongeza angalau uniti moja'
            : 'Add at least one unit',
      );
      return;
    }

    final locChanged = newLoc != _snapLocation;
    final nameChanged = newName != _snapName;
    final unitsJsonOut = _unitsJsonForSave();
    final unitsCanonNow = _canonicalUnitsJsonFromDrafts(apartmentUnits);
    final unitsChanged = unitsCanonNow != _snapUnitsCanon;
    final coverNow = coverPhotoPath.value.trim();
    final coverChanged = coverNow.isNotEmpty && coverNow != _snapCover;

    if (!locChanged && !nameChanged && !unitsChanged && !coverChanged) {
      Get.back(result: false);
      return;
    }

    await runBusy(() async {
      try {
      final merged = PropertyRecord(
        id: orig.id,
        propertyLocation: locChanged ? newLoc : orig.propertyLocation,
        propertyName: nameChanged ? newName : orig.propertyName,
        propertyType: orig.propertyType,
        propertyRef: orig.propertyRef,
        tenants: orig.tenants,
        units: unitsChanged ? _listedUnitCount() : orig.units,
        ownerUserId: orig.ownerUserId,
        workspaceType: orig.workspaceType,
        createdAtMs: orig.createdAtMs,
        rentAmount: orig.rentAmount,
        rentFrequency: orig.rentFrequency,
        minRentalDuration: orig.minRentalDuration,
        unitsJson: unitsChanged ? unitsJsonOut : orig.unitsJson,
        floorCount: orig.floorCount,
        coverPhotoPath: coverChanged ? coverNow : orig.coverPhotoPath,
      );

      await _local.update(merged);

      final ref = orig.propertyRef.trim();
      if (ref.isNotEmpty && unitsChanged) {
        for (final alias in {'local_${orig.id}', 'legacy_${orig.id}'}) {
          if (alias != ref) await _unitLocal.deleteByPropertyRef(alias);
        }
        await syncPropertyUnitsForListingSave(
          unitLocal: _unitLocal,
          propertyRef: ref,
          isApartment: true,
          apartmentUnitMaps: apartmentUnits.map((u) => u.toJson()).toList(),
          minRentalDuration: orig.minRentalDuration,
          listingRentFrequency: orig.rentFrequency,
          listingRentRaw: orig.rentAmount,
          singleUnitName: merged.propertyName,
          rooms: 0,
          maxGuests: 0,
          listingMode: orig.workspaceType,
        );
      }
      if (ref.isNotEmpty) {

        // Push units/name/location to API so remote sync does not wipe local units.
        _syncPropertyUpdate(
          propertyRef: ref,
          location: merged.propertyLocation,
          name: merged.propertyName,
          type: merged.propertyType,
          units: merged.units,
          workspaceType: merged.workspaceType,
          rentAmount: merged.rentAmount,
          rentFrequency: merged.rentFrequency,
          minRentalDuration: merged.minRentalDuration,
          unitsJson: merged.unitsJson,
          floorCount: merged.floorCount,
          coverPhotoPath: merged.coverPhotoPath,
        );
      }

      Get.back(result: true);
      showSuccessWithHaptic('Property updated on this device');
    } catch (e, st) {
      logger.e('EditListing save $e $st');
      Get.snackbar('Error', 'Could not save changes');
    }
    });
  }

  /// Fire-and-forget: attempt backend update by propertyRef; fall back to offline queue.
  void _syncPropertyUpdate({
    required String propertyRef,
    required String location,
    required String name,
    required String type,
    required int units,
    required String workspaceType,
    required String rentAmount,
    required String rentFrequency,
    required String minRentalDuration,
    required String unitsJson,
    required int floorCount,
    required String coverPhotoPath,
  }) {
    final rent = PropertyRemoteRent.amount(
      unitCount: units,
      listingRentAmount: rentAmount,
      unitsJson: unitsJson,
    );
    final payload = {
      'property_ref': propertyRef,
      'location': location,
      'name': name,
      'type': type,
      'units': units,
      'workspace_type': workspaceType,
      'rent_amount': rent,
      'rent_frequency': PropertyRemoteRent.frequency(
        unitCount: units,
        listingRentFrequency: rentFrequency,
        unitsJson: unitsJson,
        rentAmount: rent,
      ),
      'min_rental_duration': minRentalDuration,
      'units_json': unitsJson,
      'floor_count': floorCount,
      'cover_photo_path': coverPhotoPath,
    };
    Future.microtask(() async {
      try {
        if (Get.isRegistered<TenantLocalDataSource>()) {
          payload['tenants'] = await Get.find<TenantLocalDataSource>()
              .countByPropertyRef(propertyRef);
        }
        final res = await _repository.updatePropertyByRef(propertyRef, payload);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'updatePropertyByRef failed');
      } catch (_) {
        try {
          await _syncQueue.enqueue(
            entityType: 'property',
            operation: 'update',
            payloadJson: jsonEncode(payload),
            dedupeKey: 'property:update:$propertyRef',
          );
          await _syncWorker.runNow(maxItems: 5);
        } catch (_) {}
      }
    });
  }

  @override
  void onClose() {
    propertyLocationController.dispose();
    propertyNameController.dispose();
    draftUnitNameController.dispose();
    draftUnitRentController.dispose();
    draftUnitDescriptionController.dispose();
    super.onClose();
  }
}

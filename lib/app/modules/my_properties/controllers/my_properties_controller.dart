import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/getx_instance_probe.dart';
import '../../../core/utils/property_listing_image_assigner.dart';
import '../../../core/utils/property_unit_count.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/deleted_properties_store.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/remote_account_sync_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';

class MyPropertiesController extends BaseController {
  final selectedFilterIndex = 0.obs;
  final filterLabels = ['All Listings', 'Active', 'Drafts', 'Archive'];

  /// Workspace mode filter: '' = all, 'bnb' = BnB + both, 'rent' = Rent + both
  final workspaceModeFilter = ''.obs;

  MyPropertiesController()
      : _repository =
            Get.find<AppRepository>(tag: (AppRepository).toString()),
        _local = Get.find<PropertyLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        _deleted = DeletedPropertiesStore();

  final AppRepository _repository;
  final PropertyLocalDataSource _local;
  final TenantLocalDataSource _tenantLocal;
  final PreferenceManager _preferenceManager;
  final DeletedPropertiesStore _deleted;

  /// Status sent to API for filter: null = all, ACTIVE, DRAFT, ARCHIVED.
  static const List<String?> _filterStatuses = [null, 'ACTIVE', 'DRAFT', 'ARCHIVED'];

  final properties = <PropertyListing>[].obs;
  final loading = false.obs;

  /// Properties after applying workspaceModeFilter on top of the status filter.
  List<PropertyListing> get displayProperties {
    final ws = workspaceModeFilter.value;
    if (ws.isEmpty) return properties;
    return properties
        .where((p) => p.mode == ws || p.mode == 'both')
        .toList();
  }

  @override
  void onReady() {
    super.onReady();
    // Accept an initial workspace filter from navigation arguments.
    final args = Get.arguments;
    if (args is Map) {
      final ws = (args['workspaceFilter'] as String? ?? '').toLowerCase();
      if (ws == 'bnb' || ws == 'rent') {
        workspaceModeFilter.value = ws;
      }
    }
    loadProperties();
  }

  void setWorkspaceFilter(String ws) {
    workspaceModeFilter.value = ws.toLowerCase();
  }

  /// Immediately drops matching cards from the in-memory list (before reload).
  void removePropertyFromList(Iterable<String> ids) {
    final keys = ids.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (keys.isEmpty) return;
    properties.assignAll(
      properties.where((p) => !keys.contains(p.id)).toList(),
    );
  }

  static Future<void> refreshIfRegistered() async {
    if (!GetxInstanceProbe.isAlive<MyPropertiesController>()) return;
    await Get.find<MyPropertiesController>().loadProperties();
  }

  static void removeIfRegistered(Iterable<String> ids) {
    if (!GetxInstanceProbe.isAlive<MyPropertiesController>()) return;
    Get.find<MyPropertiesController>().removePropertyFromList(ids);
  }

  /// Fetches properties from service by current filter (All / Active / Drafts / Archive).
  Future<void> loadProperties() async {
    loading.value = true;
    final status = _filterStatuses[selectedFilterIndex.value];
    final deleted = _deleted.load();
    try {
      if (Get.isRegistered<RemoteAccountSyncService>()) {
        await Get.find<RemoteAccountSyncService>().syncPropertiesFromRemote();
      }
      final localList = await _loadLocalListings(status: status);
      final res = await _repository.getMyListings(status: status);
      final data = res.data;
      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['content'] is List) {
        rawList = data['content'] as List;
      } else if (data is Map && data['listings'] is List) {
        rawList = data['listings'] as List;
      }
      var maps = rawList.whereType<Map<String, dynamic>>().toList();
      if (status != null && status.isNotEmpty) {
        maps = maps.where((m) {
          final s = (m['status'] as String?)?.toUpperCase();
          return s == status;
        }).toList();
      }
      final remoteList = (await Future.wait(
              maps.map(_listingFromMap),
            ))
          .where((e) => e.id.isNotEmpty && !deleted.contains(e.id))
          .toList();
      properties.assignAll(
        _mergeListings(localList, remoteList)
            .where((p) => !deleted.contains(p.id))
            .where((p) {
              if (status == null || status.isEmpty) return true;
              return p.status == PropertyRecord.normalizeListingStatus(status);
            })
            .toList(),
      );
    } catch (e) {
      // Fall back to local rows so screen stays useful offline / API failure.
      final localList = await _loadLocalListings(status: status);
      properties.assignAll(
        localList.where((p) => !deleted.contains(p.id)).toList(),
      );
      Get.snackbar('Error', 'Could not load properties');
    } finally {
      loading.value = false;
    }
  }

  Future<List<PropertyListing>> _loadLocalListings({
    required String? status,
  }) async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final deleted = _deleted.load();
    final rowsByKey = <String, PropertyRecord>{};
    for (final workspace in const ['bnb', 'rent']) {
      final rows = await _local.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: workspace,
      );
      for (final row in rows) {
        final key = row.propertyRef.trim().isNotEmpty
            ? row.propertyRef.trim()
            : 'local_${row.id}';
        if (deleted.contains(key) || deleted.contains('local_${row.id}')) {
          continue;
        }
        final existing = rowsByKey[key];
        if (existing == null ||
            PropertyUnitCount.of(row) > PropertyUnitCount.of(existing)) {
          rowsByKey[key] = row;
        }
      }
    }
    final local = await Future.wait(rowsByKey.values.map(_listingFromLocal));
    if (status == null || status.isEmpty) return local;
    final want = PropertyRecord.normalizeListingStatus(status);
    return local.where((p) => p.status == want).toList();
  }

  Future<PropertyListing> _listingFromLocal(PropertyRecord r) async {
    final title = r.propertyName.trim().isNotEmpty
        ? r.propertyName.trim()
        : (r.propertyLocation.trim().isNotEmpty
            ? r.propertyLocation.trim()
            : 'Property');
    final id = r.propertyRef.trim().isNotEmpty
        ? r.propertyRef.trim()
        : 'local_${r.id}';
    final tenants = await _tenantLocal.countByPropertyRef(id);
    return PropertyListing(
      id: id,
      title: title,
      rating: 0,
      location: r.propertyLocation,
      activeTenants: tenants,
      unitSlots: PropertyUnitCount.of(r),
      mode: _normalizeListingMode(r.workspaceType),
      isFavorite: false,
      imageUrl: PropertyListingImageAssigner.resolveDisplayPath(
        storedPath: r.coverPhotoPath,
        propertyRef: id,
        localPropertyId: r.id,
        propertyName: title,
      ),
      status: PropertyRecord.normalizeListingStatus(r.listingStatus),
      localRowId: r.id,
    );
  }

  static List<PropertyListing> _mergeListings(
    List<PropertyListing> local,
    List<PropertyListing> remote,
  ) {
    final byId = <String, PropertyListing>{};
    for (final item in local) {
      byId[item.id] = item;
    }
    for (final item in remote) {
      final existing = byId[item.id];
      if (existing == null) {
        byId[item.id] = item;
        continue;
      }
      byId[item.id] = PropertyListing(
        id: item.id,
        title: item.title,
        rating: item.rating,
        location: item.location,
        activeTenants: item.activeTenants,
        unitSlots: item.unitSlots > 0 ? item.unitSlots : existing.unitSlots,
        mode: item.mode,
        isFavorite: item.isFavorite,
        imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : existing.imageUrl,
        // Local lifecycle (Draft/Archive) wins: the API often omits status or
        // always returns ACTIVE, which would otherwise revert a just-changed card.
        status: existing.status,
        statusSource: existing.statusSource,
        localRowId: existing.localRowId ?? item.localRowId,
      );
    }
    return byId.values.toList();
  }

  Future<PropertyListing> _listingFromMap(Map<String, dynamic> m) async {
    final id = m['id']?.toString() ?? m['listingId']?.toString() ?? '';
    final title =
        m['propertyName']?.toString() ?? m['title']?.toString() ?? 'Property';
    final rating = (m['rating'] as num?)?.toDouble() ?? 0.0;
    final location =
        m['propertyLocation']?.toString() ?? m['location']?.toString() ?? '';
    final tenants = await _tenantLocal.countByPropertyRef(id);
    final remoteUnits = (m['units'] as num?)?.toInt() ?? 0;
    final remoteUnitsJson =
        (m['units_json'] ?? m['unitsJson'] ?? '').toString();
    var mode = _normalizeListingMode(
      m['workspaceType'] ?? m['listingMode'] ?? m['operationMode'],
    );
    var imageUrl = m['coverPhotoUrl']?.toString() ??
        m['coverPhoto']?.toString() ??
        m['imageUrl']?.toString() ??
        '';
    imageUrl = imageUrl.trim();
    final rawStatus = m['status']?.toString() ?? m['listingStatus']?.toString();
    final hasRemoteStatus =
        rawStatus != null && rawStatus.trim().isNotEmpty;
    var status = hasRemoteStatus
        ? PropertyRecord.normalizeListingStatus(rawStatus)
        : PropertyRecord.listingStatusActive;
    int? localRowId;
    var units = remoteUnits;
    if (units <= 0 && remoteUnitsJson.trim().isNotEmpty) {
      units = PropertyUnitCount.fromUnitsJson(remoteUnitsJson);
    }
    final localRow = id.isEmpty ? null : await _local.findByHubId(id);
    if (localRow != null) {
      localRowId = localRow.id;
      mode = _normalizeListingMode(localRow.workspaceType);
      // Prefer local structured count when remote payload is thin.
      final localUnits = PropertyUnitCount.of(localRow);
      if (units <= 0 && localUnits > 0) {
        units = localUnits;
      }
      if (imageUrl.isEmpty) {
        imageUrl = PropertyListingImageAssigner.resolveDisplayPath(
          storedPath: localRow.coverPhotoPath,
          propertyRef: localRow.propertyRef,
          localPropertyId: localRow.id,
          propertyName: title,
        );
      }
      status = PropertyRecord.normalizeListingStatus(localRow.listingStatus);
    } else if (id.isNotEmpty && imageUrl.isEmpty) {
      imageUrl =
          PropertyListingImageAssigner.assignForProperty(propertyRef: id);
    }
    return PropertyListing(
      id: id,
      title: title,
      rating: rating,
      location: location,
      activeTenants: tenants,
      unitSlots: units,
      mode: mode,
      isFavorite: false,
      imageUrl: imageUrl,
      status: status,
      statusSource: hasRemoteStatus ? 'remote' : 'local',
      localRowId: localRowId,
    );
  }

  static String _normalizeListingMode(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    if (value == 'rent') return 'rent';
    if (value == 'both') return 'both';
    return 'bnb';
  }

  void selectFilter(int index) {
    if (selectedFilterIndex.value == index) return;
    selectedFilterIndex.value = index;
    loadProperties();
  }

  void toggleFavorite(PropertyListing p) {
    final i = properties.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      final updated = p.copyWith(isFavorite: !p.isFavorite);
      properties.value = [
        ...properties.take(i),
        updated,
        ...properties.skip(i + 1),
      ];
    }
  }

  Future<void> setListingStatus(
    PropertyListing p,
    String status,
  ) async {
    final next = PropertyRecord.normalizeListingStatus(status);
    if (p.status == next) return;

    try {
      _applyStatusInMemory(p.id, next);

      if (p.localRowId != null) {
        await _local.updateListingStatus(
          id: p.localRowId!,
          listingStatus: next,
        );
      } else {
        final byRef = await _local.updateListingStatusByRef(
          propertyRef: p.id,
          listingStatus: next,
        );
        if (byRef == null && p.id.startsWith('local_')) {
          final id = int.tryParse(p.id.replaceFirst('local_', ''));
          if (id != null) {
            await _local.updateListingStatus(id: id, listingStatus: next);
          }
        }
      }

      if (!p.id.startsWith('local_')) {
        try {
          await _repository.updatePropertyByRef(p.id, {
            'status': next,
            'listingStatus': next,
            'listing_status': next,
          });
        } catch (_) {
          // Local status still applies when offline / API unavailable.
        }
      }

      final isSw = Get.locale?.languageCode == 'sw';
      final label = switch (next) {
        PropertyRecord.listingStatusDraft =>
          isSw ? 'Rasimu' : 'Draft',
        PropertyRecord.listingStatusArchived =>
          isSw ? 'Hifadhi' : 'Archive',
        _ => isSw ? 'Hai' : 'Active',
      };
      showSuccessMessage(
        isSw ? 'Mali imewekwa kama $label' : 'Property marked as $label',
      );
      await loadProperties();
    } catch (e) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Imeshindikana kubadilisha hali ya mali.'
            : 'Could not update property status.',
      );
    }
  }

  void _applyStatusInMemory(String id, String status) {
    final i = properties.indexWhere((e) => e.id == id);
    if (i < 0) return;
    properties[i] = properties[i].copyWith(
      status: status,
      statusSource: 'local',
    );
    properties.refresh();
  }

  Future<void> deleteProperty(PropertyListing p) async {
    final isSw = Get.locale?.languageCode == 'sw';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(isSw ? 'Futa mali?' : 'Delete property?'),
        content: Text(
          isSw
              ? 'Hii itafuta "${p.title}" na rekodi zake kwenye kifaa hiki. Hatua hii haiwezi kutenduliwa.'
              : 'This will remove "${p.title}" and its saved details from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(isSw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(isSw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (confirmed != true) return;

    try {
      final ids = <String>{
        if (p.id.trim().isNotEmpty) p.id.trim(),
        if (p.localRowId != null) 'local_${p.localRowId}',
      };
      await _deleted.markDeleted(ids);

      if (p.localRowId != null) {
        await _local.deleteById(p.localRowId!);
      } else {
        final row = await _local.findByHubId(p.id);
        if (row != null) {
          ids.add('local_${row.id}');
          if (row.propertyRef.trim().isNotEmpty) {
            ids.add(row.propertyRef.trim());
          }
          await _deleted.markDeleted(ids);
          await _local.deleteById(row.id);
        }
      }

      removePropertyFromList(ids);

      if (!p.id.startsWith('local_')) {
        try {
          final parsed = int.tryParse(p.id);
          if (parsed != null) {
            await _repository.deleteProperty(parsed);
          } else {
            await _repository.updatePropertyByRef(p.id, {
              'status': 'DELETED',
              'listingStatus': 'DELETED',
            });
          }
        } catch (_) {
          // Tombstone keeps it hidden until a later remote delete succeeds.
        }
      }

      showSuccessMessage(isSw ? 'Mali imefutwa.' : 'Property deleted.');
      await HomeController.refreshIfRegistered();
    } catch (_) {
      showErrorMessage(
        isSw ? 'Imeshindikana kufuta mali.' : 'Could not delete property.',
      );
    }
  }

  Future<void> manageProperty(PropertyListing p) async {
    final result = await Get.toNamed(
      Routes.LISTING_DETAILS,
      arguments: {
        'property_id': p.id,
        'property_name': p.title,
        'property_location': p.location,
        'property_image': p.imageUrl,
      },
    );
    if (result == true) {
      await loadProperties();
    }
  }

  Future<void> addProperty() async {
    await Get.toNamed(Routes.ADD_LISTING);
    await loadProperties();
  }
}

class PropertyListing {
  final String id;
  final String title;
  final double rating;
  final String location;
  final int activeTenants;
  final int unitSlots;
  /// Property operation mode: `bnb`, `rent`, or `both`.
  final String mode;
  final bool isFavorite;
  final String imageUrl;
  /// Lifecycle status: ACTIVE, DRAFT, or ARCHIVED.
  final String status;
  /// `remote` when status came from API; otherwise `local`.
  final String statusSource;
  final int? localRowId;

  PropertyListing({
    required this.id,
    required this.title,
    required this.rating,
    required this.location,
    required this.activeTenants,
    required this.unitSlots,
    required this.mode,
    required this.isFavorite,
    required this.imageUrl,
    this.status = PropertyRecord.listingStatusActive,
    this.statusSource = 'local',
    this.localRowId,
  });

  PropertyListing copyWith({
    bool? isFavorite,
    String? status,
    String? statusSource,
    int? localRowId,
  }) {
    return PropertyListing(
      id: id,
      title: title,
      rating: rating,
      location: location,
      activeTenants: activeTenants,
      unitSlots: unitSlots,
      mode: mode,
      isFavorite: isFavorite ?? this.isFavorite,
      imageUrl: imageUrl,
      status: status ?? this.status,
      statusSource: statusSource ?? this.statusSource,
      localRowId: localRowId ?? this.localRowId,
    );
  }
}

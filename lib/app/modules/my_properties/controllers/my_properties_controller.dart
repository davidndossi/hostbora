import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/property_listing_image_assigner.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/remote_account_sync_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

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
        );

  final AppRepository _repository;
  final PropertyLocalDataSource _local;
  final TenantLocalDataSource _tenantLocal;
  final PreferenceManager _preferenceManager;

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

  /// Fetches properties from service by current filter (All / Active / Drafts / Archive).
  Future<void> loadProperties() async {
    loading.value = true;
    final status = _filterStatuses[selectedFilterIndex.value];
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
          .where((e) => e.id.isNotEmpty)
          .toList();
      properties.assignAll(_mergeListings(localList, remoteList));
    } catch (e) {
      // Fall back to local rows so screen stays useful offline / API failure.
      final localList = await _loadLocalListings(status: status);
      properties.assignAll(localList);
      Get.snackbar('Error', 'Could not load properties');
    } finally {
      loading.value = false;
    }
  }

  Future<List<PropertyListing>> _loadLocalListings({
    required String? status,
  }) async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
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
        rowsByKey[key] = row;
      }
    }
    final local = await Future.wait(rowsByKey.values.map(_listingFromLocal));
    if (status == null) return local;
    if (status == 'ACTIVE') {
      return local;
    }
    // Local table does not currently persist DRAFT / ARCHIVED status.
    return const [];
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
    final units = r.units;
    return PropertyListing(
      id: id,
      title: title,
      rating: 0,
      location: r.propertyLocation,
      // pricePerNight: price,
      activeTenants: tenants,
      unitSlots: units,
      mode: _normalizeListingMode(r.workspaceType),
      isFavorite: false,
      imageUrl: PropertyListingImageAssigner.resolveDisplayPath(
        storedPath: r.coverPhotoPath,
        propertyRef: id,
        localPropertyId: r.id,
        propertyName: title,
      ),
    );
  }

  static List<PropertyListing> _mergeListings(
    List<PropertyListing> local,
    List<PropertyListing> remote,
  ) {
    final byId = <String, PropertyListing>{};
    // Keep remote as source of truth when same id exists.
    for (final item in local) {
      byId[item.id] = item;
    }
    for (final item in remote) {
      byId[item.id] = item;
    }
    return byId.values.toList();
  }

  Future<PropertyListing> _listingFromMap(Map<String, dynamic> m) async {
    final id = m['id']?.toString() ?? m['listingId']?.toString() ?? '';
    final title = m['propertyName']?.toString() ?? m['title']?.toString() ?? 'Property';
    final rating = (m['rating'] as num?)?.toDouble() ?? 0.0;
    final location = m['propertyLocation']?.toString() ?? m['location']?.toString() ?? '';
    final tenants = await _tenantLocal.countByPropertyRef(id);
    final units = (m['units'] as num?)?.toInt() ?? 0;
    var mode = _normalizeListingMode(
      m['workspaceType'] ?? m['listingMode'] ?? m['operationMode'],
    );
    var imageUrl = m['coverPhotoUrl']?.toString() ??
        m['coverPhoto']?.toString() ??
        m['imageUrl']?.toString() ??
        '';
    imageUrl = imageUrl.trim();
    if (imageUrl.isEmpty) {
      final localRow = await _local.findByHubId(id);
      if (localRow != null) {
        mode = _normalizeListingMode(localRow.workspaceType);
        imageUrl = PropertyListingImageAssigner.resolveDisplayPath(
          storedPath: localRow.coverPhotoPath,
          propertyRef: localRow.propertyRef,
          localPropertyId: localRow.id,
          propertyName: title,
        );
      } else if (id.isNotEmpty) {
        imageUrl = PropertyListingImageAssigner.assignForProperty(propertyRef: id);
      }
    }
    return PropertyListing(
      id: id,
      title: title,
      rating: rating,
      location: location,
      // pricePerNight: price,
      activeTenants: tenants,
      unitSlots: units,
      mode: mode,
      isFavorite: false,
      imageUrl: imageUrl,
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
      final updated = PropertyListing(
        id: p.id,
        title: p.title,
        rating: p.rating,
        location: p.location,
        // pricePerNight: p.pricePerNight,
        activeTenants: p.activeTenants,
        unitSlots: p.unitSlots,
        mode: p.mode,
        isFavorite: !p.isFavorite,
        imageUrl: p.imageUrl,
      );
      properties.value = [
        ...properties.take(i),
        updated,
        ...properties.skip(i + 1),
      ];
    }
  }

  void manageProperty(PropertyListing p) {
    Get.toNamed(
      Routes.LISTING_DETAILS,
      arguments: {
        'property_id': p.id,
        'property_name': p.title,
        'property_location': p.location,
        // 'property_price': p.pricePerNight,
        'property_image': p.imageUrl,
      },
    );
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
  // final int pricePerNight;
  final int activeTenants;
  final int unitSlots;
  /// Property operation mode: `bnb`, `rent`, or `both`.
  final String mode;
  final bool isFavorite;
  final String imageUrl;

  PropertyListing({
    required this.id,
    required this.title,
    required this.rating,
    required this.location,
    // required this.pricePerNight,
    required this.activeTenants,
    required this.unitSlots,
    required this.mode,
    required this.isFavorite,
    required this.imageUrl,
  });
}

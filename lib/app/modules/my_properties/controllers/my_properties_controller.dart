import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class MyPropertiesController extends BaseController {
  final selectedFilterIndex = 0.obs;
  final filterLabels = ['All Listings', 'Active', 'Drafts', 'Archive'];

  MyPropertiesController()
      : _repository =
            Get.find<AppRepository>(tag: (AppRepository).toString()),
        _local = Get.find<PropertyLocalDataSource>();

  final AppRepository _repository;
  final PropertyLocalDataSource _local;

  /// Status sent to API for filter: null = all, ACTIVE, DRAFT, ARCHIVED.
  static const List<String?> _filterStatuses = [null, 'ACTIVE', 'DRAFT', 'ARCHIVED'];

  final properties = <PropertyListing>[].obs;
  final loading = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadProperties();
  }

  /// Fetches properties from service by current filter (All / Active / Drafts / Archive).
  Future<void> loadProperties() async {
    loading.value = true;
    final status = _filterStatuses[selectedFilterIndex.value];
    try {
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
      final remoteList =
          maps.map(_listingFromMap).where((e) => e.id.isNotEmpty).toList();
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
    final rows = await _local.getAllNewestFirst();
    final local = rows.map(_listingFromLocal).toList();
    if (status == null) return local;
    if (status == 'ACTIVE') {
      return local;
    }
    // Local table does not currently persist DRAFT / ARCHIVED status.
    return const [];
  }

  static PropertyListing _listingFromLocal(PropertyRecord r) {
    final title = r.propertyName.trim().isNotEmpty
        ? r.propertyName.trim()
        : (r.propertyLocation.trim().isNotEmpty
            ? r.propertyLocation.trim()
            : 'Property');
    // final price = int.tryParse(r.rentAmount.replaceAll(',', '').trim()) ?? 0;
    final id = r.propertyRef.trim().isNotEmpty
        ? r.propertyRef.trim()
        : 'local_${r.id}';
    final tenants = (r.tenants as num?)?.toInt() ?? 0;
    final units = (r.units as num?)?.toInt() ?? 0;
    return PropertyListing(
      id: id,
      title: title,
      rating: 0,
      location: r.propertyLocation,
      // pricePerNight: price,
      activeTenants: tenants,
      unitSlots: units,
      status: PropertyStatus.ready,
      isFavorite: false,
      imageUrl: '',
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

  static PropertyListing _listingFromMap(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? m['listingId']?.toString() ?? '';
    final title = m['propertyName']?.toString() ?? m['title']?.toString() ?? 'Property';
    final rating = (m['rating'] as num?)?.toDouble() ?? 0.0;
    final location = m['propertyLocation']?.toString() ?? m['location']?.toString() ?? '';
    // final price = (m['baseNightlyRate'] as num?)?.toInt() ?? 0;
    final tenants = (m['tenants'] as num?)?.toInt() ?? 0;
    final units = (m['units'] as num?)?.toInt() ?? 0;
    final statusStr = (m['status'] as String?)?.toUpperCase() ?? 'ACTIVE';
    final status = statusStr == 'CLEANING' ? PropertyStatus.cleaning : PropertyStatus.ready;
    final imageUrl = m['coverPhotoUrl']?.toString() ?? m['coverPhoto']?.toString() ?? m['imageUrl']?.toString() ?? '';
    return PropertyListing(
      id: id,
      title: title,
      rating: rating,
      location: location,
      // pricePerNight: price,
      activeTenants: tenants,
      unitSlots: units,
      status: status,
      isFavorite: false,
      imageUrl: imageUrl,
    );
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
        status: p.status,
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

enum PropertyStatus { ready, cleaning }

class PropertyListing {
  final String id;
  final String title;
  final double rating;
  final String location;
  // final int pricePerNight;
  final int activeTenants;
  final int unitSlots;
  final PropertyStatus status;
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
    required this.status,
    required this.isFavorite,
    required this.imageUrl,
  });
}

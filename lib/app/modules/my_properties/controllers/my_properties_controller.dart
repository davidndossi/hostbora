import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class MyPropertiesController extends BaseController {
  final selectedFilterIndex = 0.obs;
  final filterLabels = ['All Listings', 'Active', 'Drafts', 'Archive'];

  MyPropertiesController() : _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final AppRepository _repository;

  /// Status sent to API for filter: null = all, ACTIVE, DRAFT, ARCHIVED.
  static const List<String?> _filterStatuses = [null, 'ACTIVE', 'DRAFT', 'ARCHIVED'];

  // final properties = <PropertyListing>[
  //   PropertyListing(
  //     id: '1',
  //     title: 'Azure Coastal Villa',
  //     rating: 4.9,
  //     location: 'Malibu, California',
  //     pricePerNight: 450,
  //     status: PropertyStatus.ready,
  //     isFavorite: true,
  //     imageUrl: 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
  //   ),
  //   PropertyListing(
  //     id: '2',
  //     title: 'Manhattan Urban Loft',
  //     rating: 4.7,
  //     location: 'Downtown NY, New York',
  //     pricePerNight: 210,
  //     status: PropertyStatus.cleaning,
  //     isFavorite: false,
  //     imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
  //   ),
  //   PropertyListing(
  //     id: '3',
  //     title: 'Aspen Peaks Cabin',
  //     rating: 5.0,
  //     location: 'Aspen, Colorado',
  //     pricePerNight: 600,
  //     status: PropertyStatus.ready,
  //     isFavorite: false,
  //     imageUrl: 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800',
  //   ),
  // ].obs;
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
    try {
      final status = _filterStatuses[selectedFilterIndex.value];
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
      final list = maps.map(_listingFromMap).where((e) => e.id.isNotEmpty).toList();
      properties.assignAll(list);
    } catch (e) {
      properties.clear();
      Get.snackbar('Error', 'Could not load properties');
    } finally {
      loading.value = false;
    }
  }

  static PropertyListing _listingFromMap(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? m['listingId']?.toString() ?? '';
    final title = m['propertyName']?.toString() ?? m['title']?.toString() ?? 'Property';
    final rating = (m['rating'] as num?)?.toDouble() ?? 0.0;
    final location = m['streetAddress']?.toString() ?? m['location']?.toString() ?? '';
    final price = (m['baseNightlyRate'] as num?)?.toInt() ?? 0;
    final statusStr = (m['status'] as String?)?.toUpperCase() ?? 'ACTIVE';
    final status = statusStr == 'CLEANING' ? PropertyStatus.cleaning : PropertyStatus.ready;
    final imageUrl = m['coverPhotoUrl']?.toString() ?? m['coverPhoto']?.toString() ?? m['imageUrl']?.toString() ?? '';
    return PropertyListing(
      id: id,
      title: title,
      rating: rating,
      location: location,
      pricePerNight: price,
      status: status,
      isFavorite: false,
      imageUrl: imageUrl,
    );
  }

  void openDrawer() {
    // TODO: open drawer / menu
  }

  void openSearch() {
    // TODO: open search
  }

  void openFilter() {
    // TODO: open filter
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
        pricePerNight: p.pricePerNight,
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
      Routes.ADD_LISTING,
      arguments: {
        'listing_id': p.id,
        'listing_data': {
          'propertyName': p.title,
          'streetAddress': p.location,
          'baseNightlyRate': p.pricePerNight,
        },
      },
    );
  }

  void addProperty() => Get.toNamed(Routes.ADD_LISTING);
}

enum PropertyStatus { ready, cleaning }

class PropertyListing {
  final String id;
  final String title;
  final double rating;
  final String location;
  final int pricePerNight;
  final PropertyStatus status;
  final bool isFavorite;
  final String imageUrl;

  PropertyListing({
    required this.id,
    required this.title,
    required this.rating,
    required this.location,
    required this.pricePerNight,
    required this.status,
    required this.isFavorite,
    required this.imageUrl,
  });
}

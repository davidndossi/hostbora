import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../../routes/app_pages.dart';

/// Property row for the concierge management hub cards (separate from [my_properties] models).
class RentHubPropertyRow {
  const RentHubPropertyRow({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.propertyTypeLabel,
    required this.activeTenants,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String propertyTypeLabel;
  final int activeTenants;
}

class RentMyPropertiesHubController extends BaseController {
  RentMyPropertiesHubController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final AppRepository _repository;

  final properties = <RentHubPropertyRow>[].obs;
  final loading = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadProperties();
  }

  Future<void> loadProperties() async {
    loading.value = true;
    try {
      final res = await _repository.getMyListings(status: null);
      final data = res.data;
      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['content'] is List) {
        rawList = data['content'] as List;
      } else if (data is Map && data['listings'] is List) {
        rawList = data['listings'] as List;
      }
      final maps = rawList.whereType<Map<String, dynamic>>().toList();
      final list = maps.map(_rowFromMap).where((e) => e.id.isNotEmpty).toList();
      properties.assignAll(list);
    } catch (e) {
      properties.clear();
      Get.snackbar('Error', 'Could not load properties');
    } finally {
      loading.value = false;
    }
  }

  static RentHubPropertyRow _rowFromMap(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? m['listingId']?.toString() ?? '';
    final title = m['propertyName']?.toString() ?? m['title']?.toString() ?? 'Property';
    final imageUrl = m['coverPhotoUrl']?.toString() ?? m['coverPhoto']?.toString() ?? m['imageUrl']?.toString() ?? '';
    final propertyTypeLabel =
        (m['propertyType'] ?? m['propertyCategory'] ?? m['category'])?.toString().toUpperCase() ?? 'PROPERTY';
    final activeTenants = (m['activeTenants'] as num?)?.toInt() ?? (m['tenantCount'] as num?)?.toInt() ?? 0;
    return RentHubPropertyRow(
      id: id,
      title: title,
      imageUrl: imageUrl,
      propertyTypeLabel: propertyTypeLabel,
      activeTenants: activeTenants,
    );
  }

  void addProperty() => Get.toNamed(Routes.ADD_LISTING);
}

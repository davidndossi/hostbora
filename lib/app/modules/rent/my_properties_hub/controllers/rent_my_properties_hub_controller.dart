import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_property_local_data_source.dart';
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
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _localRent = Get.find<RentPropertyLocalDataSource>();

  final AppRepository _repository;
  final RentPropertyLocalDataSource _localRent;

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
      final localRecords = await _localRent.getAllNewestFirst();
      final localRows = localRecords.map(_rowFromLocal).toList();

      List<RentHubPropertyRow> remoteRows = [];
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
        remoteRows = maps.map(_rowFromMap).where((e) => e.id.isNotEmpty).toList();
      } catch (_) {
        // Offline or API failure: still show SQLite properties.
      }
      properties.assignAll([...localRows, ...remoteRows]);
    } catch (e) {
      properties.clear();
      Get.snackbar('Error', 'Could not load properties');
    } finally {
      loading.value = false;
    }
  }

  static RentHubPropertyRow _rowFromLocal(RentPropertyRecord r) {
    final loc = r.propertyLocation.trim();
    final suite = r.apartmentSuite.trim();
    final title = suite.isNotEmpty ? '$loc · $suite' : (loc.isNotEmpty ? loc : 'Property');
    return RentHubPropertyRow(
      id: 'local_${r.id}',
      title: title,
      imageUrl: '',
      propertyTypeLabel: r.propertyType.toUpperCase(),
      activeTenants: 0,
    );
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

  void addProperty() {
    final future = Get.toNamed(Routes.RENT_ADD_NEW_LISTING);
    future?.then((value) {
      if (value == true) {
        loadProperties();
      }
    });
  }
}

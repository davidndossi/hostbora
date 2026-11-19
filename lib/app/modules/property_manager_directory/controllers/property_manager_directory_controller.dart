import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/property_manager.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class PropertyManagerDirectoryController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final directory = Rxn<PropertyManagerDirectory>();
  final loading = false.obs;
  final location = ''.obs;
  final propertyType = ''.obs;
  final properties = ''.obs;

  bool get isSw => Get.locale?.languageCode == 'sw';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading(true);
    try {
      final response = await _repository.getPropertyManagers(
        location: location.value.isEmpty ? null : location.value,
        propertyType: propertyType.value.isEmpty ? null : propertyType.value,
        properties: properties.value.isEmpty ? null : properties.value,
      );
      final data = response.data;
      if (response.isSuccess && data is Map) {
        directory(PropertyManagerDirectory.fromJson(Map<String, dynamic>.from(data)));
      }
    } catch (_) {
      showErrorMessage(
        isSw ? 'Imeshindikana kupakia orodha ya wasimamizi.' : 'Could not load property managers.',
      );
    } finally {
      loading(false);
    }
  }

  Future<void> setLocation(String? key) async {
    location(key ?? '');
    await load();
  }

  Future<void> setPropertyType(String? key) async {
    propertyType(key ?? '');
    await load();
  }

  Future<void> setProperties(String? key) async {
    properties(key ?? '');
    await load();
  }

  void openProfile(PropertyManager manager) {
    Get.toNamed(Routes.PROPERTY_MANAGER_PROFILE, arguments: manager.id);
  }
}

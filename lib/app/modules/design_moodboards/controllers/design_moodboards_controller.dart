import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';

enum MoodboardFilter { all, aiConcepts, materials }

class MoodboardListItem {
  MoodboardListItem({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.savedCount,
    required this.showAiBadge,
    required this.aiConcept,
    required this.materials,
  });

  final String id;
  final String title;
  final String assetPath;
  final int savedCount;
  final bool showAiBadge;
  final bool aiConcept;
  final bool materials;

  bool matches(MoodboardFilter f) {
    switch (f) {
      case MoodboardFilter.all:
        return true;
      case MoodboardFilter.aiConcepts:
        return aiConcept;
      case MoodboardFilter.materials:
        return materials;
    }
  }
}

class DesignMoodboardsController extends BaseController {
  final filter = MoodboardFilter.all.obs;

  final items = <MoodboardListItem>[
    MoodboardListItem(
      id: '1',
      title: 'Mediterranean Vibes',
      assetPath: 'images/mediterranean_vibes.jpg',
      savedCount: 12,
      showAiBadge: true,
      aiConcept: true,
      materials: false,
    ),
    MoodboardListItem(
      id: '2',
      title: 'Victorian Suite',
      assetPath: 'images/victorian_suite.jpg',
      savedCount: 12,
      showAiBadge: false,
      aiConcept: false,
      materials: true,
    ),
    MoodboardListItem(
      id: '3',
      title: 'Modern Minimalist',
      assetPath: 'images/modern_minimalist.jpg',
      savedCount: 8,
      showAiBadge: true,
      aiConcept: true,
      materials: false,
    ),
    MoodboardListItem(
      id: '4',
      title: 'Scandinavian Cozy',
      assetPath: 'images/scandinavian_cozy.jpg',
      savedCount: 15,
      showAiBadge: false,
      aiConcept: false,
      materials: true,
    ),
    MoodboardListItem(
      id: '5',
      title: 'Industrial Loft',
      assetPath: 'images/industrial_loft.jpg',
      savedCount: 9,
      showAiBadge: false,
      aiConcept: false,
      materials: true,
    ),
    MoodboardListItem(
      id: '6',
      title: 'Bohemian Desert',
      assetPath: 'images/bohemian_desert.jpg',
      savedCount: 11,
      showAiBadge: true,
      aiConcept: true,
      materials: false,
    ),
  ];

  List<MoodboardListItem> get filteredItems {
    final f = filter.value;
    return items.where((e) => e.matches(f)).toList();
  }

  void setFilter(MoodboardFilter f) => filter.value = f;

  void openMoodboardDetail(MoodboardListItem item) {
    Get.toNamed(Routes.DESIGN_MOODBOARD, arguments: item.title);
  }

  void createNewMoodboard() {
    Get.toNamed(Routes.INTERIOR_DESIGN_STUDIO);
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/help/guided_tour_service.dart';
import '../../../data/help/help_center_catalog.dart';
import '../../../data/help/help_center_models.dart';
import '../../../data/help/help_navigation_helper.dart';
import '../../../routes/app_pages.dart';

class HelpCenterController extends BaseController {
  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final workspaceFilter = HelpWorkspace.both.obs;
  final selectedTab = 0.obs;

  bool get isSw => Get.locale?.languageCode == 'sw';

  List<HelpGuide> get guides => _filterGuides(HelpCenterCatalog.guides);

  List<HelpFeature> get features => _filterFeatures(HelpCenterCatalog.features);

  List<HelpGuide> get tourGuides =>
      guides.where((g) => g.steps.isNotEmpty).toList(growable: false);

  Map<String, List<HelpFeature>> get featuresByCategory {
    final map = <String, List<HelpFeature>>{};
    for (final f in features) {
      final key = f.category(isSw);
      map.putIfAbsent(key, () => []).add(f);
    }
    return map;
  }

  @override
  void onInit() {
    super.onInit();
    final ws = Get.parameters['workspace']?.trim().toLowerCase();
    if (ws == 'rent') {
      workspaceFilter.value = HelpWorkspace.rent;
    } else if (ws == 'bnb') {
      workspaceFilter.value = HelpWorkspace.bnb;
    }
  }

  void setWorkspaceFilter(HelpWorkspace? ws) {
    workspaceFilter.value = ws ?? HelpWorkspace.both;
  }

  void onSearchChanged(String value) => searchQuery.value = value;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  void setTab(int index) => selectedTab.value = index;

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void openGuide(String guideId) {
    Get.toNamed(
      Routes.HELP_GUIDE_DETAIL,
      parameters: {'guideId': guideId},
    );
  }

  Future<void> openFeature(HelpFeature feature) async {
    await HelpNavigationHelper.openFeature(feature);
  }

  Future<void> startTour(String guideId) async {
    final tour = Get.find<GuidedTourService>();
    await tour.startGuideById(guideId);
  }

  List<HelpGuide> _filterGuides(List<HelpGuide> source) {
    final q = searchQuery.value.trim().toLowerCase();
    final ws = workspaceFilter.value;
    return source.where((g) {
      if (ws != HelpWorkspace.both &&
          g.workspace != HelpWorkspace.both &&
          g.workspace != ws) {
        return false;
      }
      if (q.isEmpty) return true;
      return g.titleEn.toLowerCase().contains(q) ||
          g.titleSw.toLowerCase().contains(q) ||
          g.summaryEn.toLowerCase().contains(q) ||
          g.categoryEn.toLowerCase().contains(q);
    }).toList();
  }

  List<HelpFeature> _filterFeatures(List<HelpFeature> source) {
    final q = searchQuery.value.trim().toLowerCase();
    final ws = workspaceFilter.value;
    return source.where((f) {
      if (ws != HelpWorkspace.both &&
          f.workspace != HelpWorkspace.both &&
          f.workspace != ws) {
        return false;
      }
      if (q.isEmpty) return true;
      return f.titleEn.toLowerCase().contains(q) ||
          f.titleSw.toLowerCase().contains(q) ||
          f.descriptionEn.toLowerCase().contains(q) ||
          f.categoryEn.toLowerCase().contains(q);
    }).toList();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/homedesigns_config.dart';
import '../../../data/local/design_moodboards_store.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';

enum MoodboardFilter { all, aiConcepts, materials }

class MoodboardListItem {
  MoodboardListItem({
    required this.id,
    required this.title,
    required this.imageRef,
    required this.savedCount,
    required this.showAiBadge,
    required this.aiConcept,
    required this.materials,
  });

  final String id;
  final String title;
  final String? imageRef;
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

  static MoodboardListItem fromStored(StoredMoodboard b) {
    return MoodboardListItem(
      id: b.id,
      title: b.title,
      imageRef: b.displayCover,
      savedCount: b.savedCount,
      showAiBadge: b.showAiBadge,
      aiConcept: b.aiConcept,
      materials: b.materials,
    );
  }
}

/// Lists moodboards from [DesignMoodboardsStore] and links to HomeDesigns.ai when configured.
///
/// API key setup (do not commit secrets):
/// ```bash
/// flutter run --dart-define=HOMEDESIGNS_ACCESS_TOKEN=your_token
/// ```
/// Token: https://homedesigns.ai/api-guide
class DesignMoodboardsController extends BaseController {
  DesignMoodboardsController({
    DesignMoodboardsStore? store,
    HomeDesignsConfig? homeDesignsConfig,
  })  : _store = store ?? DesignMoodboardsStore(),
        _homeDesignsConfig = homeDesignsConfig ?? HomeDesignsConfig.fromEnvironment();

  final DesignMoodboardsStore _store;
  final HomeDesignsConfig _homeDesignsConfig;

  final filter = MoodboardFilter.all.obs;
  final boards = <MoodboardListItem>[].obs;
  final loadFailed = false.obs;

  bool get isHomeDesignsConfigured => _homeDesignsConfig.isConfigured;

  List<MoodboardListItem> get filteredItems {
    final f = filter.value;
    return boards.where((e) => e.matches(f)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    reloadBoards();
  }

  Future<void> reloadBoards() async {
    loadFailed.value = false;
    showLoading();
    try {
      await _store.seedDefaultsIfEmpty();
      final stored = _store.loadBoards();
      boards.assignAll(
        stored.map(MoodboardListItem.fromStored).toList()
          ..sort((a, b) => b.savedCount.compareTo(a.savedCount)),
      );
    } catch (e, st) {
      logger.e('Failed to load moodboards', error: e, stackTrace: st);
      loadFailed.value = true;
      showErrorMessage(appLocalization.designMoodboardsLoadError);
    } finally {
      hideLoading();
    }
  }

  void setFilter(MoodboardFilter f) => filter.value = f;

  void openMoodboardDetail(MoodboardListItem item) {
    Get.toNamed(Routes.DESIGN_MOODBOARD, arguments: item.id);
  }

  Future<void> createNewMoodboard() async {
    final title = await _promptForBoardTitle();
    if (title == null || title.trim().isEmpty) return;
    final board = StoredMoodboard(
      id: 'board-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      aiConcept: true,
      showAiBadge: true,
      createdAt: DateTime.now(),
    );
    await _store.upsertBoard(board);
    await reloadBoards();
    openMoodboardDetail(MoodboardListItem.fromStored(board));
  }

  Future<void> openHomeDesignsWeb() async {
    final uri = Uri.parse(HomeDesignsConfig.webAppUrl);
    if (!await canLaunchUrl(uri)) {
      showErrorMessage(appLocalization.designMoodboardCannotOpenLink);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<String?> _promptForBoardTitle() async {
    final controller = TextEditingController();
    return Get.dialog<String>(
      AlertDialog(
        title: Text(appLocalization.designMoodboardCreateDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: appLocalization.designMoodboardCreateDialogHint,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(appLocalization.cancel),
          ),
          FilledButton(
            onPressed: () => Get.back(result: controller.text),
            child: Text(appLocalization.submit),
          ),
        ],
      ),
    );
  }
}

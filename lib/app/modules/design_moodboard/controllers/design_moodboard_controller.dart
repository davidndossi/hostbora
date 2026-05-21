import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/homedesigns_config.dart';
import '../../../data/local/design_moodboards_store.dart';
import '../../../data/remote/homedesigns_api_client.dart';
import '/app/core/base/base_controller.dart';

class ConceptItem {
  const ConceptItem({
    required this.id,
    required this.name,
    required this.image,
    this.editable = true,
    this.fromAi = false,
  });

  final String id;
  final String name;
  final String image;
  final bool editable;
  final bool fromAi;
}

class PaletteSwatch {
  const PaletteSwatch({required this.hex, this.label});

  final String hex;
  final String? label;
}

/// Moodboard detail backed by [DesignMoodboardsStore] with optional HomeDesigns.ai generation.
///
/// Configure API via `--dart-define=HOMEDESIGNS_ACCESS_TOKEN=...` (see [HomeDesignsConfig]).
class DesignMoodboardController extends BaseController {
  DesignMoodboardController({
    DesignMoodboardsStore? store,
    HomeDesignsApiClient? apiClient,
    HomeDesignsConfig? homeDesignsConfig,
    ImagePicker? imagePicker,
  })  : _store = store ?? DesignMoodboardsStore(),
        _api = apiClient ?? HomeDesignsApiClient(),
        _homeDesignsConfig = homeDesignsConfig ?? HomeDesignsConfig.fromEnvironment(),
        _imagePicker = imagePicker ?? ImagePicker();

  final DesignMoodboardsStore _store;
  final HomeDesignsApiClient _api;
  final HomeDesignsConfig _homeDesignsConfig;
  final ImagePicker _imagePicker;

  late String _boardId;
  final board = Rxn<StoredMoodboard>();
  final concepts = <ConceptItem>[].obs;
  final textures = <String>[].obs;
  final palette = <PaletteSwatch>[].obs;
  final selectedPaletteIndex = 2.obs;
  final generating = false.obs;
  final loadFailed = false.obs;

  String? _pendingSourceImagePath;

  bool get isHomeDesignsConfigured =>
      _homeDesignsConfig.isConfigured && _api.isConfigured;

  String get moodboardTitle => board.value?.title ?? '';

  String get subtitleLine {
    final b = board.value;
    if (b == null) return '';
    final count = b.savedCount;
    final days = DateTime.now().difference(b.createdAt).inDays;
    final age = days <= 0
        ? appLocalization.designMoodboardCreatedToday
        : appLocalization.designMoodboardCreatedDaysAgo(days);
    return appLocalization.designMoodboardSubtitle(count, age);
  }

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    _boardId = arg is String && arg.isNotEmpty ? arg : 'seed-1';
    reloadBoard();
  }

  Future<void> reloadBoard() async {
    loadFailed.value = false;
    showLoading();
    try {
      final stored = _store.findById(_boardId);
      if (stored == null) {
        loadFailed.value = true;
        showErrorMessage(appLocalization.designMoodboardNotFound);
        return;
      }
      _applyBoard(stored);
    } catch (e, st) {
      logger.e('Failed to load moodboard', error: e, stackTrace: st);
      loadFailed.value = true;
      showErrorMessage(appLocalization.designMoodboardsLoadError);
    } finally {
      hideLoading();
    }
  }

  void _applyBoard(StoredMoodboard stored) {
    board.value = stored;
    concepts.assignAll(
      stored.items
          .map(
            (e) => ConceptItem(
              id: e.id,
              name: e.name,
              image: e.imagePath,
              fromAi: e.fromAi,
            ),
          )
          .toList(),
    );
    textures.assignAll(stored.texturePaths);
    palette.assignAll(
      stored.palette
          .map((s) => PaletteSwatch(hex: s.hex, label: s.label))
          .toList(),
    );
    selectedPaletteIndex.value = stored.selectedPaletteIndex.clamp(
      0,
      stored.palette.length - 1,
    );
  }

  void selectPalette(int index) {
    if (index < 0 || index >= palette.length) return;
    selectedPaletteIndex.value = index;
    _persistPaletteIndex(index);
  }

  Future<void> _persistPaletteIndex(int index) async {
    final b = board.value;
    if (b == null) return;
    final updated = b.copyWith(selectedPaletteIndex: index);
    await _store.upsertBoard(updated);
    board.value = updated;
  }

  Future<void> addPhotoFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null) return;
    _pendingSourceImagePath = picked.path;
    await _addConceptFromPath(
      picked.path,
      name: appLocalization.designMoodboardNewConceptName,
      fromAi: false,
    );
  }

  Future<void> _addConceptFromPath(
    String path, {
    required String name,
    required bool fromAi,
  }) async {
    final b = board.value;
    if (b == null) return;
    final item = StoredMoodboardItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      imagePath: path,
      fromAi: fromAi,
    );
    final items = [...b.items, item];
    final updated = b.copyWith(
      items: items,
      showAiBadge: fromAi || b.showAiBadge,
      aiConcept: fromAi || b.aiConcept,
      coverPath: b.coverPath ?? path,
    );
    await _store.upsertBoard(updated);
    _applyBoard(updated);
  }

  Future<void> generateMoreLikeThis() async {
    if (!isHomeDesignsConfigured) {
      await openHomeDesignsWeb();
      showSuccessMessage(appLocalization.designMoodboardOpenHomeDesignsHint);
      return;
    }

    final sourcePath = _resolveSourceImagePath();
    if (sourcePath == null) {
      showErrorMessage(appLocalization.designMoodboardNeedSourcePhoto);
      await addPhotoFromGallery();
      return;
    }

    generating.value = true;
    try {
      final result = await _api.creativeRedesign(
        imageFilePath: sourcePath,
        designStyle: _styleFromBoardTitle(),
        roomType: 'Living room',
        numberOfDesigns: 2,
        prompt: 'Moodboard: $moodboardTitle',
      );
      var added = 0;
      for (var i = 0; i < result.outputImageUrls.length; i++) {
        final url = result.outputImageUrls[i];
        await _addConceptFromPath(
          url,
          name: appLocalization.designMoodboardAiConceptName(i + 1),
          fromAi: true,
        );
        added++;
      }
      if (added == 0) {
        showErrorMessage(appLocalization.designMoodboardNoOutputs);
      } else {
        showSuccessMessage(appLocalization.designMoodboardGeneratedCount(added));
      }
    } catch (e, st) {
      logger.e('HomeDesigns generate failed', error: e, stackTrace: st);
      showErrorMessage(appLocalization.designMoodboardGenerateFailed);
    } finally {
      generating.value = false;
    }
  }

  String? _resolveSourceImagePath() {
    if (_pendingSourceImagePath != null &&
        File(_pendingSourceImagePath!).existsSync()) {
      return _pendingSourceImagePath;
    }
    for (final c in concepts) {
      if (c.image.startsWith('/') && File(c.image).existsSync()) {
        return c.image;
      }
    }
    return null;
  }

  String _styleFromBoardTitle() {
    final t = moodboardTitle.toLowerCase();
    if (t.contains('mediterranean')) return 'Mediterranean';
    if (t.contains('victorian')) return 'Victorian';
    if (t.contains('scandinavian')) return 'Scandinavian';
    if (t.contains('industrial')) return 'Industrial';
    if (t.contains('bohemian')) return 'Bohemian';
    if (t.contains('minimal')) return 'Minimalist';
    return 'Modern';
  }

  Future<void> openHomeDesignsWeb() async {
    final uri = Uri.parse(HomeDesignsConfig.webAppUrl);
    if (!await canLaunchUrl(uri)) {
      showErrorMessage(appLocalization.designMoodboardCannotOpenLink);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openApiGuide() async {
    final uri = Uri.parse(HomeDesignsConfig.apiGuideUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> renameMoodboard() async {
    final b = board.value;
    if (b == null) return;
    final controller = TextEditingController(text: b.title);
    final newTitle = await Get.dialog<String>(
      AlertDialog(
        title: Text(appLocalization.designMoodboardRename),
        content: TextField(
          controller: controller,
          autofocus: true,
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
    if (newTitle == null || newTitle.trim().isEmpty) return;
    final updated = b.copyWith(title: newTitle.trim());
    await _store.upsertBoard(updated);
    _applyBoard(updated);
    showSuccessMessage(appLocalization.done);
  }

  Future<void> deleteMoodboard() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(appLocalization.designMoodboardDelete),
        content: Text(appLocalization.designMoodboardDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(appLocalization.cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              appLocalization.designMoodboardDelete,
              style: TextStyle(color: Get.theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.deleteBoard(_boardId);
    Get.back<void>();
  }
}

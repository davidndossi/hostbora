import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/config/homedesigns_config.dart';
import '../../../data/remote/homedesigns_api_client.dart';

enum StudioStyle { mediterranean, victorian, modern, minimalistic }

class StyleOption {
  final StudioStyle style;
  final String label;
  final String imagePath;

  const StyleOption({
    required this.style,
    required this.label,
    required this.imagePath,
  });
}

class ReimaginedResult {
  final String title;
  final String priceRange;
  final String subtitle;
  final List<String> tags;
  final String imagePath;

  const ReimaginedResult({
    required this.title,
    required this.priceRange,
    required this.subtitle,
    required this.tags,
    required this.imagePath,
  });
}

class InteriorDesignStudioController extends BaseController {
  InteriorDesignStudioController({
    ImagePicker? imagePicker,
    HomeDesignsApiClient? apiClient,
    HomeDesignsConfig? homeDesignsConfig,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _api = apiClient ?? HomeDesignsApiClient(),
        _homeDesignsConfig =
            homeDesignsConfig ?? HomeDesignsConfig.fromEnvironment();

  final ImagePicker _imagePicker;
  final HomeDesignsApiClient _api;
  final HomeDesignsConfig _homeDesignsConfig;

  final selectedStyle = StudioStyle.mediterranean.obs;
  final generating = false.obs;
  final pickingPhoto = false.obs;
  final selectedRoomPhotoPath = RxnString();

  final styleOptions = const <StyleOption>[
    StyleOption(
      style: StudioStyle.mediterranean,
      label: 'Mediterranean',
      imagePath: 'images/mediterranean.jpg',
    ),
    StyleOption(
      style: StudioStyle.victorian,
      label: 'Victorian',
      imagePath: 'images/victorian.jpg',
    ),
    StyleOption(
      style: StudioStyle.modern,
      label: 'Modern',
      imagePath: 'images/modern.jpg',
    ),
    StyleOption(
      style: StudioStyle.minimalistic,
      label: 'Minimalistic',
      imagePath: 'images/minimalistic.jpg',
    ),
  ].obs;

  static const _defaultResults = <ReimaginedResult>[
    ReimaginedResult(
      title: 'Mediterranean Dream',
      priceRange: '\$1,200 - \$1,500',
      subtitle: 'Perfect for coastal settings',
      tags: ['OAK WOOD', 'LINEN FABRICS', 'TERRACOTTA'],
      imagePath: 'images/mediterranean_dream.png',
    ),
    ReimaginedResult(
      title: 'Rustic Modernity',
      priceRange: '\$850 - \$1,100',
      subtitle: 'High durability for high-traffic rentals',
      tags: ['RECYCLED PINE', 'IRON FIXTURES'],
      imagePath: 'images/rustic_modernity.png',
    ),
  ];

  final results =
      RxList<ReimaginedResult>(List<ReimaginedResult>.from(_defaultResults));

  bool get isHomeDesignsConfigured =>
      _homeDesignsConfig.isConfigured && _api.isConfigured;

  bool get hasRoomPhoto {
    final path = selectedRoomPhotoPath.value;
    return path != null && path.isNotEmpty && File(path).existsSync();
  }

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  void selectStyle(StudioStyle style) {
    selectedStyle.value = style;
  }

  void uploadPhoto() {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(_t('Choose from gallery', 'Chagua kutoka gallery')),
              onTap: () {
                Get.back();
                pickPhoto(fromGallery: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(_t('Take a photo', 'Piga picha')),
              onTap: () {
                Get.back();
                pickPhoto(fromGallery: false);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Future<void> pickPhoto({required bool fromGallery}) async {
    if (pickingPhoto.value) return;
    pickingPhoto.value = true;
    try {
      final picked = await _imagePicker.pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 88,
        maxWidth: 2048,
      );
      if (picked == null || picked.path.isEmpty) return;
      selectedRoomPhotoPath.value = picked.path;
    } catch (e, st) {
      logger.e('Interior studio photo pick failed', error: e, stackTrace: st);
      showErrorMessage(
        _t(
          'Could not open photo picker. Check camera and gallery permissions.',
          'Imeshindwa kufungua picha. Angalia ruhusa za kamera na gallery.',
        ),
      );
    } finally {
      pickingPhoto.value = false;
    }
  }

  void clearRoomPhoto() => selectedRoomPhotoPath.value = null;

  Future<void> generateIdeas() async {
    if (!hasRoomPhoto) {
      showErrorMessage(appLocalization.designMoodboardNeedSourcePhoto);
      return;
    }

    if (!isHomeDesignsConfigured) {
      showErrorMessage(appLocalization.designMoodboardApiNotConfigured);
      await openHomeDesignsWeb();
      return;
    }

    final photoPath = selectedRoomPhotoPath.value!;
    final styleLabel = _apiStyleFor(selectedStyle.value);

    generating.value = true;
    try {
      final apiResult = await _api.creativeRedesign(
        imageFilePath: photoPath,
        designStyle: styleLabel,
        roomType: 'Living room',
        numberOfDesigns: 2,
        prompt: 'Interior design studio: $styleLabel',
      );

      if (apiResult.outputImageUrls.isEmpty) {
        showErrorMessage(appLocalization.designMoodboardNoOutputs);
        return;
      }

      final generated = <ReimaginedResult>[];
      for (var i = 0; i < apiResult.outputImageUrls.length; i++) {
        generated.add(
          ReimaginedResult(
            title: _t(
              '$styleLabel concept ${i + 1}',
              'Dhana ya $styleLabel ${i + 1}',
            ),
            priceRange: _t('AI estimate', 'Makadirio ya AI'),
            subtitle: _t(
              'Generated from your room photo',
              'Imetengenezwa kutoka picha ya chumba chako',
            ),
            tags: [styleLabel.toUpperCase(), 'AI GENERATED'],
            imagePath: apiResult.outputImageUrls[i],
          ),
        );
      }
      results.assignAll(generated);
      showSuccessMessage(
        appLocalization.designMoodboardGeneratedCount(generated.length),
      );
    } catch (e, st) {
      logger.e('Interior studio generate failed', error: e, stackTrace: st);
      showErrorMessage(appLocalization.designMoodboardGenerateFailed);
    } finally {
      generating.value = false;
    }
  }

  String _apiStyleFor(StudioStyle style) {
    switch (style) {
      case StudioStyle.mediterranean:
        return 'Mediterranean';
      case StudioStyle.victorian:
        return 'Victorian';
      case StudioStyle.modern:
        return 'Modern';
      case StudioStyle.minimalistic:
        return 'Minimalist';
    }
  }

  Future<void> openHomeDesignsWeb() async {
    final uri = Uri.parse(HomeDesignsConfig.webAppUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(appLocalization.designMoodboardCannotOpenLink);
    }
  }
}

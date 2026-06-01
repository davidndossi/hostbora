import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../routes/app_pages.dart';
import '../controllers/interior_design_studio_controller.dart';

class InteriorDesignStudioView
    extends BaseView<InteriorDesignStudioController> {
  InteriorDesignStudioView({super.key});

  

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(
        context,
        en: 'AI Interior Design Studio',
        sw: 'Studio ya Ubunifu wa Ndani ya AI',
      ),
      isCentered: true,
    );
  }

  @override
  Color pageBackgroundColor(BuildContext context) => FormSurfaceColors.of(context).isDark
      ? Theme.of(context).colorScheme.surface
      : AppColors.colorWhite;

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUploadCard(context),
                const SizedBox(height: 18),
                _buildStyleHeader(context),
                const SizedBox(height: 10),
                _buildStyleGrid(),
                const SizedBox(height: 14),
                _buildGenerateButton(context),
                const SizedBox(height: 18),
                Text(
                  _t(
                    context,
                    en: 'Reimagined Results',
                    sw: 'Matokeo Yaliyoboreshwa',
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.isDark
                        ? theme.colorScheme.onSurface
                        : AppColors.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildResultList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Obx(() {
      final photoPath = controller.selectedRoomPhotoPath.value;
      final hasPhoto =
          photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync();
      final picking = controller.pickingPhoto.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: c.isDark
              ? theme.colorScheme.surfaceContainerHigh
              : AppColors.pageBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.isDark
                ? theme.colorScheme.outlineVariant
                : AppColors.designInputBorder,
          ),
        ),
        child: Column(
          children: [
            if (hasPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photoPath),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: picking ? null : controller.clearRoomPhoto,
                  child: Text(
                    _t(context, en: 'Remove', sw: 'Ondoa'),
                    style: const TextStyle(color: AppColors.colorPrimary),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.photo_camera_outlined, color: Colors.white),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              hasPhoto
                  ? _t(
                      context,
                      en: 'Room photo ready',
                      sw: 'Picha ya chumba iko tayari',
                    )
                  : _t(
                      context,
                      en: 'Upload a photo of your room',
                      sw: 'Pakia picha ya chumba chako',
                    ),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.isDark
                    ? theme.colorScheme.onSurface
                    : AppColors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _t(
                context,
                en: 'For best results, ensure the room is well-lit',
                sw: 'Kwa matokeo bora, hakikisha chumba kina mwanga wa kutosha',
              ),
              style: TextStyle(
                fontSize: 12,
                color: c.isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.textColorSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: picking ? null : controller.uploadPhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                minimumSize: const Size(140, 48),
              ),
              child: picking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      hasPhoto
                          ? _t(context, en: 'Change Photo', sw: 'Badili Picha')
                          : _t(context, en: 'Select Photo', sw: 'Chagua Picha'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStyleHeader(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Row(
      children: [
        Text(
          _t(context, en: 'Select Style', sw: 'Chagua Mtindo'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.isDark
                ? theme.colorScheme.onSurface
                : AppColors.textColorPrimary,
          ),
        ),
        const Spacer(),
        Text(
          _t(context, en: '4 STYLES AVAILABLE', sw: 'MITINDO 4 INAPATIKANA'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.colorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleGrid() {
    return Obx(() {
      return GridView.builder(
        itemCount: controller.styleOptions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final style = controller.styleOptions[index];
          final selected = controller.selectedStyle.value == style.style;
          return GestureDetector(
            onTap: () => controller.selectStyle(style.style),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.colorPrimary
                      : AppColors.designInputBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(style.imagePath, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.06),
                            Colors.black.withValues(alpha: 0.42),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Text(
                        style.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildGenerateButton(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: controller.generating.value
              ? null
              : controller.generateIdeas,
          icon: controller.generating.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(
            controller.generating.value
                ? _t(context, en: 'Generating...', sw: 'Inatengeneza...')
                : _t(
                    context,
                    en: 'Generate Design Ideas',
                    sw: 'Tengeneza Mawazo ya Ubunifu',
                  ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.45,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colorPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildResultList() {
    return Obx(() {
      final c = FormSurfaceColors.of(Get.context!);
      final theme = Theme.of(Get.context!);
      return Column(
        children: controller.results
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: c.isDark
                      ? theme.colorScheme.surfaceContainerHigh
                      : AppColors.colorWhite,
                  borderRadius: BorderRadius.circular(AppValues.radius_12),
                  border: Border.all(
                    color: c.isDark
                        ? theme.colorScheme.outlineVariant
                        : AppColors.designInputBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppValues.radius_12),
                      ),
                      child: _resultImage(item.imagePath, height: 150),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.isDark
                                  ? theme.colorScheme.onSurface
                                  : AppColors.textColorPrimary,
                            ),
                          ),
                        ),
                        Text(
                          item.priceRange,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.colorPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.textColorSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: c.isDark
                                    ? theme.colorScheme.surface
                                    : AppColors.pageBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: c.isDark
                                      ? theme.colorScheme.outlineVariant
                                      : AppColors.designInputBorder,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: c.isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : AppColors.textColorSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(Routes.DESIGN_MOODBOARD),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: BorderSide(
                            color: c.isDark
                                ? theme.colorScheme.outlineVariant
                                : AppColors.designInputBorder,
                          ),
                          foregroundColor: c.isDark
                              ? theme.colorScheme.onSurface
                              : AppColors.textColorPrimary,
                        ),
                        child: Text(
                          _t(
                            Get.context!,
                            en: 'View Material List',
                            sw: 'Tazama Orodha ya Vifaa',
                          ),
                          style: const TextStyle(
                            color: AppColors.colorPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      );
    });
  }

  Widget _resultImage(String path, {required double height}) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _resultImagePlaceholder(height),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: height,
            child: const DefaultScreenSkeleton(),
          );
        },
      );
    }
    if (path.startsWith('/')) {
      return Image.file(
        File(path),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _resultImagePlaceholder(height),
      );
    }
    return Image.asset(
      path,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _resultImagePlaceholder(height),
    );
  }

  Widget _resultImagePlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.pageBackground,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}

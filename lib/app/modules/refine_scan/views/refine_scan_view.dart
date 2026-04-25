import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/refine_scan_controller.dart';

class RefineScanView extends BaseView<RefineScanController> {
  RefineScanView({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  Color pageBackgroundColor(BuildContext context) => _isDark(context)
      ? Theme.of(context).colorScheme.surface
      : AppColors.colorWhite;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.refineScan,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewWithCrop(context),
          const SizedBox(height: 10),
          _buildCropHint(context),
          const SizedBox(height: 20),
          _buildAdjustmentButtons(context),
          const SizedBox(height: 24),
          _buildDestinationFolder(context),
          const SizedBox(height: 28),
          _buildBottomButtons(context),
        ],
      ),
    );
  }

  Widget _buildPreviewWithCrop(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * (11 / 8.5);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(
              color: isDark
                  ? theme.colorScheme.outlineVariant
                  : AppColors.designInputBorder,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPreviewContent(context, width - 48, height - 48),
                ),
              ),
              Center(
                child: SizedBox(
                  width: width - 48,
                  height: height - 48,
                  child: _CropOverlay(
                    controller: controller,
                    overlayWidth: width - 48,
                    overlayHeight: height - 48,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewContent(
    BuildContext context,
    double maxWidth,
    double maxHeight,
  ) {
    return Obx(() {
      final path = controller.pathToDisplay;
      final processing = controller.isProcessing.value;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          return Stack(
            children: [
              SizedBox(
                width: maxWidth,
                height: maxHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.file(
                    file,
                    key: ValueKey(path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (processing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        }
      }
      return Container(
        width: maxWidth,
        height: maxHeight,
        decoration: BoxDecoration(
          color: _isDark(context)
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : AppColors.pageBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t(context, en: 'CONTRACT', sw: 'MKATABA'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _isDark(context)
                      ? Theme.of(context).colorScheme.onSurface
                      : AppColors.textColorPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.description_outlined,
                size: 48,
                color: AppColors.textColorSecondary,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCropHint(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Obx(() {
      final hasCrop =
          controller.cropRect.value.left > 0 ||
          controller.cropRect.value.top > 0 ||
          controller.cropRect.value.right < 1 ||
          controller.cropRect.value.bottom < 1;
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t(
                context,
                en: 'ADJUST CORNERS TO CROP',
                sw: 'REKEBISHA PEMBE KUKATA',
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.textColorSecondary,
              ),
            ),
            if (hasCrop) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: controller.isProcessing.value
                    ? null
                    : () => controller.applyCrop(),
                child: Text(
                  _t(context, en: 'Apply crop', sw: 'Tumia ukataji'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildAdjustmentButtons(BuildContext context) {
    return Obx(() {
      final processing = controller.isProcessing.value;
      return Row(
        children: [
          Expanded(
            child: _AdjustButton(
              icon: Icons.rotate_right,
              label: _t(context, en: 'Rotate', sw: 'Zungusha'),
              onTap: processing ? () {} : () => controller.rotate(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AdjustButton(
              icon: Icons.auto_fix_high,
              label: _t(context, en: 'Enhance', sw: 'Boresha'),
              onTap: processing ? () {} : () => controller.enhance(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AdjustButton(
              icon: Icons.contrast,
              label: _t(context, en: 'B&W', sw: 'Nyeusi/Nyeupe'),
              onTap: processing ? () {} : controller.toggleBlackAndWhite,
              isActive: controller.blackAndWhiteOn.value,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDestinationFolder(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, en: 'Destination Folder', sw: 'Kabrasha Lengwa'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? theme.colorScheme.onSurface
                : AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh
              : AppColors.colorWhite,
          borderRadius: BorderRadius.circular(AppValues.radius_6),
          child: InkWell(
            onTap: controller.selectDestinationFolder,
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppValues.radius_6),
                border: Border.all(
                  color: isDark
                      ? theme.colorScheme.outlineVariant
                      : AppColors.designInputBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Text(
                        controller.destinationFolder.value == 'Select folder'
                            ? _t(
                                context,
                                en: 'Select folder',
                                sw: 'Chagua kabrasha',
                              )
                            : controller.destinationFolder.value,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              controller.destinationFolder.value ==
                                  'Select folder'
                              ? (isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : AppColors.designPlaceholder)
                              : (isDark
                                    ? theme.colorScheme.onSurface
                                    : AppColors.textColorPrimary),
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.designPlaceholder,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: controller.retake,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? theme.colorScheme.onSurface
                  : AppColors.textColorPrimary,
              side: BorderSide(
                color: isDark
                    ? theme.colorScheme.outlineVariant
                    : AppColors.designInputBorder,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppValues.radius_6),
              ),
            ),
            child: Text(
              _t(context, en: 'Retake', sw: 'Piga Tena'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: controller.saveToVault,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.designAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppValues.radius_6),
              ),
              elevation: 0,
            ),
            child: Text(
              _t(context, en: 'Save to Vault', sw: 'Hifadhi Kwenye Vault'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _CropOverlay extends StatelessWidget {
  final RefineScanController controller;
  final double overlayWidth;
  final double overlayHeight;

  const _CropOverlay({
    required this.controller,
    required this.overlayWidth,
    required this.overlayHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final imgW = controller.imageWidth.value;
      final imgH = controller.imageHeight.value;
      final r = controller.cropRect.value;
      final contentW = overlayWidth;
      final contentH = overlayHeight;
      late final Rect imageRect;
      if (imgW <= 0 || imgH <= 0) {
        imageRect = Rect.fromLTWH(0, 0, contentW, contentH);
      } else {
        final aspect = imgW / imgH;
        double displayW, displayH, displayLeft, displayTop;
        if (contentH / contentW > aspect) {
          displayW = contentW;
          displayH = contentW / aspect;
          displayLeft = 0;
          displayTop = (contentH - displayH) / 2;
        } else {
          displayH = contentH;
          displayW = contentH * aspect;
          displayLeft = (contentW - displayW) / 2;
          displayTop = 0;
        }
        imageRect = Rect.fromLTWH(displayLeft, displayTop, displayW, displayH);
      }
      final cropLeft = imageRect.left + r.left * imageRect.width;
      final cropTop = imageRect.top + r.top * imageRect.height;
      final cropRight = imageRect.left + r.right * imageRect.width;
      final cropBottom = imageRect.top + r.bottom * imageRect.height;
      const handleSize = 14.0;
      const half = handleSize / 2;
      const hitSlop = 20.0;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(overlayWidth, overlayHeight),
            painter: _CropFramePainter(
              cropRect: Rect.fromLTRB(cropLeft, cropTop, cropRight, cropBottom),
              imageRect: imageRect,
            ),
          ),
          _CornerHandle(
            size: handleSize,
            hitSlop: hitSlop,
            left: cropLeft - half,
            top: cropTop - half,
            onPanUpdate: (overlayX, overlayY) =>
                _updateCrop(controller, 0, overlayX, overlayY, imageRect),
          ),
          _CornerHandle(
            size: handleSize,
            hitSlop: hitSlop,
            left: cropRight - half,
            top: cropTop - half,
            onPanUpdate: (overlayX, overlayY) =>
                _updateCrop(controller, 1, overlayX, overlayY, imageRect),
          ),
          _CornerHandle(
            size: handleSize,
            hitSlop: hitSlop,
            left: cropRight - half,
            top: cropBottom - half,
            onPanUpdate: (overlayX, overlayY) =>
                _updateCrop(controller, 2, overlayX, overlayY, imageRect),
          ),
          _CornerHandle(
            size: handleSize,
            hitSlop: hitSlop,
            left: cropLeft - half,
            top: cropBottom - half,
            onPanUpdate: (overlayX, overlayY) =>
                _updateCrop(controller, 3, overlayX, overlayY, imageRect),
          ),
        ],
      );
    });
  }
}

void _updateCrop(
  RefineScanController controller,
  int cornerIndex,
  double overlayX,
  double overlayY,
  Rect imageRect,
) {
  final r = controller.cropRect.value;
  final normX = ((overlayX - imageRect.left) / imageRect.width).clamp(0.0, 1.0);
  final normY = ((overlayY - imageRect.top) / imageRect.height).clamp(0.0, 1.0);
  const minSize = 0.05;
  double left = r.left, top = r.top, right = r.right, bottom = r.bottom;
  switch (cornerIndex) {
    case 0: // top-left
      left = normX.clamp(0.0, right - minSize);
      top = normY.clamp(0.0, bottom - minSize);
      break;
    case 1: // top-right
      right = normX.clamp(left + minSize, 1.0);
      top = normY.clamp(0.0, bottom - minSize);
      break;
    case 2: // bottom-right
      right = normX.clamp(left + minSize, 1.0);
      bottom = normY.clamp(top + minSize, 1.0);
      break;
    case 3: // bottom-left
      left = normX.clamp(0.0, right - minSize);
      bottom = normY.clamp(top + minSize, 1.0);
      break;
  }
  controller.setCropRect(Rect.fromLTRB(left, top, right, bottom));
}

class _CropFramePainter extends CustomPainter {
  final Rect cropRect;
  final Rect imageRect;

  _CropFramePainter({required this.cropRect, required this.imageRect});

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.fill;
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cropPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(8)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cropPath),
      dim,
    );
    final border = Paint()
      ..color = AppColors.designAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cropRect, const Radius.circular(8)),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant _CropFramePainter oldDelegate) =>
      oldDelegate.cropRect != cropRect || oldDelegate.imageRect != imageRect;
}

class _CornerHandle extends StatelessWidget {
  final double size;
  final double hitSlop;
  final double left;
  final double top;
  final void Function(double overlayX, double overlayY) onPanUpdate;

  const _CornerHandle({
    required this.size,
    this.hitSlop = 20,
    required this.left,
    required this.top,
    required this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final hitSize = size + 2 * hitSlop;
    final hitOffset = hitSlop;
    return Positioned(
      left: left - hitOffset,
      top: top - hitOffset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          final overlayX = left - hitOffset + details.localPosition.dx;
          final overlayY = top - hitOffset + details.localPosition.dy;
          onPanUpdate(overlayX, overlayY);
        },
        onPanUpdate: (details) {
          final overlayX = left - hitOffset + details.localPosition.dx;
          final overlayY = top - hitOffset + details.localPosition.dy;
          onPanUpdate(overlayX, overlayY);
        },
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.colorWhite,
                border: Border.all(color: AppColors.designAccent, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _AdjustButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isActive
          ? AppColors.designAccent.withValues(alpha: 0.12)
          : (isDark
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : AppColors.lightGreyColor.withValues(alpha: 0.4)),
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? AppColors.designAccent
                    : AppColors.textColorPrimary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppColors.designAccent
                      : AppColors.textColorPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

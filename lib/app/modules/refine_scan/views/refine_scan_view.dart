import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/refine_scan_controller.dart';

class RefineScanView extends BaseView<RefineScanController> {
  RefineScanView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => AppColors.colorWhite;

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
          _buildCropHint(),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * (11 / 8.5);
        const inset = 16.0;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(color: AppColors.designInputBorder),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CONTRACT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textColorPrimary,
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
                ),
              ),
              Positioned(
                left: inset,
                top: inset,
                right: inset,
                bottom: inset,
                child: _CropOverlay(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCropHint() {
    return const Center(
      child: Text(
        'ADJUST CORNERS TO CROP',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.textColorSecondary,
        ),
      ),
    );
  }

  Widget _buildAdjustmentButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AdjustButton(
            icon: Icons.rotate_right,
            label: 'Rotate',
            onTap: controller.rotate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AdjustButton(
            icon: Icons.auto_fix_high,
            label: 'Enhance',
            onTap: controller.enhance,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(
            () => _AdjustButton(
              icon: Icons.contrast,
              label: 'B&W',
              onTap: controller.toggleBlackAndWhite,
              isActive: controller.blackAndWhiteOn.value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationFolder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Destination Folder',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.colorWhite,
          borderRadius: BorderRadius.circular(AppValues.radius_6),
          child: InkWell(
            onTap: controller.selectDestinationFolder,
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppValues.radius_6),
                border: Border.all(color: AppColors.designInputBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Text(
                        controller.destinationFolder.value,
                        style: TextStyle(
                          fontSize: 16,
                          color: controller.destinationFolder.value == 'Select folder'
                              ? AppColors.designPlaceholder
                              : AppColors.textColorPrimary,
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: controller.retake,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textColorPrimary,
              side: BorderSide(color: AppColors.designInputBorder),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppValues.radius_6),
              ),
            ),
            child: const Text(
              'Retake',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
            child: const Text(
              'Save to Vault',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CropOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const borderColor = AppColors.designAccent;
    const handleSize = 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.biggest.width;
        final h = constraints.biggest.height;
        const half = handleSize / 2;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: _CropFramePainter(),
            ),
            Positioned(left: -half, top: -half, child: _CornerHandle(size: handleSize)),
            Positioned(right: -half, top: -half, child: _CornerHandle(size: handleSize)),
            Positioned(right: -half, bottom: -half, child: _CornerHandle(size: handleSize)),
            Positioned(left: -half, bottom: -half, child: _CornerHandle(size: handleSize)),
          ],
        );
      },
    );
  }
}

class _CropFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.designAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerHandle extends StatelessWidget {
  final double size;

  const _CornerHandle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        border: Border.all(color: AppColors.designAccent, width: 2),
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
    return Material(
      color: isActive
          ? AppColors.designAccent.withOpacity(0.12)
          : AppColors.lightGreyColor.withOpacity(0.4),
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
                color: isActive ? AppColors.designAccent : AppColors.textColorPrimary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.designAccent : AppColors.textColorPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

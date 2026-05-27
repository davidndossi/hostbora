import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widget/module_default_text_scope.dart';
import '../../../core/values/app_values.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/document_scanner_controller.dart';

const _scannerBg = Color(0xFF1E2E3A);
const _scannerTeal = Color(0xFF2DD4BF);
const _scannerTealRing = Color(0xFF5EEAD4);
const _scannerPillBg = Color(0xFF2A3A45);
const _scannerSecondary = Color(0xFF9CA3AF);

class DocumentScannerView extends GetView<DocumentScannerController> {
  const DocumentScannerView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final scannerBg = isDark ? _scannerBg : const Color(0xFFF3F6F8);
    final scannerPillBg = isDark
        ? _scannerPillBg
        : Colors.white.withValues(alpha: 0.92);
    final scannerSecondary = isDark
        ? _scannerSecondary
        : AppColors.textColorSecondary;
    final topIconColor = isDark ? Colors.white : AppColors.textColorPrimary;
    final instructionTextColor = isDark
        ? Colors.white
        : AppColors.textColorPrimary;

    return ModuleDefaultTextScope(
      child: Scaffold(
      backgroundColor: scannerBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: controller.close,
          icon: const Icon(Icons.close, size: 28),
          color: topIconColor,
        ),
        actions: [
          IconButton(
            onPressed: controller.toggleFlash,
            icon: Obx(
              () => Icon(
                controller.flashOn.value ? Icons.flash_on : Icons.flash_off,
                size: 26,
                color: topIconColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildCameraPreview(context, scannerBg)),
          _buildDocumentFrameOverlay(context),
          _buildInstructionPill(
            context,
            scannerPillBg: scannerPillBg,
            textColor: instructionTextColor,
          ),
          _buildBottomBar(
            context,
            scannerPillBg: scannerPillBg,
            scannerSecondary: scannerSecondary,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context, Color scannerBg) {
    return Obx(() {
      if (controller.cameraError.value.isNotEmpty) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          color: scannerBg,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.cameraError.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isDark(context)
                          ? Colors.white70
                          : AppColors.textColorSecondary,
                      fontSize: 15,
                    ),
                  ),
                  if (controller.showPermissionActions.value) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: controller.retryPermission,
                          child: Text(l10n.designMoodboardRetry),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: controller.openAppSettingsForCamera,
                          child: Text(l10n.openSettings),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
      if (!controller.isCameraReady.value ||
          controller.cameraController == null) {
        return Container(
          color: scannerBg,
          child: const Center(
            child: CircularProgressIndicator(color: _scannerTeal),
          ),
        );
      }
      final ctrl = controller.cameraController!;
      final previewSize = ctrl.value.previewSize;
      if (previewSize == null) {
        return Container(
          color: scannerBg,
          child: const Center(
            child: CircularProgressIndicator(color: _scannerTeal),
          ),
        );
      }
      final isPortrait =
          MediaQuery.orientationOf(context) == Orientation.portrait;
      final aspectRatio = isPortrait
          ? previewSize.height / previewSize.width
          : previewSize.width / previewSize.height;
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          double width, height;
          if (h / w > aspectRatio) {
            height = h;
            width = h / aspectRatio;
          } else {
            width = w;
            height = w * aspectRatio;
          }
          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: CameraPreview(ctrl),
            ),
          );
        },
      );
    });
  }

  Widget _buildDocumentFrameOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const inset = 32.0;
    final frameWidth = size.width - inset * 2;
    final frameHeight = frameWidth * (11 / 8.5); // approximate A4 aspect
    final top = (size.height - frameHeight) * 0.35;

    return Positioned(
      left: inset,
      top: top,
      width: frameWidth,
      height: frameHeight,
      child: CustomPaint(
        painter: _DocumentFramePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildInstructionPill(
    BuildContext context, {
    required Color scannerPillBg,
    required Color textColor,
  }) {
    final size = MediaQuery.of(context).size;
    const inset = 32.0;
    final frameWidth = size.width - inset * 2;
    final frameHeight = frameWidth * (11 / 8.5);
    final top = (size.height - frameHeight) * 0.35;

    return Positioned(
      left: 24,
      right: 24,
      top: top + frameHeight + 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: scannerPillBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            _t(
              context,
              en: 'Position the document within the frame',
              sw: 'Weka faili ndani ya fremu',
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context, {
    required Color scannerPillBg,
    required Color scannerSecondary,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: _BottomAction(
                  icon: Icons.photo_library_outlined,
                  label: _t(context, en: 'IMPORT', sw: 'INGIZA'),
                  scannerPillBg: scannerPillBg,
                  scannerSecondary: scannerSecondary,
                  onTap: controller.importFromGallery,
                ),
              ),
              _buildCaptureButton(context),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton(BuildContext context) {
    return GestureDetector(
      onTap: controller.capture,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _scannerTealRing, width: 4),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: _scannerTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const borderColor = _scannerTeal;
    const borderWidth = 2.5;
    const cornerLen = 24.0;
    const radius = 12.0;

    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );
    canvas.drawRRect(path, border);

    final corner = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    void drawCorner(double x, double y, bool horizontalOut, bool verticalOut) {
      final dx = horizontalOut ? 1.0 : -1.0;
      final dy = verticalOut ? 1.0 : -1.0;
      canvas.drawLine(Offset(x, y), Offset(x + cornerLen * dx, y), corner);
      canvas.drawLine(Offset(x, y), Offset(x, y + cornerLen * dy), corner);
    }

    drawCorner(0, 0, true, true);
    drawCorner(w, 0, false, true);
    drawCorner(w, h, false, false);
    drawCorner(0, h, true, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color scannerPillBg;
  final Color scannerSecondary;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.scannerPillBg,
    required this.scannerSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scannerPillBg,
              borderRadius: BorderRadius.circular(AppValues.radius_6),
            ),
            child: Icon(icon, size: 26, color: scannerSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scannerSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

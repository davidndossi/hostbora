import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '/app/core/values/app_colors.dart';

/// Full-screen barcode / QR scanner for inventory.
///
/// Usage:
/// ```dart
/// final code = await Get.to<String>(() => InventoryBarcodeScannerView());
/// if (code != null) { /* use scanned barcode */ }
/// ```
class InventoryBarcodeScannerView extends StatefulWidget {
  const InventoryBarcodeScannerView({super.key});

  @override
  State<InventoryBarcodeScannerView> createState() =>
      _InventoryBarcodeScannerViewState();
}

class _InventoryBarcodeScannerViewState
    extends State<InventoryBarcodeScannerView> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _done = false;
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _done = true;
    Get.back<String>(result: code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _isSw ? 'Changanua Msimbo' : 'Scan Barcode / QR',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            tooltip: _isSw ? 'Taa' : 'Torch',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon:
                const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
            tooltip: _isSw ? 'Badilisha kamera' : 'Flip camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.colorPrimary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Label
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              _isSw
                  ? 'Weka msimbo ndani ya fremu'
                  : 'Align barcode or QR code within the frame',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

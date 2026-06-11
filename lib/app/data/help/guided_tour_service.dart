import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'help_center_catalog.dart';
import 'help_center_models.dart';
import '../../modules/help_center/widgets/guided_tour_overlay.dart';

/// Runs multi-step guided tours: navigates to screens and shows coach overlays.
class GuidedTourService extends GetxService {
  final isActive = false.obs;
  final currentStepIndex = 0.obs;
  final currentGuideId = ''.obs;

  HelpGuide? _guide;

  bool get isSw => Get.locale?.languageCode == 'sw';

  Future<void> startGuide(HelpGuide guide) async {
    if (guide.steps.isEmpty) return;
    _guide = guide;
    currentGuideId.value = guide.id;
    currentStepIndex.value = 0;
    isActive.value = true;
    await _runStep(0);
  }

  Future<void> startGuideById(String guideId) async {
    final guide = HelpCenterCatalog.guideById(guideId);
    if (guide == null) return;
    await startGuide(guide);
  }

  Future<void> _runStep(int index) async {
    final guide = _guide;
    if (guide == null || index < 0 || index >= guide.steps.length) {
      await finish();
      return;
    }

    currentStepIndex.value = index;
    final step = guide.steps[index];

    if (step.route != null && step.route!.isNotEmpty) {
      final params = step.routeParameters ?? {};
      final args = step.routeArguments;
      // Do NOT await — Get.toNamed's Future completes on pop, not on push.
      // Fire-and-forget so we can show the overlay after the transition settles.
      if (args != null) {
        Get.toNamed(step.route!, parameters: params, arguments: args);
      } else {
        Get.toNamed(step.route!, parameters: params);
      }
      // Wait for the push animation to finish before attaching the overlay.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) {
      await finish();
      return;
    }

    if (!ctx.mounted) return;

    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogCtx) => GuidedTourOverlay(
        guideTitle: guide.title(isSw),
        stepIndex: index,
        stepCount: guide.steps.length,
        stepTitle: step.title(isSw),
        stepBody: step.body(isSw),
        isSw: isSw,
        onSkip: () {
          Navigator.of(dialogCtx).pop();
          finish();
        },
        onNext: () {
          Navigator.of(dialogCtx).pop();
          final next = index + 1;
          if (next >= guide.steps.length) {
            finish();
          } else {
            _runStep(next);
          }
        },
      ),
    );
  }

  Future<void> finish() async {
    isActive.value = false;
    currentStepIndex.value = 0;
    currentGuideId.value = '';
    _guide = null;
  }

  void skip() => finish();
}

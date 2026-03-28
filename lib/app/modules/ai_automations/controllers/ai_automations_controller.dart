import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

enum VoiceTone { friendly, professional, casual }

class AiAutomationsController extends BaseController {
  final autoReplyEnabled = true.obs;
  final smartPricingEnabled = true.obs;
  final autoAssignCleaningEnabled = false.obs;

  final selectedTone = VoiceTone.friendly.obs;
  final personaController = TextEditingController();

  void setAutoReply(bool value) => autoReplyEnabled.value = value;

  void setSmartPricing(bool value) => smartPricingEnabled.value = value;

  void setAutoAssignCleaning(bool value) => autoAssignCleaningEnabled.value = value;

  void setTone(VoiceTone tone) => selectedTone.value = tone;

  void previewVoice() {
    showSuccessMessage('Previewing AI voice...');
  }

  @override
  void onClose() {
    personaController.dispose();
    super.onClose();
  }
}

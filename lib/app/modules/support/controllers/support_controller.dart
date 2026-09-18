import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class SupportController extends BaseController {
  static const String supportEmailAddress = 'info@hostbora.co.tz';
  final faqQuery = ''.obs;
  final faqSearchController = TextEditingController();

  static final Uri _supportEmail = Uri.parse(
    'mailto:$supportEmailAddress?subject=${Uri.encodeComponent('HostBora support')}',
  );

  /// WhatsApp number in international format **without** + or spaces (e.g. `255712345678`).
  static const String supportWhatsAppE164 = '255789287509';

  static const String supportWhatsAppDisplay = '+255 789 287 509';

  Future<void> openSupportEmail() async {
    try {
      if (await canLaunchUrl(_supportEmail)) {
        await launchUrl(_supportEmail, mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      logger.e('openSupportEmail $e $st');
    }
  }

  Future<void> openWhatsApp() async {
    final msg = Uri.encodeComponent(
      'Hello, I need help with the HostBora app.',
    );
    final uri = Uri.parse('https://wa.me/$supportWhatsAppE164?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      logger.e('openWhatsApp $e $st');
    }
  }

  void clearFaqQuery() {
    faqQuery.value = '';
    faqSearchController.clear();
  }

  void openTerms() => Get.toNamed(Routes.TERMS);

  void openPrivacy() => Get.toNamed(Routes.PRIVACY);

  void openFeedback() => Get.toNamed(Routes.FEEDBACK);

  void openHelpCenter() => Get.toNamed(Routes.HELP_CENTER);

  @override
  void onClose() {
    faqSearchController.dispose();
    super.onClose();
  }
}

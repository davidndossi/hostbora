import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class SupportController extends BaseController {
  static const String supportEmailAddress = 'support@hostbora.co.tz';

  static final Uri _supportEmail = Uri.parse(
    'mailto:$supportEmailAddress?subject=${Uri.encodeComponent('Host Bora support')}',
  );

  /// WhatsApp number in international format **without** + or spaces (e.g. `255712345678`).
  /// Replace with your support / business line.
  static const String supportWhatsAppE164 = '255789287509';

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
      'Hello, I need help with the Host Bora app.',
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

  void openTerms() => Get.toNamed(Routes.TERMS);

  void openPrivacy() => Get.toNamed(Routes.PRIVACY);

  void openFeedback() => Get.toNamed(Routes.FEEDBACK);
}

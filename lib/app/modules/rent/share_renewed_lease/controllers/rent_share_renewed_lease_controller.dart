import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';

class RentShareRenewedLeaseController extends BaseController {
  final sendCopyToMyEmail = true.obs;

  String get previewFileName {
    final p = Get.parameters['fileName']?.trim();
    if (p != null && p.isNotEmpty) return p;
    return 'Riverside_Lease_2024.pdf';
  }

  String _shareMessage({required bool isSw}) {
    final name = previewFileName;
    if (isSw) {
      return 'Mkataba ulioboreshwa: $name\nTafadhali angalia na saini.';
    }
    return 'Your renewed lease is ready: $name\nPlease review and sign.';
  }

  Future<void> shareViaWhatsApp() async {
    final isSw = Get.locale?.languageCode == 'sw';
    final text = Uri.encodeComponent(_shareMessage(isSw: isSw));
    final uri = Uri.parse('https://wa.me/?text=$text');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(_shareMessage(isSw: isSw));
      }
    } catch (_) {
      await Share.share(_shareMessage(isSw: isSw));
    }
  }

  Future<void> sendViaEmail() async {
    final isSw = Get.locale?.languageCode == 'sw';
    final subject = isSw ? 'Mkataba ulioboreshwa' : 'Renewed lease document';
    var body = _shareMessage(isSw: isSw);
    if (sendCopyToMyEmail.value) {
      body += isSw
          ? '\n\n(Nakili kwa mwenye mali pia.)'
          : '\n\n(Copy to landlord noted in request.)';
    }
    final mailto = Uri.parse(
      'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    try {
      if (await canLaunchUrl(mailto)) {
        await launchUrl(mailto, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(body, subject: subject);
      }
    } catch (_) {
      await Share.share(body, subject: subject);
    }
  }

  void toggleSendCopy(bool? v) {
    if (v != null) sendCopyToMyEmail.value = v;
  }

  void onPreviewTap() {
    showSuccessMessage(
      Get.locale?.languageCode == 'sw'
          ? 'Hakiki kamili — hivi karibuni'
          : 'Full preview — coming soon',
    );
  }

  void onDone() => Get.back();

  void returnToContractHub() {
    Get.offNamed(Routes.RENT_CONTRACT_HUB);
  }
}

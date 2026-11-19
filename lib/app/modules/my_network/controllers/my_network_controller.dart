import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/host_network.dart';
import '../../../data/repository/app_repository.dart';

class MyNetworkController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final network = Rxn<HostNetwork>();
  final loading = false.obs;

  bool get isSw => Get.locale?.languageCode == 'sw';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading(true);
    try {
      final response = await _repository.getMyNetwork();
      final data = response.data;
      if (response.isSuccess && data is Map) {
        network(HostNetwork.fromJson(Map<String, dynamic>.from(data)));
      }
    } catch (_) {
      showErrorMessage(isSw ? 'Imeshindikana kupakia mtandao.' : 'Could not load your network.');
    } finally {
      loading(false);
    }
  }

  String inviteMessage() {
    final data = network.value;
    if (data == null) return '';
    return isSw
        ? 'Jiunge Host Bora kwa msimbo wangu ${data.referralCode}\n${data.inviteUrl}'
        : 'Join Host Bora with my referral code ${data.referralCode}\n${data.inviteUrl}';
  }

  Future<void> _countInvite() async {
    try {
      final response = await _repository.recordHostInvite();
      final data = response.data;
      if (response.isSuccess && data is Map) {
        network(HostNetwork.fromJson(Map<String, dynamic>.from(data)));
      }
    } catch (_) {
      // Sharing still proceeds if the counter is temporarily unavailable.
    }
  }

  Future<void> shareWhatsApp() async {
    final text = inviteMessage();
    if (text.isEmpty) return;
    await _countInvite();
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(isSw ? 'WhatsApp haikufunguka.' : 'Could not open WhatsApp.');
    }
  }

  Future<void> shareSms() async {
    final text = inviteMessage();
    if (text.isEmpty) return;
    await _countInvite();
    final uri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(isSw ? 'SMS haikufunguka.' : 'Could not open Messages.');
    }
  }

  Future<void> copyLink() async {
    final url = network.value?.inviteUrl ?? '';
    if (url.isEmpty) return;
    await _countInvite();
    await Clipboard.setData(ClipboardData(text: url));
    showSuccessMessage(isSw ? 'Kiungo kimenakiliwa' : 'Referral link copied');
  }
}

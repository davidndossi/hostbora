import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/property_manager.dart';
import '../../../data/repository/app_repository.dart';

class PropertyManagerProfileController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final manager = Rxn<PropertyManager>();
  final loading = false.obs;

  bool get isSw => Get.locale?.languageCode == 'sw';

  String get managerId {
    final args = Get.arguments;
    return args?.toString() ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (managerId.isEmpty) return;
    loading(true);
    try {
      final response = await _repository.getPropertyManager(managerId);
      final data = response.data;
      if (response.isSuccess && data is Map) {
        manager(PropertyManager.fromJson(Map<String, dynamic>.from(data)));
      }
    } catch (_) {
      showErrorMessage(isSw ? 'Wasifu haujapatikana.' : 'Could not load this profile.');
    } finally {
      loading(false);
    }
  }

  Future<void> contactWhatsApp() async {
    final profile = await _recordContact('whatsapp');
    final phone = _digits(profile?.phone);
    if (phone.isEmpty) return;
    final text = isSw
        ? 'Habari ${profile!.displayName}, nimekupata kwenye HostBora Property Manager Directory.'
        : 'Hello ${profile!.displayName}, I found you on the HostBora Property Manager Directory.';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(isSw ? 'WhatsApp haikufunguka.' : 'Could not open WhatsApp.');
    }
  }

  Future<void> contactSms() async {
    final profile = await _recordContact('sms');
    final phone = profile?.phone?.trim() ?? '';
    if (phone.isEmpty) return;
    final text = isSw
        ? 'Habari ${profile!.displayName}, nimekupata kwenye HostBora.'
        : 'Hello ${profile!.displayName}, I found you on HostBora.';
    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(isSw ? 'SMS haikufunguka.' : 'Could not open Messages.');
    }
  }

  Future<void> contactCall() async {
    final profile = await _recordContact('call');
    final phone = profile?.phone?.trim() ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(isSw ? 'Simu haikufunguka.' : 'Could not start the call.');
    }
  }

  Future<PropertyManager?> _recordContact(String channel) async {
    try {
      final response = await _repository.contactPropertyManager(managerId, channel);
      final data = response.data;
      if (response.isSuccess && data is Map && data['manager'] is Map) {
        final next = PropertyManager.fromJson(Map<String, dynamic>.from(data['manager'] as Map));
        manager(next);
        return next;
      }
    } catch (_) {
      // Launch still proceeds with the already-loaded profile.
    }
    return manager.value;
  }

  String _digits(String? raw) => (raw ?? '').replaceAll(RegExp(r'\D'), '');
}

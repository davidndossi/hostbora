import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/base/base_controller.dart';

class AboutController extends BaseController {
  final versionText = ''.obs;
  final versionLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      versionText.value = '${info.version} (${info.buildNumber})';
    } catch (e) {
      logger.e('Failed to load app version', error: e);
      versionText.value = '—';
    } finally {
      versionLoading.value = false;
    }
  }
}

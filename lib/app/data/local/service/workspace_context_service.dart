import 'package:get/get.dart';

import '/app/routes/app_pages.dart';
import '../preference/preference_manager.dart';

class WorkspaceContextService extends GetxService {
  WorkspaceContextService({
    required PreferenceManager preferenceManager,
  }) : _preferenceManager = preferenceManager;

  /// Pass in [offAllToPreferredWorkspace] `arguments` after sign-in so the rent shell
  /// can switch to the Listings tab once when the hub has no properties.
  static const String rentHubRedirectListingsIfEmptyKey = 'redirect_rent_listings_if_empty';

  final PreferenceManager _preferenceManager;

  final currentWorkspace = 'bnb'.obs;

  Future<WorkspaceContextService> init() async {
    final saved = await _preferenceManager.getString(
      PreferenceManager.keyWorkspaceType,
      defaultValue: 'bnb',
    );
    currentWorkspace.value = _normalize(saved);
    return this;
  }

  Future<String> getWorkspaceType() async {
    final value = currentWorkspace.value.trim();
    if (value.isEmpty) {
      final saved = await _preferenceManager.getString(
        PreferenceManager.keyWorkspaceType,
        defaultValue: 'bnb',
      );
      currentWorkspace.value = _normalize(saved);
    }
    return currentWorkspace.value;
  }

  Future<void> switchWorkspace(String workspaceType) async {
    final next = _normalize(workspaceType);
    currentWorkspace.value = next;
    await _preferenceManager.setString(PreferenceManager.keyWorkspaceType, next);
  }

  /// Clears the stack and opens BnB shell or Rent shell based on saved workspace.
  Future<void> offAllToPreferredWorkspace({Map<String, dynamic>? arguments}) async {
    final saved = await _preferenceManager.getString(
      PreferenceManager.keyWorkspaceType,
      defaultValue: 'bnb',
    );
    await switchWorkspace(_normalize(saved));
    if (currentWorkspace.value == 'bnb') {
      Get.offAllNamed(Routes.MAIN, arguments: arguments);
    } else {
      Get.offAllNamed(Routes.RENT_HUB, arguments: arguments);
    }
  }

  String _normalize(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'bnb') return 'bnb';
    return 'rent';
  }
}


import 'package:get/get.dart';

import '../preference/preference_manager.dart';

class WorkspaceContextService extends GetxService {
  WorkspaceContextService({
    required PreferenceManager preferenceManager,
  }) : _preferenceManager = preferenceManager;

  /// Passed as a navigation argument after sign-in so the rent shell can
  /// switch to the Listings tab once when the hub has no properties.
  ///
  /// Currently written by the sign-in paths and read by nobody: the rent hub
  /// it targets has no registered route. Kept rather than removed because the
  /// shell is unfinished, not abandoned.
  static const String rentHubRedirectListingsIfEmptyKey = 'redirect_rent_listings_if_empty';

  final PreferenceManager _preferenceManager;

  /// `all` | `bnb` | `rent`.
  ///
  /// Defaults to `all` because the host is never asked to choose. Picking a
  /// side on their behalf is what previously hid half the product: the value
  /// defaulted to `bnb`, so a long-term landlord's rent data was filtered out
  /// of Home by a preference they had never set.
  final currentWorkspace = _allWorkspaces.obs;

  static const String _allWorkspaces = 'all';

  Future<WorkspaceContextService> init() async {
    final saved = await _preferenceManager.getString(
      PreferenceManager.keyWorkspaceType,
      defaultValue: _allWorkspaces,
    );
    currentWorkspace.value = _normalize(saved);
    return this;
  }

  Future<String> getWorkspaceType() async {
    final value = currentWorkspace.value.trim();
    if (value.isEmpty) {
      final saved = await _preferenceManager.getString(
        PreferenceManager.keyWorkspaceType,
        defaultValue: _allWorkspaces,
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

  /// `bnb` and `rent` are explicit host choices made inside the app. Anything
  /// else — unset, `both`, or a value from a build that stored something
  /// different — means no side was chosen, which is [_allWorkspaces]. That
  /// matches the data layer, where empty and `all` both select every
  /// workspace.
  String _normalize(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'bnb') return 'bnb';
    if (v == 'rent') return 'rent';
    return _allWorkspaces;
  }
}


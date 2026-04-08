import 'package:get/get.dart';

import '../preference/preference_manager.dart';

class WorkspaceContextService extends GetxService {
  WorkspaceContextService({
    required PreferenceManager preferenceManager,
  }) : _preferenceManager = preferenceManager;

  final PreferenceManager _preferenceManager;

  final currentWorkspace = 'rent'.obs;

  Future<WorkspaceContextService> init() async {
    final saved = await _preferenceManager.getString(
      PreferenceManager.keyWorkspaceType,
      defaultValue: 'rent',
    );
    currentWorkspace.value = _normalize(saved);
    return this;
  }

  Future<String> getWorkspaceType() async {
    final value = currentWorkspace.value.trim();
    if (value.isEmpty) {
      final saved = await _preferenceManager.getString(
        PreferenceManager.keyWorkspaceType,
        defaultValue: 'rent',
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

  String _normalize(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'bnb') return 'bnb';
    return 'rent';
  }
}


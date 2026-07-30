import 'package:get/get.dart';

/// Ensures at most one soft (non-critical) launch prompt is shown per app
/// session, so Home is not buried under update / review / tip / dialog stacks.
///
/// Force-update dialogs must not use this gate — they always win.
class LaunchPromptGate extends GetxService {
  bool _softPromptClaimed = false;

  /// Returns true if this caller may show a soft prompt, and marks the slot used.
  bool tryClaimSoftPrompt() {
    if (_softPromptClaimed) return false;
    _softPromptClaimed = true;
    return true;
  }

  bool get softPromptClaimed => _softPromptClaimed;
}

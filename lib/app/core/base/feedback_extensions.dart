import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/haptic_feedback_util.dart';
import '../widget/undo_snackbar.dart';
import 'base_controller.dart';

/// Destructive-action helpers (undo snackbar, haptics, confirm dialogs).
extension FeedbackExtensions on BaseController {
  Future<bool> confirmDestructive({
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Delete',
    bool barrierDismissible = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
    return result == true;
  }
  /// Success toast + light haptic (trend #5).
  void showSuccessWithHaptic(String msg) {
    hapticPrimaryConfirm();
    showSuccessMessage(msg);
  }

  /// Runs [action], then shows undo snackbar. Calls [onUndo] if user taps Undo.
  Future<void> runDestructiveWithUndo({
    required String message,
    required Future<void> Function() action,
    required Future<void> Function() onUndo,
    Duration duration = const Duration(seconds: 5),
  }) async {
    await action();
    hapticPrimaryConfirm();
    final ctx = Get.context;
    if (ctx == null || !ctx.mounted) return;
    UndoSnackBar.show(
      ctx,
      message: message,
      duration: duration,
      onUndo: () {
        onUndo();
      },
    );
  }

  /// Focus first invalid field + haptic (forms).
  void hapticOnValidationError() {
    hapticValidationError();
  }
}

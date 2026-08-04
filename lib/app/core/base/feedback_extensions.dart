import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/haptic_feedback_util.dart';
import '../values/app_colors.dart';
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
    Duration duration = const Duration(seconds: 4),
  }) async {
    await action();
    hapticPrimaryConfirm();
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    final ctx = Get.context;
    if (ctx != null && ctx.mounted) {
      final messenger = ScaffoldMessenger.maybeOf(ctx);
      if (messenger != null) {
        UndoSnackBar.show(
          ctx,
          message: message,
          duration: duration,
          onUndo: () {
            onUndo();
          },
        );
        return;
      }
    }
    // GetX pages often lack a ScaffoldMessenger ancestor for Get.context.
    Get.rawSnackbar(
      messageText: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: Colors.white,
        ),
      ),
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
          onUndo();
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.colorPrimaryLight,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        child: const Text('Undo'),
      ),
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
      isDismissible: true,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
    );
  }

  /// Focus first invalid field + haptic (forms).
  void hapticOnValidationError() {
    hapticValidationError();
  }
}

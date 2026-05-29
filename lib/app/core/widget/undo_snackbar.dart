import 'package:flutter/material.dart';

import '../values/app_colors.dart';

/// Destructive-action snackbar with undo (trend #5 — communicative feedback).
class UndoSnackBar {
  UndoSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
    String undoLabel = 'Undo',
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: undoLabel,
          textColor: AppColors.colorPrimaryLight,
          onPressed: onUndo,
        ),
      ),
    );
  }
}

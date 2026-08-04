import 'package:flutter/material.dart';

import '../values/app_colors.dart';

/// Destructive-action snackbar with undo (trend #5 — communicative feedback).
class UndoSnackBar {
  UndoSnackBar._();

  static const double _fontSize = 14;

  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 4),
    String undoLabel = 'Undo',
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        // Custom row so Undo matches the message size (SnackBarAction uses
        // labelLarge, which reads much larger than the content text).
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onUndo();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.colorPrimaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              child: Text(undoLabel),
            ),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

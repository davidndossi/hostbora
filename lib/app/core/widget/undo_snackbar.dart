import 'package:flutter/material.dart';

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

    final scheme = Theme.of(context).colorScheme;
    // inverseSurface / onInverseSurface stay high-contrast in both light and
    // dark themes (Material 3 snackbar defaults). Hardcoded white text failed
    // on dark theme when the snackbar surface stayed light.
    final background = scheme.inverseSurface;
    final foreground = scheme.onInverseSurface;
    final actionColor = Color.lerp(foreground, scheme.primary, 0.35)!;

    messenger.hideCurrentSnackBar();
    // One-shot: rapid/repeat Undo taps must not re-run restore (duplicates).
    var undone = false;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: background,
        // Custom row so Undo matches the message size (SnackBarAction uses
        // labelLarge, which reads much larger than the content text).
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: foreground,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                if (undone) return;
                undone = true;
                messenger.hideCurrentSnackBar();
                onUndo();
              },
              style: TextButton.styleFrom(
                foregroundColor: actionColor,
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

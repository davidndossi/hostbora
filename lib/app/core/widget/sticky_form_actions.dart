import 'package:flutter/material.dart';

import '../values/app_values.dart';
import '../theme/app_theme_tokens.dart';

/// Pins a form's primary action to the bottom of the screen.
///
/// Long forms previously carried their Save button as the last item in the
/// scroll, so on a tall form the only way to commit was to scroll to the
/// bottom first — the action was present but not reachable. Lifting it out of
/// the scroll makes it reachable at every scroll position.
///
/// Place as the last child of a [Column] whose other child is an [Expanded]
/// scroll view. Sitting inside the Scaffold body rather than in
/// `bottomNavigationBar` is deliberate: the body shrinks for the keyboard, so
/// the bar rides above it instead of being covered by it.
class StickyFormActions extends StatelessWidget {
  const StickyFormActions({
    super.key,
    required this.primary,
    this.secondary,
  });

  /// The committing action. Stretched to the full width of the bar.
  final Widget primary;

  /// An optional lower-weight escape, usually Cancel. Rendered under the
  /// primary at a smaller size so the two never read as equal choices.
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppValues.padding,
            12,
            AppValues.padding,
            12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: double.infinity, child: primary),
              if (secondary case final secondary?) ...[
                const SizedBox(height: 4),
                secondary,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/form_surface_colors.dart';

/// Shared chrome for the condensed "quick action" step-by-step wizards
/// (Add Property, Add Income, Add Expense) launched from the home quick
/// actions dialog: a step-dot indicator, animated step content, and a
/// Previous / Skip / Next-or-Submit bottom bar.
///
/// Presented as a tall, scrollable modal bottom sheet so it feels like a
/// self-contained dialog while leaving room for real form content.
///
/// Deliberately uses Flutter's own [showModalBottomSheet] rather than
/// `Get.bottomSheet`: GetX's `GetModalBottomSheetRoute.buildPage` wraps the
/// *entire* sheet in `Padding(bottom: MediaQuery.viewInsets.bottom)` at the
/// route level, before any of our widgets even run — so no matter what we
/// do inside `_QuickWizardSheetChrome`/`QuickWizardBody`, the whole sheet
/// still gets visibly "pushed"/shrunk by the keyboard opening. Flutter's
/// native `ModalBottomSheetRoute` never touches `viewInsets` at all, which
/// leaves keyboard handling entirely to our own (already keyboard-aware)
/// content below, so the sheet's outer size stays put.
Future<T?> showQuickWizardSheet<T>({
  required String title,
  required WidgetBuilder builder,
}) {
  final context = Get.context;
  if (context == null) return Future.value(null);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickWizardSheetChrome(title: title, builder: builder),
  );
}

class _QuickWizardSheetChrome extends StatelessWidget {
  const _QuickWizardSheetChrome({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    // Deliberately NOT reducing this box's height by the keyboard inset
    // (e.g. via an outer AnimatedPadding): that would compound with
    // `heightFactor` — shrinking the sheet by *both* the keyboard height
    // *and* 6% of what's left — squeezing the header/dots/footer chrome
    // into a tiny strip on smaller screens or with taller keyboards. The
    // sheet keeps a fixed, comfortable size relative to the full screen;
    // keyboard avoidance is handled inside `QuickWizardBody`'s scrollable
    // content instead, which is where Flutter's built-in
    // "scroll focused field into view" behavior expects it.
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Container(
        decoration: BoxDecoration(
          color: c.scaffold,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: builder(context),
      ),
    );
  }
}

/// Body content for a quick-add wizard screen: header (title + close),
/// step dots, animated step area, and bottom navigation bar.
class QuickWizardBody extends StatelessWidget {
  const QuickWizardBody({
    super.key,
    required this.title,
    required this.stepIndex,
    required this.totalSteps,
    required this.stepContent,
    required this.onClose,
    this.onPrevious,
    required this.onNext,
    required this.nextLabel,
    this.onSkip,
    this.skipLabel,
    this.isSubmitting = false,
  });

  final String title;
  final int stepIndex;
  final int totalSteps;
  final Widget stepContent;
  final VoidCallback onClose;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String nextLabel;
  final VoidCallback? onSkip;
  final String? skipLabel;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.headline,
              ),
            ),
          ),
          Text(
            'STEP ${stepIndex + 1}/$totalSteps',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: c.secondary,
            ),
          ),
          IconButton(
            onPressed: isSubmitting ? null : onClose,
            icon: Icon(Icons.close_rounded, color: c.hint),
          ),
        ],
      ),
    );

    final dots = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _StepDots(current: stepIndex, total: totalSteps),
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(stepIndex),
          child: stepContent,
        ),
      ),
    );

    final footer = SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: c.scaffold,
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            if (onPrevious != null) ...[
              OutlinedButton(
                onPressed: isSubmitting ? null : onPrevious,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(color: c.headline, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
            ],
            if (onSkip != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onSkip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: c.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    skipLabel ?? 'Skip',
                    style: TextStyle(color: c.secondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: isSubmitting ? null : onNext,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        nextLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    // Rather than a Column with a rigidly `Expanded` middle section (which
    // overflows if the header/dots/footer chrome alone doesn't fit the
    // space left after the keyboard shrinks the sheet on smaller screens),
    // the whole body scrolls as one unit. `spaceBetween` still pins the
    // footer to the bottom whenever there's enough room, and the
    // `ConstrainedBox` + `SingleChildScrollView` combo guarantees this can
    // never overflow — it just becomes scrollable instead.
    //
    // The sheet's own box (see `_QuickWizardSheetChrome`) is a fixed size,
    // no longer reduced by the keyboard. We still need the *scrollable
    // viewport* itself (not just its content/padding) to shrink by the
    // keyboard height though: Flutter's "scroll the focused field into
    // view" logic and manual scrolling both reason about what's visible
    // relative to the Scrollable's own size, not the keyboard. Sizing the
    // viewport to (box height - keyboard height) leaves an inert gap below
    // it exactly where the keyboard sits, so fields/the footer scroll to a
    // position that's genuinely visible above the keyboard instead of
    // just being "off the end" of a viewport that doesn't know better.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight =
            (constraints.maxHeight - keyboardInset).clamp(0.0, constraints.maxHeight);
        return Column(
          children: [
            SizedBox(
              height: viewportHeight,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [header, dots, const SizedBox(height: 8), content],
                      ),
                      footer,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: active ? c.tokens.accent : c.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

/// Section label used above each step's input (consistent with existing forms).
Widget quickWizardLabel(BuildContext context, String text) {
  final c = FormSurfaceColors.of(context);
  return Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: c.headline,
    ),
  );
}

/// Larger step heading shown above the label/input for extra context.
Widget quickWizardHeading(BuildContext context, String text) {
  final c = FormSurfaceColors.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: c.headline,
      ),
    ),
  );
}

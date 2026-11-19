import 'package:flutter/material.dart';

import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_values.dart';

/// Page frame for one step of the sign-up wizard: back arrow, progress bar,
/// the step's question, and a single pinned primary action.
///
/// The progress bar animates between steps rather than jumping. Seeing the
/// remaining distance shrink is the whole mechanism — a bar that teleports
/// reads as a static label and does nothing to pull the host forward.
class SignupWizardScaffold extends StatelessWidget {
  const SignupWizardScaffold({
    super.key,
    required this.progress,
    required this.stepLabel,
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    required this.stepKey,
    required this.child,
    this.isBusy = false,
    this.footer,
  });

  final double progress;
  final String stepLabel;
  final VoidCallback onBack;
  final String primaryLabel;
  final Future<void> Function() onPrimary;

  /// Identifies the current step so the content can animate on change.
  final Object stepKey;
  final Widget child;
  final bool isBusy;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: isBusy ? null : onBack,
                icon: Icon(Icons.arrow_back_outlined, color: c.headline),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              const Spacer(),
              Text(
                stepLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: c.secondary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _ProgressBar(value: progress),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              // Outgoing step is removed from layout immediately so the two
              // steps do not stack into a double-height column mid-animation.
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(stepKey), child: child),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              children: [
                if (footer != null) ...[
                  footer!,
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  width: double.infinity,
                  height: AppValues.formButtonHeight + 6,
                  child: FilledButton(
                    onPressed: isBusy ? null : onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.tokens.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: c.tokens.accent.withValues(
                        alpha: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppValues.radius_12,
                        ),
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            primaryLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => LinearProgressIndicator(
          value: animated,
          minHeight: 6,
          backgroundColor: c.divider,
          valueColor: AlwaysStoppedAnimation(c.tokens.accent),
        ),
      ),
    );
  }
}

/// One question plus its inputs. Keeps the heading rhythm identical across
/// steps so only the content appears to change as the host advances.
class SignupStepBody extends StatelessWidget {
  const SignupStepBody({
    super.key,
    required this.question,
    required this.children,
    this.helper,
  });

  final String question;
  final String? helper;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.5,
            color: c.headline,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 10),
          Text(
            helper!,
            style: TextStyle(fontSize: 15, height: 1.45, color: c.secondary),
          ),
        ],
        const SizedBox(height: 28),
        ...children,
      ],
    );
  }
}

/// Large tappable answer used for the yes/no question, sized like a button so
/// the choice is as cheap to make as tapping Continue.
class SignupChoiceTile extends StatelessWidget {
  const SignupChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Material(
      color: selected ? c.tokens.accent : c.inputFill,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(
              color: selected ? c.tokens.accent : c.inputBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : c.headline,
            ),
          ),
        ),
      ),
    );
  }
}

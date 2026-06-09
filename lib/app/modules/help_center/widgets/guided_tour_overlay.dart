import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_tokens.dart';


/// Bottom coach-mark card for a single guided tour step.
class GuidedTourOverlay extends StatelessWidget {
  const GuidedTourOverlay({
    super.key,
    required this.guideTitle,
    required this.stepIndex,
    required this.stepCount,
    required this.stepTitle,
    required this.stepBody,
    required this.onNext,
    required this.onSkip,
    this.isSw = false,
  });

  final String guideTitle;
  final int stepIndex;
  final int stepCount;
  final String stepTitle;
  final String stepBody;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isSw;

  static const _teal = Color(0xFF005F5F);

  @override
  Widget build(BuildContext context) {
    final isLast = stepIndex >= stepCount - 1;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Material(
          color: isDark ? context.tokens.cardBackground : Colors.white,
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        guideTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark
                              ? const Color(0xFFAEAEB2)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Text(
                      '${stepIndex + 1} / $stepCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: stepCount <= 0 ? 0 : (stepIndex + 1) / stepCount,
                  backgroundColor: _teal.withValues(alpha: 0.15),
                  color: _teal,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  stepTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stepBody,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isDark
                        ? const Color(0xFFAEAEB2)
                        : const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      child: Text(isSw ? 'Ruka' : 'Skip tour'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isLast
                            ? (isSw ? 'Maliza' : 'Finish')
                            : (isSw ? 'Ifuatayo' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/change_pin_controller.dart';

class ChangePinView extends BaseView<ChangePinController> {
  ChangePinView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final tokens = context.tokens;
    return CustomAppBar(
      appBarTitleText: controller.remoteConfirmMode.value
          ? _t(context, en: 'Confirm PIN', sw: 'Thibitisha PIN')
          : controller.changePinMode.value
              ? _t(context, en: 'Change PIN', sw: 'Badilisha PIN')
              : _t(context, en: 'New PIN', sw: 'PIN Mpya'),
      isCentered: true,
      isBackButtonEnabled: false,
      leading: IconButton(
        tooltip: _t(context, en: 'Back', sw: 'Rudi'),
        icon: Icon(Icons.arrow_back_outlined, color: tokens.textPrimary),
        onPressed: controller.goBack,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final tokens = context.tokens;
    final surface = FormSurfaceColors.of(context);

    return Obx(() {
      final status = controller.pinStatus.value;
      final filled = controller.getCountsOfPIN();
      final mismatch = status == PINStatus.unequals;
      final copy = _copyFor(context, status);

      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _HeroIcon(
                    icon: copy.icon,
                    accent: mismatch ? AppColors.colorAlert : tokens.accent,
                    surface: surface,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    copy.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: tokens.textSecondary,
                    ),
                  ),
                  if (_showSetupSteps(status)) ...[
                    const SizedBox(height: 20),
                    _SetupSteps(
                      confirming: status == PINStatus.enterSecond,
                      tokens: tokens,
                      createLabel: _t(context, en: 'Create', sw: 'Tengeneza'),
                      confirmLabel: _t(context, en: 'Confirm', sw: 'Thibitisha'),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _PinSlots(
                    filled: filled,
                    mismatch: mismatch,
                    tokens: tokens,
                    surface: surface,
                  ),
                  if (controller.isVerifyingRemotePin.value) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: tokens.accent,
                      ),
                    ),
                  ],
                  if (mismatch) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: controller.retryAfterMismatch,
                      child: Text(
                        _t(context, en: 'Try again', sw: 'Jaribu tena'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: tokens.accent,
                        ),
                      ),
                    ),
                  ],
                  if ((controller.remoteConfirmError.value ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      controller.remoteConfirmError.value!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.colorAlert,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _Keypad(
              surface: surface,
              tokens: tokens,
              enabled: !controller.isVerifyingRemotePin.value && !mismatch,
              onDigit: (n) {
                HapticFeedback.selectionClick();
                controller.setPIN(n);
              },
              onErase: () {
                HapticFeedback.selectionClick();
                controller.erase();
              },
            ),
          ),
          if (controller.remoteConfirmMode.value)
            TextButton(
              onPressed: controller.forgotRemotePin,
              child: Text(
                _t(
                  context,
                  en: 'Forgot PIN? Set a new one',
                  sw: 'Umesahau PIN? Weka mpya',
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: tokens.accent,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          const SizedBox(height: 4),
        ],
      );
    });
  }

  bool _showSetupSteps(PINStatus status) {
    if (controller.remoteConfirmMode.value) return false;
    return status == PINStatus.enterFirst || status == PINStatus.enterSecond;
  }

  _PinCopy _copyFor(BuildContext context, PINStatus status) {
    switch (status) {
      case PINStatus.confirmRemote:
        return _PinCopy(
          icon: Icons.lock_open_outlined,
          title: _t(context, en: 'Welcome back', sw: 'Karibu tena'),
          subtitle: _t(
            context,
            en: 'Enter your 4-digit PIN to continue.',
            sw: 'Weka PIN yenye tarakimu 4 ili kuendelea.',
          ),
        );
      case PINStatus.verifyCurrent:
        return _PinCopy(
          icon: Icons.lock_reset_outlined,
          title: _t(context, en: 'Current PIN', sw: 'PIN ya sasa'),
          subtitle: _t(
            context,
            en: 'Enter your existing PIN before choosing a new one.',
            sw: 'Weka PIN yako ya sasa kabla ya kuchagua mpya.',
          ),
        );
      case PINStatus.enterSecond:
        return _PinCopy(
          icon: Icons.verified_user_outlined,
          title: _t(context, en: 'Confirm your PIN', sw: 'Thibitisha PIN'),
          subtitle: _t(
            context,
            en: 'Enter the same 4 digits once more.',
            sw: 'Weka tarakimu 4 zilezile tena.',
          ),
        );
      case PINStatus.unequals:
        return _PinCopy(
          icon: Icons.error_outline,
          title: _t(context, en: 'PINs don’t match', sw: 'PIN hazilingani'),
          subtitle: _t(
            context,
            en: 'Both entries must be the same. Try again.',
            sw: 'Ingizo zote lazima zifanane. Jaribu tena.',
          ),
        );
      case PINStatus.equals:
      case PINStatus.enterFirst:
        return _PinCopy(
          icon: Icons.lock_outline,
          title: _t(context, en: 'Create a PIN', sw: 'Tengeneza PIN'),
          subtitle: _t(
            context,
            en: 'Choose 4 digits to unlock Host Bora on this device.',
            sw: 'Chagua tarakimu 4 kufungua Host Bora kwenye kifaa hiki.',
          ),
        );
    }
  }
}

class _PinCopy {
  const _PinCopy({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({
    required this.icon,
    required this.accent,
    required this.surface,
  });

  final IconData icon;
  final Color accent;
  final FormSurfaceColors surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: surface.isDark ? 0.18 : 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, size: 34, color: accent),
    );
  }
}

class _SetupSteps extends StatelessWidget {
  const _SetupSteps({
    required this.confirming,
    required this.tokens,
    required this.createLabel,
    required this.confirmLabel,
  });

  final bool confirming;
  final AppThemeTokens tokens;
  final String createLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepChip(
          label: createLabel,
          done: confirming,
          active: !confirming,
          tokens: tokens,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: 28,
            child: Divider(color: tokens.border, thickness: 1.2),
          ),
        ),
        _StepChip(
          label: confirmLabel,
          done: false,
          active: confirming,
          tokens: tokens,
        ),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.done,
    required this.active,
    required this.tokens,
  });

  final String label;
  final bool done;
  final bool active;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = done || active ? tokens.accent : tokens.textMuted;
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? tokens.accent : Colors.transparent,
            border: Border.all(color: color, width: 1.4),
          ),
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PinSlots extends StatelessWidget {
  const _PinSlots({
    required this.filled,
    required this.mismatch,
    required this.tokens,
    required this.surface,
  });

  final int filled;
  final bool mismatch;
  final AppThemeTokens tokens;
  final FormSurfaceColors surface;

  @override
  Widget build(BuildContext context) {
    final border = mismatch ? AppColors.colorAlert : tokens.border;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 56,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isFilled
                ? tokens.accent.withValues(alpha: surface.isDark ? 0.2 : 0.1)
                : surface.inputFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFilled
                  ? (mismatch ? AppColors.colorAlert : tokens.accent)
                  : border,
              width: isFilled ? 1.6 : 1.2,
            ),
          ),
          child: Center(
            child: AnimatedScale(
              scale: isFilled ? 1 : 0.4,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? (mismatch ? AppColors.colorAlert : tokens.accent)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.surface,
    required this.tokens,
    required this.enabled,
    required this.onDigit,
    required this.onErase,
  });

  final FormSurfaceColors surface;
  final AppThemeTokens tokens;
  final bool enabled;
  final ValueChanged<int> onDigit;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(AppValues.radius),
        border: Border.all(color: surface.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: surface.isDark ? 0.22 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          children: [
            _row(['1', '2', '3']),
            const SizedBox(height: 8),
            _row(['4', '5', '6']),
            const SizedBox(height: 8),
            _row(['7', '8', '9']),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(child: _key('0')),
                Expanded(
                  child: _Key(
                    enabled: enabled,
                    onTap: onErase,
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 22,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      children: digits.map((d) => Expanded(child: _key(d))).toList(),
    );
  }

  Widget _key(String digit) {
    return _Key(
      enabled: enabled,
      onTap: () => onDigit(int.parse(digit)),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: tokens.textPrimary,
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.colorPrimary.withValues(alpha: 0.12),
          highlightColor: AppColors.colorPrimary.withValues(alpha: 0.06),
          child: SizedBox(
            height: 56,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

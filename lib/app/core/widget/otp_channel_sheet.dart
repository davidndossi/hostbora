import 'package:flutter/material.dart';

import '../theme/app_theme_tokens.dart';
import '../values/app_colors.dart';
import '../values/app_values.dart';

/// Returns `EMAIL` or `SMS`, or null if dismissed.
/// WhatsApp is shown as coming soon (not selectable).
Future<String?> showOtpChannelSheet(
  BuildContext context, {
  required bool isSw,
  bool emailAvailable = true,
  String? phone,
  String? email,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.tokens.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final platformType = Typography.material2021(
        platform: Theme.of(ctx).platform,
      );
      final readableType = Theme.of(ctx).brightness == Brightness.dark
          ? platformType.white
          : platformType.black;
      return Theme(
        // Theme fontFamily is "Roboto" but the family is not bundled, so
        // iOS drops the space glyph. Use the platform typeface here.
        data: Theme.of(ctx).copyWith(
          textTheme: readableType.apply(
            bodyColor: ctx.tokens.textPrimary,
            displayColor: ctx.tokens.textPrimary,
            fontFamilyFallback: const [
              '.AppleSystemUIFont',
              'Helvetica Neue',
              'sans-serif',
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: _OtpChannelSheetBody(
              isSw: isSw,
              emailAvailable: emailAvailable,
              phone: phone,
              email: email,
            ),
          ),
        ),
      );
    },
  );
}

class _OtpChannelSheetBody extends StatelessWidget {
  const _OtpChannelSheetBody({
    required this.isSw,
    required this.emailAvailable,
    this.phone,
    this.email,
  });

  final bool isSw;
  final bool emailAvailable;
  final String? phone;
  final String? email;

  String get _prettyPhone {
    final raw = (phone ?? '').trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && digits.startsWith('0')) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    if (digits.length == 12 && digits.startsWith('255')) {
      return '+255 ${digits.substring(3, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final smsDestination = _prettyPhone.isNotEmpty
        ? _prettyPhone
        : (isSw ? 'Namba yako ya simu' : 'Your phone number');
    final emailDestination = (email ?? '').trim().isNotEmpty
        ? email!.trim()
        : (emailAvailable
            ? (isSw ? 'Barua pepe iliyosajiliwa' : 'Email on this account')
            : (isSw
                ? 'Hakuna barua pepe kwenye akaunti hii'
                : 'No email on this account'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.colorPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.colorPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSw ? 'Tuma msimbo wa kuingia' : 'Send your login code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSw
                        ? 'Chagua njia ya kupokea OTP ya tarakimu 4.'
                        : 'Choose where we should send the 4-digit OTP.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ChannelCard(
          icon: Icons.sms_rounded,
          title: 'SMS',
          destination: smsDestination,
          badge: isSw ? 'Inapendekezwa' : 'Recommended',
          emphasized: true,
          enabled: true,
          onTap: () => Navigator.pop(context, 'SMS'),
        ),
        if (emailAvailable) ...[
          const SizedBox(height: 10),
          _ChannelCard(
            icon: Icons.mail_outline_rounded,
            title: isSw ? 'Barua pepe' : 'Email',
            destination: emailDestination,
            emphasized: false,
            enabled: true,
            onTap: () => Navigator.pop(context, 'EMAIL'),
          ),
        ],
        const SizedBox(height: 14),
        _WhatsAppSoonRow(isSw: isSw),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.icon,
    required this.title,
    required this.destination,
    required this.emphasized,
    required this.enabled,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String destination;
  final String? badge;
  final bool emphasized;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final borderColor = emphasized
        ? AppColors.colorPrimary.withValues(alpha: 0.35)
        : tokens.border;
    final fill = !enabled
        ? tokens.scaffoldBackground
        : emphasized
            ? AppColors.colorPrimary.withValues(alpha: 0.08)
            : tokens.cardBackground;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.colorPrimary.withValues(alpha: 0.14)
                      : tokens.border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled
                      ? AppColors.colorPrimary
                      : tokens.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: enabled
                                  ? tokens.textPrimary
                                  : tokens.textMuted,
                            ),
                          ),
                        ),
                        if (badge != null && enabled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.colorPrimary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: enabled
                            ? tokens.textSecondary
                            : tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: tokens.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppSoonRow extends StatelessWidget {
  const _WhatsAppSoonRow({required this.isSw});

  final bool isSw;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.scaffoldBackground,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_outlined, size: 18, color: tokens.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'WhatsApp',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textMuted,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSw ? 'Inakuja' : 'Soon',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

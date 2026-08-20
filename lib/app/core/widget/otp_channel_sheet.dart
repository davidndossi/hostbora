import 'package:flutter/material.dart';

import '../values/app_colors.dart';

/// Returns `EMAIL` or `SMS`, or null if dismissed.
/// WhatsApp is shown as coming soon (not selectable).
Future<String?> showOtpChannelSheet(
  BuildContext context, {
  required bool isSw,
  bool emailAvailable = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSw ? 'Pokea msimbo wapi?' : 'Where should we send the code?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSw
                    ? 'Chagua njia ya kupokea OTP ya tarakimu 4'
                    : 'Choose how to receive your 4-digit OTP',
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _ChannelTile(
                icon: Icons.sms_outlined,
                title: 'SMS',
                subtitle: isSw
                    ? 'Tuma kwa namba yako ya simu'
                    : 'Send to your phone number',
                enabled: true,
                onTap: () => Navigator.pop(ctx, 'SMS'),
              ),
              const SizedBox(height: 10),
              _ChannelTile(
                icon: Icons.email_outlined,
                title: isSw ? 'Barua pepe' : 'Email',
                subtitle: emailAvailable
                    ? (isSw
                        ? 'Tuma kwa barua pepe ya akaunti'
                        : 'Send to your account email')
                    : (isSw
                        ? 'Hakuna barua pepe kwenye akaunti hii'
                        : 'No email on this account'),
                enabled: emailAvailable,
                onTap: emailAvailable ? () => Navigator.pop(ctx, 'EMAIL') : null,
              ),
              const SizedBox(height: 10),
              _ChannelTile(
                icon: Icons.chat_outlined,
                title: 'WhatsApp',
                subtitle: isSw ? 'Inakuja hivi karibuni' : 'Coming soon',
                enabled: false,
                onTap: null,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: enabled
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.colorPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: enabled
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

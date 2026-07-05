import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/service/subscription_service.dart';
import '../../routes/app_pages.dart';

/// Which subscription tier a feature requires.
enum RequiredPlan { any, pro, ultra }

/// Checks whether the current user's subscription meets the [required] tier.
///
/// Usage:
/// ```dart
/// // Block feature entirely:
/// if (!PlanGate.check(RequiredPlan.pro)) {
///   PlanGate.showUpgradeSheet(RequiredPlan.pro, featureName: 'SMS / WhatsApp');
///   return;
/// }
///
/// // Or inline in a button:
/// onPressed: PlanGate.guard(RequiredPlan.pro, featureName: 'Staff tools', () { ... })
/// ```
class PlanGate {
  PlanGate._();

  static SubscriptionService get _svc => Get.find<SubscriptionService>();

  /// Returns true if the user's active plan satisfies [required].
  static bool check(RequiredPlan required) {
    final svc = _svc;
    if (!svc.isActive) return false;
    switch (required) {
      case RequiredPlan.any:   return true;
      case RequiredPlan.pro:   return svc.isProOrAbove;
      case RequiredPlan.ultra: return svc.isUltra;
    }
  }

  /// Shows an upgrade bottom sheet and navigates to the subscription page.
  static void showUpgradeSheet(
    RequiredPlan required, {
    required String featureName,
    String? subtitle,
  }) {
    final ctx = Get.context;
    if (ctx == null) return;

    final planName = required == RequiredPlan.ultra ? 'Ultra' : 'Pro';

    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UpgradeSheet(
        featureName: featureName,
        subtitle: subtitle ??
            '$featureName requires the $planName plan or above.',
        planName: planName,
      ),
    );
  }

  /// Wraps [action] with a plan check. If the check fails, shows the upgrade sheet.
  static VoidCallback guard(
    RequiredPlan required, {
    required String featureName,
    required VoidCallback action,
  }) {
    return () {
      if (check(required)) {
        action();
      } else {
        showUpgradeSheet(required, featureName: featureName);
      }
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet({
    required this.featureName,
    required this.subtitle,
    required this.planName,
  });

  final String featureName;
  final String subtitle;
  final String planName;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Lock icon
          const Center(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF1C6E64),
              child: Icon(Icons.lock_outline, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            '$featureName requires $planName',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF9FA4B0)),
          ),
          const SizedBox(height: 24),

          // CTA
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed(Routes.SUBSCRIPTION);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C6E64),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Upgrade to $planName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/app/core/access/plan_loss_snapshot.dart';
import '/app/data/local/service/currency_service.dart';
import '/app/data/service/subscription_service.dart';
import '/app/routes/app_pages.dart';

/// Home banner for a plan inside its last week, stating the consequence
/// rather than the renewal.
///
/// The notification sent by `PlanExpiryWarningService` fires once per
/// threshold; this is the standing version of the same fact, present for as
/// long as the deadline is. It is intentionally not dismissible — it appears
/// only inside seven days of a real dated loss and disappears on its own once
/// the plan renews.
class PlanExpiryBanner extends StatefulWidget {
  const PlanExpiryBanner({super.key});

  /// Days remaining at which the banner starts appearing.
  static const windowDays = 7;

  @override
  State<PlanExpiryBanner> createState() => _PlanExpiryBannerState();
}

class _PlanExpiryBannerState extends State<PlanExpiryBanner> {
  PlanLossSnapshot? _loss;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await PlanLossSnapshot.load();
    if (mounted) setState(() => _loss = snapshot);
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SubscriptionService>()) {
      return const SizedBox.shrink();
    }
    final service = Get.find<SubscriptionService>();

    return Obx(() {
      final sub = service.status.value;
      // An expired plan has already taken the loss, and 'loading' is not yet
      // known to be anything — neither is a warning.
      if (!sub.isActive) return const SizedBox.shrink();

      final end = sub.currentPeriodEnd ?? sub.trialEndAt;
      if (end == null) return const SizedBox.shrink();

      final days = sub.daysLeft;
      if (days > PlanExpiryBanner.windowDays) return const SizedBox.shrink();

      final urgent = days <= 3;
      final accent = urgent ? const Color(0xFFDC2626) : const Color(0xFFD97706);
      final dark = Theme.of(context).brightness == Brightness.dark;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => Get.toNamed(Routes.SUBSCRIPTION),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.timer_outlined, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline(sub.isTrial, sub.plan, days),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark
                              ? const Color(0xFFF2F2F7)
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _consequence(sub.periodEndDisplay),
                        style: TextStyle(fontSize: 12, color: accent),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_outlined,
                  size: 20,
                  color: dark
                      ? const Color(0xFFAEAEB2)
                      : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _headline(bool isTrial, String plan, int days) {
    final label = isTrial
        ? (_isSw ? 'Jaribio lako' : 'Your free trial')
        : (_isSw
              ? 'Mpango wa ${_planLabel(plan)}'
              : '${_planLabel(plan)} plan');
    if (days <= 0) {
      return _isSw ? '$label inaisha leo' : '$label ends today';
    }
    if (days == 1) {
      return _isSw ? '$label inaisha kesho' : '$label ends tomorrow';
    }
    return _isSw
        ? '$label inaisha baada ya siku $days'
        : '$label ends in $days days';
  }

  /// Only lists consequences the host actually has. A single-property host
  /// with no back history is told about the features and nothing more.
  String _consequence(String endDisplay) {
    final loss = _loss;
    if (loss == null) {
      return _isSw ? 'Gusa kuona kitakachobadilika' : 'Tap to see what changes';
    }

    final parts = <String>[];
    if (loss.propertyCount > 1) {
      parts.add(
        _isSw
            ? 'mali ${loss.propertyCount} zitapungua kuwa 1'
            : '${loss.propertyCount} properties drop to 1',
      );
    }
    if (loss.hiddenRecordCount > 0) {
      final money = _money(loss.hiddenIncomeTotal + loss.hiddenExpenseTotal);
      parts.add(
        _isSw
            ? 'kumbukumbu ${loss.hiddenRecordCount} ($money) zitafichwa'
            : '${loss.hiddenRecordCount} records ($money) hide',
      );
    }

    if (parts.isEmpty) {
      return _isSw
          ? 'Baada ya $endDisplay ripoti na ukumbusho zitazimwa'
          : 'After $endDisplay reports and reminders switch off';
    }
    final and = _isSw ? ' na ' : ' and ';
    final list = parts.length == 1
        ? parts.first
        : '${parts.sublist(0, parts.length - 1).join(', ')}$and${parts.last}';
    return _isSw ? 'Baada ya $endDisplay: $list' : 'After $endDisplay: $list';
  }

  String _money(double amount) {
    if (Get.isRegistered<CurrencyService>()) {
      try {
        return Get.find<CurrencyService>().formatBase(amount);
      } catch (_) {}
    }
    return amount.toStringAsFixed(0);
  }

  static String _planLabel(String plan) {
    switch (plan.trim().toLowerCase()) {
      case 'ultra':
        return 'Ultra';
      case 'pro':
        return 'Pro';
      case 'starter':
        return 'Starter';
      default:
        return 'Your';
    }
  }
}

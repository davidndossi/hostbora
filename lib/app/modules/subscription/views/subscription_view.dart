import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/service/subscription_service.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionView extends BaseView<SubscriptionController> {
  SubscriptionView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
        appBarTitleText: 'HostBora Plans',
        isCentered: true,
        actions: [
          Obx(() {
            final busy = controller.startingCheckout.value ||
                controller.activatingTrial.value;
            return busy
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: controller.refresh,
                  );
          }),
        ],
      );

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final sub = controller.currentStatus;

      return ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppValues.padding,
          vertical: AppValues.largePadding,
        ),
        children: [
          // ── Status banner ──────────────────────────────────────
          if (sub.isActive) _StatusBanner(sub: sub),
          if (sub.isActive) const SizedBox(height: AppValues.spacing_20),

          // ── Header ────────────────────────────────────────────
          Text(
            sub.isActive ? 'Your Plan' : 'Choose a Plan',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: AppValues.halfPadding),
          Text(
            sub.isActive
                ? 'Upgrade or manage your subscription below.'
                : 'Start with a free 30-day trial. No credit card required.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: AppValues.spacing_20),

          // ── Plan cards ────────────────────────────────────────
          ...hostBoraPlanInfos.map((plan) => _PlanCard(
                info: plan,
                isCurrentPlan: sub.isActive && sub.plan == plan.key,
                priceOverride: controller.priceLabel(plan.key),
                usesAppleIap: controller.usesAppleIap,
                onSubscribe: controller.startingCheckout.value
                    ? null
                    : () => controller.subscribe(plan.key),
              )),

          const SizedBox(height: AppValues.spacing_20),

          // ── Trial CTA ─────────────────────────────────────────
          if (!sub.isActive) ...[
            _TrialCard(
              loading: controller.activatingTrial.value,
              onActivate: controller.requestTrial,
            ),
            const SizedBox(height: AppValues.spacing_20),
          ],

          // ── Restore purchases (iOS) ───────────────────────────
          if (controller.usesAppleIap) ...[
            TextButton(
              onPressed: controller.startingCheckout.value
                  ? null
                  : controller.restorePurchases,
              child: const Text('Restore Purchases'),
            ),
            const SizedBox(height: AppValues.spacing_20),
          ],

          // ── Footer note ───────────────────────────────────────
          Text(
            controller.usesAppleIap
                ? 'Subscriptions are billed through your Apple ID and auto-renew monthly. '
                    'Manage or cancel in Settings → Apple ID → Subscriptions.'
                : 'Payments processed securely via Snippe. Subscriptions auto-renew monthly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppValues.largePadding),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.sub});
  final dynamic sub; // SubscriptionStatus

  @override
  Widget build(BuildContext context) {
    final isTrial = sub.isTrial as bool;
    final color = isTrial ? AppColors.colorYellow : AppColors.colorSuccessGreen;
    final icon  = isTrial ? Icons.timer_outlined : Icons.check_circle_outline;
    final label = isTrial
        ? 'Free trial · ${sub.daysLeft} days left'
        : '${sub.plan.toString().toUpperCase()} active · ${sub.daysLeft} days left';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppValues.padding,
        vertical: AppValues.smallPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppValues.smallRadius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.info,
    required this.isCurrentPlan,
    required this.onSubscribe,
    this.priceOverride,
    this.usesAppleIap = false,
  });

  final PlanInfo info;
  final bool isCurrentPlan;
  final VoidCallback? onSubscribe;
  final String? priceOverride;
  final bool usesAppleIap;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isCurrentPlan ? AppColors.colorPrimary : AppColors.textColorSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppValues.padding),
      child: Card(
        elevation: isCurrentPlan || info.isPopular ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppValues.radius),
          side: isCurrentPlan
              ? const BorderSide(color: AppColors.colorPrimary, width: 2)
              : info.isPopular
                  ? const BorderSide(color: AppColors.colorSecondary, width: 1.5)
                  : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppValues.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + badge row
              Row(
                children: [
                  Text(
                    info.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? theme.colorScheme.onSurface : AppColors.textColorPrimary,
                    ),
                  ),
                  if (info.isPopular) ...[
                    const SizedBox(width: 8),
                    _Badge(label: 'Most Popular', color: AppColors.colorSecondary),
                  ],
                  if (isCurrentPlan) ...[
                    const SizedBox(width: 8),
                    _Badge(label: 'Your Plan', color: AppColors.colorPrimary),
                  ],
                  const Spacer(),
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceOverride ?? info.priceFormatted,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? theme.colorScheme.onSurface : AppColors.textColorPrimary,
                        ),
                      ),
                      Text(
                        usesAppleIap ? 'per month (App Store)' : 'per month',
                        style: const TextStyle(fontSize: 12, color: AppColors.textColorSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                info.tagline,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textColorSecondary,
                ),
              ),
              const Divider(height: AppValues.spacing_20),

              // Features
              ...info.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16, color: AppColors.colorPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppValues.padding),

              // Action button
              SizedBox(
                width: double.infinity,
                height: AppValues.formButtonHeight,
                child: isCurrentPlan
                    ? OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.colorPrimary),
                          foregroundColor: AppColors.colorPrimary,
                        ),
                        child: const Text('Current Plan'),
                      )
                    : ElevatedButton(
                        onPressed: onSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.colorPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          usesAppleIap
                              ? 'Subscribe — ${priceOverride ?? 'App Store'}'
                              : 'Subscribe — ${info.priceFormatted}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TrialCard extends StatelessWidget {
  const _TrialCard({required this.loading, required this.onActivate});
  final bool loading;
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppValues.padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.colorPrimary, AppColors.colorPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppValues.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Try HostBora free for 30 days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Get full Starter access with no payment details required. '
            'Upgrade any time before or after the trial ends.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: AppValues.padding),
          SizedBox(
            height: AppValues.formButtonHeight,
            child: ElevatedButton(
              onPressed: loading ? null : onActivate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.colorPrimary,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.colorPrimary,
                      ),
                    )
                  : const Text(
                      'Start Free Trial',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppValues.smallRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../controllers/ai_pricing_optimizer_controller.dart';

/// Pricing Rules screen — teal `#149C95`, cream `#F8F7F4`, navy `#0B1320`.
class AiPricingOptimizerView extends BaseView<AiPricingOptimizerController> {
  AiPricingOptimizerView({super.key});

  static const Color _kBg = Color(0xFFF8F7F4);
  static const Color _kTeal = Color(0xFF149C95);
  static const Color _kNavy = Color(0xFF0B1320);
  static const Color _kTitleNavy = Color(0xFF1B2838);
  static const Color _kMuted = Color(0xFF6B7280);
  static const Color _kBadgePosBg = Color(0xFFE8F5F4);
  static const Color _kBadgeNegBg = Color(0xFFFFF4ED);
  static const Color _kBadgeNegFg = Color(0xFFC45C2A);

  @override
  Color pageBackgroundColor(BuildContext context) => _kBg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBarRow(context),
                  const SizedBox(height: 20),
                  Text(
                    'Pricing Rules',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _kTitleNavy,
                      fontFamily: 'Times New Roman',
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Configure how the AI adjusts your nightly rates based on market demand.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: _kMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...List.generate(
                    controller.rules.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ruleCard(i),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _simulationCard(context),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        _buildBottomNav(context),
      ],
    );
  }

  Widget _buildAppBarRow(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: Get.back,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _kTitleNavy),
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 18, color: _kTeal),
              const SizedBox(width: 6),
              Text(
                'AI POWERED',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: _kTeal,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: controller.addRule,
          icon: const Icon(Icons.add_circle_outline, color: _kTeal, size: 26),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }

  Widget _ruleCard(int index) {
    final rule = controller.rules[index];
    final badgePositive = rule.positiveBadge;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgePositive ? _kBadgePosBg : _kBadgeNegBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rule.badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgePositive ? _kTeal : _kBadgeNegFg,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rule.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTitleNavy,
                  ),
                ),
              ),
              Obx(
                () => Switch(
                  value: controller.ruleEnabled[index].value,
                  onChanged: (v) => controller.setRuleEnabled(index, v),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return Colors.grey.shade400;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _kTeal.withValues(alpha: 0.55);
                    }
                    return Colors.grey.shade300;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rule.description,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => controller.editRule(index),
            style: TextButton.styleFrom(
              foregroundColor: _kTeal,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.edit_outlined, size: 16, color: _kTeal),
            label: const Text(
              'Edit Rule',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simulationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            top: -12,
            child: Icon(
              Icons.calculate_outlined,
              size: 100,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: Colors.white.withValues(alpha: 0.9), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Price Simulation',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(
                () => Material(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => controller.pickSimulationDate(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18, color: Colors.white.withValues(alpha: 0.85)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SAMPLE DATE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.formattedSimulationDate,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...controller.simulationLines.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            line.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: line.isBase
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          line.amount,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: line.isBase
                                ? Colors.white.withValues(alpha: 0.7)
                                : _kTeal,
                          ),
                        ),
                      ],
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${controller.estimatedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.applySettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 22),
                  label: const Text(
                    'Apply Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    Widget item(IconData icon, String label, bool active, VoidCallback onTap) {
      final c = active ? _kTeal : _kMuted;
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: c),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: c),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            item(Icons.grid_view_rounded, 'Overview', false, controller.goOverview),
            item(Icons.calendar_today_outlined, 'Calendar', false, controller.goCalendar),
            item(Icons.payments_outlined, 'Pricing', true, () {}),
            item(Icons.insights_outlined, 'Insights', false, controller.goInsights),
            item(Icons.person_outline, 'Profile', false, controller.goProfile),
          ],
        ),
      ),
    );
  }
}

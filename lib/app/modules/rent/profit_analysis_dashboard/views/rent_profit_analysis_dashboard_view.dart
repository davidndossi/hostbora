import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_profit_analysis_dashboard_controller.dart';

/// Financial Analysis — cream `#F8F7F2`, teal `#005B5C`, editorial serif headers.
abstract class _ProfitPalette {
  static const Color teal = Color(0xFF005B5C);
  static const Color navy = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE8E6E1);
  static const Color chartGray = Color(0xFFD9D6D0);
  static const Color deviationBg = Color(0xFFFBE4DB);
  static const Color deviationFg = Color(0xFF5C4033);
  static const Color expenseTag = Color(0xFF8B4513);
}

class RentProfitAnalysisDashboardView extends BaseView<RentProfitAnalysisDashboardController> {
  RentProfitAnalysisDashboardView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Financial Analysis');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryCard(
            label: 'TARGET PROFIT',
            value: 'Tsh 12,450,000',
            subtext: 'Based on 92% occupancy projection',
            subItalic: true,
            icon: Icons.bar_chart_rounded,
            iconBg: const Color(0xFFE8F3F2),
          ),
          const SizedBox(height: 12),
          _summaryCard(
            label: 'ACTUAL PROFIT',
            value: 'Tsh 10,120,500',
            subtext: 'Net after all overheads',
            subItalic: false,
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFFE8F3F2),
          ),
          const SizedBox(height: 12),
          _deviationCard(),
          const SizedBox(height: 20),
          _varianceChartCard(),
          const SizedBox(height: 20),
          _aiInsightsCard(),
          const SizedBox(height: 24),
          _expenseSectionHeader(),
          const SizedBox(height: 12),
          _expenseLineItem(
            icon: Icons.plumbing_outlined,
            iconBg: const Color(0xFFFFE4E1),
            title: 'Emergency Plumbing',
            meta: 'Sunset Villa • Apr 12',
            amount: 'Tsh 850,000',
            tag: 'UNPLANNED',
          ),
          const SizedBox(height: 10),
          _expenseLineItem(
            icon: Icons.kitchen_outlined,
            iconBg: const Color(0xFFFFE4E1),
            title: 'Commercial Fridge Replacement',
            meta: 'Beach House • Mar 28',
            amount: 'Tsh 2,100,000',
            tag: 'ASSET LOSS',
          ),
          const SizedBox(height: 10),
          _expenseLineItem(
            icon: Icons.water_drop_outlined,
            iconBg: const Color(0xFFFFE4E1),
            title: 'Water & Utilities Spike',
            meta: 'Evergreen Estate • Apr 1',
            amount: 'Tsh 420,000',
            tag: 'USAGE VARIANCE',
          ),
          const SizedBox(height: 16),
          _managerTipCard(),
        ],
      ),
    );
  }

  static Widget _summaryCard({
    required String label,
    required String value,
    required String subtext,
    required bool subItalic,
    required IconData icon,
    required Color iconBg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _ProfitPalette.teal, size: 22),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: _ProfitPalette.muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _ProfitPalette.navy,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 12,
                  color: _ProfitPalette.muted,
                  fontStyle: subItalic ? FontStyle.italic : FontStyle.normal,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deviationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ProfitPalette.deviationBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.warning_amber_rounded, color: _ProfitPalette.deviationFg, size: 26),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEVIATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: _ProfitPalette.deviationFg.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '- Tsh 2,329,500',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _ProfitPalette.deviationFg,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '18.7% variance from target',
                style: TextStyle(
                  fontSize: 12,
                  color: _ProfitPalette.deviationFg.withValues(alpha: 0.95),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _varianceChartCard() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    // Actual as fraction of target per month (visual).
    const actualRatios = [0.88, 0.92, 0.79, 0.85, 0.78, 0.91];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ProfitPalette.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profit Variance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ProfitPalette.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monthly Performance Comparison',
            style: TextStyle(fontSize: 12, color: _ProfitPalette.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _legendDot(const Color(0xFFC8C5BE), 'Target'),
              const SizedBox(width: 20),
              _legendDot(_ProfitPalette.teal, 'Actual'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _VarianceBar(
                      actualRatio: actualRatios[i],
                      month: months[i],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ProfitPalette.muted),
        ),
      ],
    );
  }

  Widget _aiInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ProfitPalette.teal,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _ProfitPalette.teal.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.95), size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.98),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Maintenance costs were 15% higher this month due to three emergency call-outs. '
              "Property 'Sunset Villa' required unexpected HVAC repair.",
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.95),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Recommendation: Implement quarterly preventive HVAC checks to reduce emergency premium rates by estimated 22%.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.onApplyStrategy,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8E0DE),
                foregroundColor: _ProfitPalette.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Apply Strategy',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            'Expense Breakdown',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _ProfitPalette.navy,
            ),
          ),
        ),
        Text(
          'Reviewing 5 Line Items',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _ProfitPalette.expenseTag,
          ),
        ),
      ],
    );
  }

  static Widget _expenseLineItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String meta,
    required String amount,
    required String tag,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFFB71C1C), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ProfitPalette.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(fontSize: 11, color: _ProfitPalette.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ProfitPalette.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: _ProfitPalette.expenseTag,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _managerTipCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/luxury_room_view.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: const Color(0xFFE8E4DD)),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manager Tip',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _ProfitPalette.muted,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Invest in smart sensors for 'Beach House' to cap utility spikes.",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ProfitPalette.navy,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VarianceBar extends StatelessWidget {
  const _VarianceBar({required this.actualRatio, required this.month});

  final double actualRatio;
  final String month;

  static const double _barMax = 110;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: _barMax,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: double.infinity,
                height: _barMax,
                decoration: BoxDecoration(
                  color: _ProfitPalette.chartGray,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: (_barMax * actualRatio).clamp(8.0, _barMax),
                decoration: BoxDecoration(
                  color: _ProfitPalette.teal,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          month,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _ProfitPalette.muted,
          ),
        ),
      ],
    );
  }
}

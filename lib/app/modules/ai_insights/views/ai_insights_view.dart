import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../routes/app_pages.dart';
import '../controllers/ai_insights_controller.dart';

class AiInsightsView extends BaseView<AiInsightsController> {
  AiInsightsView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  _buildAiSummary(context),
                  const SizedBox(height: 16),
                  _buildRevenueAnalysis(context),
                  const SizedBox(height: 16),
                  Text(
                    _t(context, en: 'Recommendations', sw: 'Mapendekezo'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRecommendations(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final period = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _circleIcon(
                context,
                Icons.arrow_back_ios_new_rounded,
                onTap: Get.back,
              ),
              Text(
                _t(context, en: 'AI Insights', sw: 'Maarifa ya AI'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_t(context, en: 'Performance Report', sw: 'Ripoti ya Utendaji')} • $period',
                style: TextStyle(
                  fontSize: 14,
                  color: context.tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0x190D6D6D),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: FormSurfaceColors.of(context).inputBorder,
            ),
          ),
          child: Icon(Icons.auto_awesome, color: AppColors.colorPrimary),
        ),
      ],
    );
  }

  Widget _buildAiSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FormSurfaceColors.of(context).isDark
            ? const Color(0xFF1F1F1F)
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: FormSurfaceColors.of(context).inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: SvgPicture.asset(
                    'images/ic_intelligence.svg',
                    width: 12,
                    height: 12,
                  ),
                ),
              ),
              Text(
                _t(context, en: 'AI Summary', sw: 'Muhtasari wa AI'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colorPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14.5,
                height: 1.65,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: _t(
                    context,
                    en: 'This week, occupancy is up ',
                    sw: 'Wiki hii, kiwango cha ukodishaji kimeongezeka ',
                  ),
                ),
                TextSpan(
                  text: '12%',
                  style: TextStyle(
                    color: AppColors.colorSuccessGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: _t(
                    context,
                    en: '. Guest sentiment remains high, specifically regarding your "Seamless Check-In" process. You are outperforming 85% of similar listings in your area.',
                    sw: '. Maoni ya wageni yanaendelea kuwa mazuri, hasa kuhusu mchakato wako wa "Kuingia Bila Usumbufu". Unafanya vizuri kuliko 85% ya matangazo yanayofanana katika eneo lako.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag(context, _t(context, en: '🚀 Growth', sw: '🚀 Ukuaji')),
              _tag(
                context,
                _t(context, en: '💧 High Satisfaction', sw: '💧 Kuridhika Juu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: FormSurfaceColors.of(context).isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.pageBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FormSurfaceColors.of(context).inputBorder,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: context.tokens.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRevenueAnalysis(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _t(context, en: 'Revenue Analysis', sw: 'Uchambuzi wa Mapato'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            _rangePill(context, 0, '1W'),
            const SizedBox(width: 6),
            _rangePill(context, 1, '1M'),
            const SizedBox(width: 6),
            _rangePill(context, 2, _t(context, en: 'All', sw: 'Zote')),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: FormSurfaceColors.of(context).isDark
                ? const Color(0xFF1F1F1F)
                : AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(
              color: FormSurfaceColors.of(context).inputBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            context,
                            en: 'TOTAL REVENUE',
                            sw: 'JUMLA YA MAPATO',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.tokens.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$4,250.00',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _t(
                            context,
                            en: '↗ 15.2% vs predicted',
                            sw: '↗ 15.2% dhidi ya makadirio',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.colorSuccessGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendDot(
                        context,
                        _t(context, en: 'PREDICTED', sw: 'MAKADIRIO'),
                        const Color(0xFF9EC8C1),
                      ),
                      const SizedBox(height: 4),
                      _legendDot(
                        context,
                        _t(context, en: 'ACTUAL', sw: 'HALISI'),
                        AppColors.colorPrimary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RevenueChartPainter(
                    controller.chartValues.toList(),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['MON', 'WED', 'FRI', 'SUN']
                    .map(
                      (d) => Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.tokens.textSecondary,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(BuildContext context, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: context.tokens.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _rangePill(BuildContext context, int index, String label) {
    return Obx(() {
      final selected = controller.selectedRange.value == index;
      return GestureDetector(
        onTap: () => controller.setRange(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? (FormSurfaceColors.of(context).isDark
                      ? const Color(0xFF1F1F1F)
                      : AppColors.colorWhite)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? (FormSurfaceColors.of(context).inputBorder)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : (context.tokens.textSecondary),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRecommendations(BuildContext context) {
    return Column(
      children: controller.recommendations.map((item) {
        final (badge, badgeColor) = switch (item.impact) {
          RecommendationImpact.highImpact => (
            'HIGH IMPACT',
            const Color(0xFFF3D89F),
          ),
          RecommendationImpact.observation => (
            'OBSERVATION',
            const Color(0xFFE1E7F8),
          ),
          RecommendationImpact.newItem => ('NEW', const Color(0xFFD9F4EA)),
        };
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FormSurfaceColors.of(context).isDark
                ? const Color(0xFF1F1F1F)
                : AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(
              color: FormSurfaceColors.of(context).inputBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FormSurfaceColors.of(context).isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: context.tokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.tokens.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            item.impact == RecommendationImpact.highImpact
                            ? () => Get.toNamed(Routes.PRICE_ANALYSIS)
                            : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              item.impact == RecommendationImpact.observation
                              ? Colors.white
                              : AppColors.colorPrimary,
                          foregroundColor:
                              item.impact == RecommendationImpact.observation
                              ? (context.tokens.textPrimary)
                              : Colors.white,
                          elevation: 0,
                          side: BorderSide(
                            color:
                                item.impact == RecommendationImpact.observation
                                ? (FormSurfaceColors.of(context).inputBorder)
                                : Colors.transparent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          item.cta,
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
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _circleIcon(
    BuildContext context,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: FormSurfaceColors.of(context).inputFill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: context.tokens.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  final List<double> values;

  _RevenueChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    Offset point(int i, double yVal) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - ((yVal - minV) / range) * (size.height - 8) - 4;
      return Offset(x, y);
    }

    final actual = Path();
    final predicted = Path();

    for (var i = 0; i < values.length; i++) {
      final p1 = point(i, values[i]);
      final p2 = point(i, values[i] - 8);
      if (i == 0) {
        actual.moveTo(p1.dx, p1.dy);
        predicted.moveTo(p2.dx, p2.dy);
      } else {
        actual.lineTo(p1.dx, p1.dy);
        predicted.lineTo(p2.dx, p2.dy);
      }
    }

    final fill = Path.from(actual)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.colorPrimary.withValues(alpha: 0.20),
          AppColors.colorPrimary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fill, fillPaint);

    final predPaint = Paint()
      ..color = const Color(0xFF9EC8C1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final actualPaint = Paint()
      ..color = AppColors.colorPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(predicted, predPaint);
    canvas.drawPath(actual, actualPaint);
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

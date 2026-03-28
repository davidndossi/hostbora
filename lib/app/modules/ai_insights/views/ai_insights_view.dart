import 'dart:math' as math;

import 'package:flutter/material.dart';
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
                  _buildAiSummary(),
                  const SizedBox(height: 16),
                  _buildRevenueAnalysis(),
                  const SizedBox(height: 16),
                  Text(
                    'Recommendations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRecommendations(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final period = DateFormat.yMMMM(Localizations.localeOf(context).toString())
        .format(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _circleIcon(Icons.arrow_back_ios_new_rounded, onTap: Get.back),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColorPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Performance Report • $period',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textColorSecondary,
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
            border: Border.all(color: AppColors.designInputBorder),
          ),
          child: Icon(Icons.auto_awesome, color: AppColors.colorPrimary),
        ),
      ],
    );
  }

  Widget _buildAiSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Center(child: SvgPicture.asset('images/ic_intelligence.svg', width: 12, height: 12))
              ),
              Text(
                'AI Summary',
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
                color: AppColors.textColorPrimary,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'This week, occupancy is up '),
                TextSpan(
                  text: '12%',
                  style: TextStyle(
                    color: AppColors.colorSuccessGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text:
                      '. Guest sentiment remains high, specifically regarding your "Seamless Check-In" process. You are outperforming 85% of similar listings in your area.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [_tag('🚀 Growth'), _tag('💧 High Satisfaction')],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textColorSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRevenueAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Revenue Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
              ),
            ),
            const Spacer(),
            _rangePill(0, '1W'),
            const SizedBox(width: 6),
            _rangePill(1, '1M'),
            const SizedBox(width: 6),
            _rangePill(2, 'All'),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(color: AppColors.designInputBorder),
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
                          'TOTAL REVENUE',
                          style: TextStyle(fontSize: 11, color: AppColors.textColorSecondary, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '\$4,250.00',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textColorPrimary),
                        ),
                        Text(
                          '↗ 15.2% vs predicted',
                          style: TextStyle(fontSize: 11, color: AppColors.colorSuccessGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendDot('PREDICTED', const Color(0xFF9EC8C1)),
                      const SizedBox(height: 4),
                      _legendDot('ACTUAL', AppColors.colorPrimary),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RevenueChartPainter(controller.chartValues.toList()),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['MON', 'WED', 'FRI', 'SUN']
                    .map(
                      (d) => Text(
                        d,
                        style: TextStyle(fontSize: 10, color: AppColors.textColorSecondary),
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

  Widget _legendDot(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 10, color: AppColors.textColorSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _rangePill(int index, String label) {
    return Obx(() {
      final selected = controller.selectedRange.value == index;
      return GestureDetector(
        onTap: () => controller.setRange(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.colorWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.designInputBorder : Colors.transparent),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.textColorPrimary : AppColors.textColorSecondary,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRecommendations() {
    return Column(
      children: controller.recommendations.map((item) {
        final (badge, badgeColor) = switch (item.impact) {
          RecommendationImpact.highImpact => ('HIGH IMPACT', const Color(0xFFF3D89F)),
          RecommendationImpact.observation => ('OBSERVATION', const Color(0xFFE1E7F8)),
          RecommendationImpact.newItem => ('NEW', const Color(0xFFD9F4EA)),
        };
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(color: AppColors.designInputBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 18))),
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
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textColorPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColorSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: item.impact == RecommendationImpact.highImpact ? () => Get.toNamed(Routes.PRICE_ANALYSIS) : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item.impact == RecommendationImpact.observation
                              ? Colors.white
                              : AppColors.colorPrimary,
                          foregroundColor: item.impact == RecommendationImpact.observation
                              ? AppColors.textColorPrimary
                              : Colors.white,
                          elevation: 0,
                          side: BorderSide(
                            color: item.impact == RecommendationImpact.observation
                                ? AppColors.designInputBorder
                                : Colors.transparent,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(item.cta, style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
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

  Widget _circleIcon(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: AppColors.colorWhite,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: AppColors.textColorPrimary),
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
        colors: [AppColors.colorPrimary.withOpacity(0.20), AppColors.colorPrimary.withOpacity(0.02)],
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
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) => oldDelegate.values != values;
}

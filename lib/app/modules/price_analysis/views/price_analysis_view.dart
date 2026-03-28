import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../routes/app_pages.dart';
import '../controllers/price_analysis_controller.dart';

class PriceAnalysisView extends BaseView<PriceAnalysisController> {
  PriceAnalysisView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  const SizedBox(height: 14),
                  Text(
                    'Saturday, Oct 14',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textColorPrimary),
                  ),
                  Text(
                    'Market insights for this weekend',
                    style: TextStyle(fontSize: 14, color: AppColors.textColorSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('↗ High Demand in Masaki', isPrimary: true),
                      _chip('📅 Weekend Rate'),
                      _chip('👥 70% Occupancy'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _recommendationCard(),
                  const SizedBox(height: 14),
                  Text(
                    'Market Comparison',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textColorPrimary),
                  ),
                  const SizedBox(height: 10),
                  _comparisonCard(),
                  const SizedBox(height: 14),
                  Text(
                    'Location Context',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textColorPrimary),
                  ),
                  const SizedBox(height: 10),
                  _mapCard(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.applyToCalendar();
                  Get.toNamed(Routes.AI_PRICING_OPTIMIZER);
                },
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Apply to Calendar', style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.50,
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _roundIcon(Icons.arrow_back_ios_new_rounded, onTap: Get.back),
        const Spacer(),
        Text(
          'Price Analysis',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.colorPrimary, fontFamily: 'Times New Roman'),
        ),
        const Spacer(),
        _roundIcon(Icons.info_outline, onTap: () {}),
      ],
    );
  }

  Widget _roundIcon(IconData icon, {required VoidCallback onTap}) {
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

  Widget _chip(String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? Color(0x0D6D6D1A) : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isPrimary ? AppColors.colorPrimary : AppColors.textColorPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _recommendationCard() {
    return Obx(
      () => Container(
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
                Text(
                  'AI RECOMMENDATION',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textColorSecondary, letterSpacing: 0.6),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+11% Peak',
                    style: TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: TextStyle(color: AppColors.textColorPrimary),
                children: [
                  TextSpan(text: '\$${controller.suggestedPrice.value}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' / night', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _bullet('Your Superhost status and recent 5-star reviews justify a premium over the neighborhood average.'),
            const SizedBox(height: 8),
            _bullet('Local events in Masaki are driving a 15% increase in searches for this date.'),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, color: AppColors.colorPrimary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w400, color: AppColors.textColorPrimary)),
        ),
      ],
    );
  }

  Widget _comparisonCard() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.colorWhite,
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          border: Border.all(color: AppColors.designInputBorder),
        ),
        child: Column(
          children: [
            _barRow('Your Suggested Price', controller.suggestedPrice.value, 0.86, AppColors.colorPrimary),
            const SizedBox(height: 14),
            _barRow('Competitor Average', controller.competitorAverage.value, 0.63, const Color(0xFFC5CEDB)),
            const SizedBox(height: 10),
            Text(
              'Based on 42 similar listings within 2 miles',
              style: TextStyle(fontSize: 12, color: AppColors.textColorSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barRow(String label, int value, double pct, Color fill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textColorPrimary)),
            const Spacer(),
            Text('\$$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.colorPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          decoration: BoxDecoration(color: AppColors.pageBackground, borderRadius: BorderRadius.circular(12)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 180,
            child: Image.asset('images/home_img_2.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.cyan.withOpacity(0.35)),
          ),
          Positioned(
            top: 10,
            left: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.colorWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '\$240',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.colorPrimary),
              ),
            ),
          ),
          Positioned(
            left: 150,
            top: 78,
            child: Icon(Icons.location_on, color: AppColors.colorPrimary, size: 28),
          ),
        ],
      ),
    );
  }
}

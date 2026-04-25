import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../routes/app_pages.dart';
import '../controllers/price_analysis_controller.dart';

class PriceAnalysisView extends BaseView<PriceAnalysisController> {
  PriceAnalysisView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

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
                  _topBar(context),
                  const SizedBox(height: 14),
                  Text(
                    _t(context, en: 'Saturday, Oct 14', sw: 'Jumamosi, Okt 14'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _t(
                      context,
                      en: 'Market insights for this weekend',
                      sw: 'Uchambuzi wa soko kwa wikendi hii',
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: _isDark(context)
                          ? Colors.white70
                          : AppColors.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        context,
                        _t(
                          context,
                          en: '↗ High Demand in Masaki',
                          sw: '↗ Mahitaji makubwa Masaki',
                        ),
                        isPrimary: true,
                      ),
                      _chip(
                        context,
                        _t(context, en: 'Weekend Rate', sw: 'Bei ya wikendi'),
                      ),
                      _chip(
                        context,
                        _t(context, en: '70% Occupancy', sw: 'Ukodishaji 70%'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _recommendationCard(context),
                  const SizedBox(height: 14),
                  Text(
                    _t(
                      context,
                      en: 'Market Comparison',
                      sw: 'Ulinganisho wa Soko',
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _comparisonCard(context),
                  const SizedBox(height: 14),
                  Text(
                    _t(context, en: 'Location Context', sw: 'Muktadha wa Eneo'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _mapCard(context),
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
                label: Text(
                  _t(
                    context,
                    en: 'Apply to Calendar',
                    sw: 'Tumia Kwenye Kalenda',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        _roundIcon(context, Icons.arrow_back_ios_new_rounded, onTap: Get.back),
        const Spacer(),
        Text(
          _t(context, en: 'Price Analysis', sw: 'Uchambuzi wa Bei'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.colorPrimary,
            fontFamily: 'Times New Roman',
          ),
        ),
        const Spacer(),
        _roundIcon(context, Icons.info_outline, onTap: () {}),
      ],
    );
  }

  Widget _roundIcon(
    BuildContext context,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: _isDark(context) ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary
            ? const Color(0x0D6D6D1A)
            : (_isDark(context)
                  ? const Color(0xFF1F1F1F)
                  : AppColors.colorWhite),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark(context)
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.designInputBorder,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isPrimary
              ? AppColors.colorPrimary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _recommendationCard(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isDark(context)
              ? const Color(0xFF1F1F1F)
              : AppColors.colorWhite,
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          border: Border.all(
            color: _isDark(context)
                ? Colors.white.withValues(alpha: 0.18)
                : AppColors.designInputBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _t(context, en: 'AI RECOMMENDATION', sw: 'PENDEKEZO LA AI'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isDark(context)
                        ? Colors.white70
                        : AppColors.textColorSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _t(context, en: '+11% Peak', sw: '+11% Kilele'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '\$${controller.suggestedPrice.value}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: _t(context, en: ' / night', sw: ' / usiku'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _bullet(
              context,
              _t(
                context,
                en: 'Your Superhost status and recent 5-star reviews justify a premium over the neighborhood average.',
                sw: 'Hadhi yako ya Superhost na tathmini za nyota 5 za hivi karibuni zinahalalisha bei ya juu kuliko wastani wa jirani.',
              ),
            ),
            const SizedBox(height: 8),
            _bullet(
              context,
              _t(
                context,
                en: 'Local events in Masaki are driving a 15% increase in searches for this date.',
                sw: 'Matukio ya eneo la Masaki yanasababisha ongezeko la 15% la utafutaji kwa tarehe hii.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: AppColors.colorPrimary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _comparisonCard(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isDark(context)
              ? const Color(0xFF1F1F1F)
              : AppColors.colorWhite,
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          border: Border.all(
            color: _isDark(context)
                ? Colors.white.withValues(alpha: 0.18)
                : AppColors.designInputBorder,
          ),
        ),
        child: Column(
          children: [
            _barRow(
              context,
              _t(
                context,
                en: 'Your Suggested Price',
                sw: 'Bei Uliyopendekezwa',
              ),
              controller.suggestedPrice.value,
              0.86,
              AppColors.colorPrimary,
            ),
            const SizedBox(height: 14),
            _barRow(
              context,
              _t(
                context,
                en: 'Competitor Average',
                sw: 'Wastani wa Washindani',
              ),
              controller.competitorAverage.value,
              0.63,
              const Color(0xFFC5CEDB),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                context,
                en: 'Based on 42 similar listings within 2 miles',
                sw: 'Kulingana na matangazo 42 yanayofanana ndani ya maili 2',
              ),
              style: TextStyle(
                fontSize: 12,
                color: _isDark(context)
                    ? Colors.white70
                    : AppColors.textColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barRow(
    BuildContext context,
    String label,
    int value,
    double pct,
    Color fill,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '\$$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.colorPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: _isDark(context)
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.pageBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapCard(BuildContext context) {
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
            child: Container(color: Colors.cyan.withValues(alpha: 0.35)),
          ),
          Positioned(
            top: 10,
            left: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _isDark(context)
                    ? const Color(0xFF1F1F1F)
                    : AppColors.colorWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '\$240',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            left: 150,
            top: 78,
            child: Icon(
              Icons.location_on,
              color: AppColors.colorPrimary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

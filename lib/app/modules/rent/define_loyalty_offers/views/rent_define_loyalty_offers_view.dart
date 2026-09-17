import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/form_surface_colors.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_define_loyalty_offers_controller.dart';

/// Loyalty offer form — uses app [FormSurfaceColors] / [AppColors] (Home shell).
class RentDefineLoyaltyOffersView
    extends RentBaseView<RentDefineLoyaltyOffersController> {
  RentDefineLoyaltyOffersView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  Color _accent(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return c.isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.colorPrimary;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Ongeza ofa' : 'Add Offer');

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final accent = _accent(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              _isSw
                  ? 'Bainisha wakati wa tuzo. Tengeneza vichocheo vya kiotomatiki vinavyowalipa wakazi wa muda mrefu.'
                  : 'Define the moments of excellence. Create automated triggers that reward your long-term residents '
                      'based on their commitment and investment in the community.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: c.secondary,
              ),
            ),
            const SizedBox(height: 20),
            _curationLogicCard(context, c, accent),
            const SizedBox(height: 16),
            Obx(() {
              if (!controller.hasActivePrograms.value) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: controller.openActiveLoyaltyPrograms,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.stars_rounded, color: accent, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isSw
                                  ? 'Tazama programu hai za uaminifu'
                                  : 'View active loyalty programs',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: accent,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: accent),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            _offerThresholdsCard(context, c, accent),
            const SizedBox(height: 16),
            _offerTypeCard(context, c, accent),
            const SizedBox(height: 16),
            _termsCard(context, c, accent),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.onDeploy,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSw
                      ? 'Tekeleza Programu ya Uaminifu'
                      : 'Deploy Loyalty Program',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _curationLogicCard(
    BuildContext context,
    FormSurfaceColors c,
    Color accent,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withValues(alpha: c.isDark ? 0.65 : 1)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: c.hint),
                const SizedBox(width: 4),
                Icon(Icons.star_outline, size: 16, color: c.hint),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSw ? 'Mantiki ya Uchambuzi' : 'Curation Logic',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.headline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSw
                    ? 'Tuzo za kiotomatiki hupunguza kuondoka kwa wapangaji kwa wastani wa 24% kwenye mali za hadhi.'
                    : 'Automated rewards reduce churn by 24% on average across premium properties.',
                style: TextStyle(fontSize: 13, height: 1.4, color: c.secondary),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: controller.onViewStrategyGuide,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSw
                          ? 'Tazama Mwongozo wa Mkakati'
                          : 'View Strategy Guide',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.north_east, size: 14, color: accent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _offerThresholdsCard(
    BuildContext context,
    FormSurfaceColors c,
    Color accent,
  ) {
    return _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: accent, size: 26),
              const SizedBox(width: 8),
              Text(
                _isSw ? 'Vizingiti vya Ofa' : 'Offer Thresholds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.headline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel(
            c,
            _isSw
                ? 'MUDA WA CHINI WA UKAAJI (MIEZI)'
                : 'MINIMUM STAY DURATION (MONTHS)',
          ),
          const SizedBox(height: 6),
          _suffixField(
            c,
            accent,
            controller: controller.minStayController,
            hint: '12',
            suffix: _isSw ? 'Miezi' : 'Months',
            validator: controller.validateMinStay,
          ),
          const SizedBox(height: 14),
          _fieldLabel(
            c,
            _isSw
                ? 'KIZINGITI CHA JUMLA YA MAPATO'
                : 'TOTAL REVENUE THRESHOLD',
          ),
          const SizedBox(height: 6),
          _suffixField(
            c,
            accent,
            controller: controller.revenueController,
            hint: '5,000,000',
            suffix: Get.find<CurrencyService>().inputSuffix,
            validator: controller.validateRevenue,
          ),
        ],
      ),
    );
  }

  Widget _offerTypeCard(
    BuildContext context,
    FormSurfaceColors c,
    Color accent,
  ) {
    return _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: accent, size: 24),
              const SizedBox(width: 8),
              Text(
                _isSw ? 'Aina ya Ofa' : 'Offer Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.headline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Column(
              children: List.generate(
                RentDefineLoyaltyOffersController.offerTypeLabels.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _offerTypeRow(
                    c,
                    accent,
                    label: RentDefineLoyaltyOffersController.offerTypeLabels[i],
                    selected: controller.selectedOfferType.value == i,
                    onTap: () => controller.selectedOfferType.value = i,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsCard(
    BuildContext context,
    FormSurfaceColors c,
    Color accent,
  ) {
    return _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: accent, size: 24),
              const SizedBox(width: 8),
              Text(
                _isSw ? 'Masharti na Maelezo' : 'Terms & Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.headline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _fieldLabel(c, 'DESCRIPTION OF THE OFFER TERMS'),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.termsController,
            maxLines: 5,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: controller.validateTerms,
            style: TextStyle(fontSize: 14, height: 1.4, color: c.headline),
            cursorColor: accent,
            decoration: InputDecoration(
              hintText:
                  'Ex: Resident receives a 10% reduction on the 13th month\'s rent upon successful completion of a 12-month lease cycle without arrears.',
              hintStyle: TextStyle(
                color: c.hint.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
              filled: true,
              fillColor: c.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: c.border.withValues(alpha: c.isDark ? 0.5 : 1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(FormSurfaceColors c, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: c.secondary,
      ),
    );
  }

  Widget _suffixField(
    FormSurfaceColors c,
    Color accent, {
    required TextEditingController controller,
    required String hint,
    required String suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.headline,
      ),
      cursorColor: accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.hint.withValues(alpha: 0.85)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        isDense: false,
        filled: true,
        fillColor: c.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        suffix: Text(
          suffix,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.secondary,
          ),
        ),
      ),
    );
  }

  Widget _offerTypeRow(
    FormSurfaceColors c,
    Color accent, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: c.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.65)
                  : c.border.withValues(alpha: c.isDark ? 0.4 : 1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? accent
                        : c.hint.withValues(alpha: 0.55),
                    width: 2,
                  ),
                  color: selected
                      ? accent.withValues(alpha: c.isDark ? 0.25 : 0.15)
                      : Colors.transparent,
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.headline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(FormSurfaceColors c, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.border.withValues(alpha: c.isDark ? 0.55 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.28 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

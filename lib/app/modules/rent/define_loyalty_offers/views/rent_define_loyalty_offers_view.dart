import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_define_loyalty_offers_controller.dart';

/// Semantic colors — light cream/teal editorial; dark surfaces from [ThemeData].
class _LoyaltyUi {
  _LoyaltyUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);

  bool get dark => _t.brightness == Brightness.dark;

  static const Color teal = Color(0xFF005B5C);

  /// Teal reads better on dark scaffold / cards.
  Color get brandTeal => dark ? const Color(0xFF4DB6AC) : teal;

  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF1A1A1A);

  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);

  Color get card => _t.cardColor;

  Color get curationCard => dark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEDE8);

  Color get inputFill => dark ? const Color(0xFF3A3A3C) : const Color(0xFFF0EFEB);

  Color get border => dark ? const Color(0xFF48484A) : const Color(0xFFE0DFD9);

  Color get decorativeMuted => dark ? const Color(0xFF636366) : const Color(0xFFBDBDBD);

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Loyalty Thresholds — cream / teal editorial; dark theme aware.
class RentDefineLoyaltyOffersView extends RentBaseView<RentDefineLoyaltyOffersController> {
  RentDefineLoyaltyOffersView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Vizingiti' : 'Thresholds');

  @override
  Widget body(BuildContext context) {
    final u = _LoyaltyUi(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSw ? 'UHIFADHI WA WAKAZI' : 'RESIDENT THRESHOLDS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSw ? 'Vizingiti vya Uaminifu' : 'Loyalty Thresholds',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.normal,
                height: 1.15,
                color: u.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Define the moments of excellence. Create automated triggers that reward your long-term residents '
              'based on their commitment and investment in the community.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: u.muted,
              ),
            ),
            const SizedBox(height: 20),
            _curationLogicCard(u),
            const SizedBox(height: 16),
            Obx(() {
              if (!controller.hasActivePrograms.value) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: u.card,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: controller.openActiveLoyaltyPrograms,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.stars_rounded, color: u.brandTeal, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isSw ? 'Tazama programu hai za uaminifu' : 'View active loyalty programs',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: u.brandTeal,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: u.brandTeal),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            _offerThresholdsCard(u),
            const SizedBox(height: 16),
            _offerTypeCard(u),
            const SizedBox(height: 16),
            _termsCard(u),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.onDeploy,
                style: FilledButton.styleFrom(
                  backgroundColor: _LoyaltyUi.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isSw ? 'Tekeleza Programu ya Uaminifu' : 'Deploy Loyalty Program',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _curationLogicCard(_LoyaltyUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.curationCard,
        borderRadius: BorderRadius.circular(16),
        border: u.dark ? Border.all(color: u.border.withValues(alpha: 0.65)) : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: u.decorativeMuted),
                const SizedBox(width: 4),
                Icon(Icons.star_outline, size: 16, color: u.decorativeMuted),
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
                  color: u.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSw
                    ? 'Tuzo za kiotomatiki hupunguza kuondoka kwa wapangaji kwa wastani wa 24% kwenye mali za hadhi.'
                    : 'Automated rewards reduce churn by 24% on average across premium properties.',
                style: TextStyle(fontSize: 13, height: 1.4, color: u.muted),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: controller.onViewStrategyGuide,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSw ? 'Tazama Mwongozo wa Mkakati' : 'View Strategy Guide',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: u.brandTeal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.north_east, size: 14, color: u.brandTeal),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _offerThresholdsCard(_LoyaltyUi u) {
    return _card(
      u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: u.brandTeal, size: 26),
              const SizedBox(width: 8),
              Text(
                _isSw ? 'Vizingiti vya Ofa' : 'Offer Thresholds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: u.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel(u, _isSw ? 'MUDA WA CHINI WA UKAAJI (MIEZI)' : 'MINIMUM STAY DURATION (MONTHS)'),
          const SizedBox(height: 6),
          _suffixField(
            u,
            controller: controller.minStayController,
            hint: '12',
            suffix: _isSw ? 'Miezi' : 'Months',
            validator: controller.validateMinStay,
          ),
          const SizedBox(height: 14),
          _fieldLabel(u, _isSw ? 'KIZINGITI CHA JUMLA YA MAPATO (TSH)' : 'TOTAL REVENUE THRESHOLD (TSH)'),
          const SizedBox(height: 6),
          _suffixField(
            u,
            controller: controller.revenueController,
            hint: '5,000,000',
            suffix: _isSw ? 'Tsh' : 'Tsh',
            validator: controller.validateRevenue,
          ),
        ],
      ),
    );
  }

  Widget _offerTypeCard(_LoyaltyUi u) {
    return _card(
      u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: u.brandTeal, size: 24),
              const SizedBox(width: 8),
              Text(
                _isSw ? 'Aina ya Ofa' : 'Offer Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: u.onSurface,
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
                    u,
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

  Widget _termsCard(_LoyaltyUi u) {
    return _card(
      u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: u.brandTeal, size: 24),
              const SizedBox(width: 8),
              Text(
                _isSw ? 'Masharti na Maelezo' : 'Terms & Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: u.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _fieldLabel(u, 'DESCRIPTION OF THE OFFER TERMS'),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.termsController,
            maxLines: 5,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: controller.validateTerms,
            style: TextStyle(fontSize: 14, height: 1.4, color: u.onSurface),
            cursorColor: u.brandTeal,
            decoration: InputDecoration(
              hintText:
                  'Ex: Resident receives a 10% reduction on the 13th month\'s rent upon successful completion of a 12-month lease cycle without arrears.',
              hintStyle: TextStyle(color: u.muted.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
              filled: true,
              fillColor: u.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: u.border.withValues(alpha: u.dark ? 0.5 : 0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: u.brandTeal, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(_LoyaltyUi u, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: u.muted,
      ),
    );
  }

  Widget _suffixField(
    _LoyaltyUi u, {
    required TextEditingController controller,
    required String hint,
    required String suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: u.onSurface),
      cursorColor: u.brandTeal,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: u.muted.withValues(alpha: 0.85)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: u.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: u.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: u.brandTeal, width: 1.5),
        ),
        isDense: false,
        filled: true,
        fillColor: u.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        suffix: Text(
          suffix,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: u.muted,
          ),
        ),
      ),
    );
  }

  Widget _offerTypeRow(
    _LoyaltyUi u, {
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
            color: u.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? u.brandTeal.withValues(alpha: 0.65) : u.border.withValues(alpha: u.dark ? 0.4 : 0),
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
                    color: selected ? u.brandTeal : u.muted.withValues(alpha: 0.55),
                    width: 2,
                  ),
                  color: selected ? u.brandTeal.withValues(alpha: u.dark ? 0.25 : 0.15) : Colors.transparent,
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: u.brandTeal,
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
                    color: u.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(_LoyaltyUi u, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.cardShadow,
        border: u.dark ? Border.all(color: u.border.withValues(alpha: 0.55)) : null,
      ),
      child: child,
    );
  }
}

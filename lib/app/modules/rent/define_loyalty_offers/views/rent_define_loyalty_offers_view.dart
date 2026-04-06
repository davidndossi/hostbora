import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_define_loyalty_offers_controller.dart';

/// Loyalty Thresholds — cream `#F8F7F2`, teal `#005B5C`, editorial typography.
abstract class _LoyaltyPalette {
  static const Color teal = Color(0xFF005B5C);
  static const Color navy = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B7280);
  static const Color inputFill = Color(0xFFF0EFEB);
  static const Color curationCard = Color(0xFFEEEDE8);
}

class RentDefineLoyaltyOffersView extends BaseView<RentDefineLoyaltyOffersController> {
  RentDefineLoyaltyOffersView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Resident Retention');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 24, height: 1.15),
              children: const [
                TextSpan(
                  text: 'Loyalty ',
                  style: TextStyle(fontWeight: FontWeight.w700, fontStyle: FontStyle.normal),
                ),
                TextSpan(
                  text: 'Thresholds',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _LoyaltyPalette.teal,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Define the moments of excellence. Create automated triggers that reward your long-term residents '
            'based on their commitment and investment in the community.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: _LoyaltyPalette.muted,
            ),
          ),
          const SizedBox(height: 20),
          _curationLogicCard(),
          const SizedBox(height: 16),
          Obx(() {
            if (!controller.hasActivePrograms.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: controller.openActiveLoyaltyPrograms,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded, color: _LoyaltyPalette.teal, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'View active loyalty programs',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _LoyaltyPalette.teal,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: _LoyaltyPalette.teal),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          _offerThresholdsCard(),
          const SizedBox(height: 16),
          _offerTypeCard(),
          const SizedBox(height: 16),
          _termsCard(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.onDeploy,
              style: FilledButton.styleFrom(
                backgroundColor: _LoyaltyPalette.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Deploy Loyalty Program',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _curationLogicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LoyaltyPalette.curationCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Icon(Icons.star_outline, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Curation Logic',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _LoyaltyPalette.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Automated rewards reduce churn by 24% on average across premium properties.',
                style: TextStyle(fontSize: 13, height: 1.4, color: _LoyaltyPalette.muted),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: controller.onViewStrategyGuide,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Strategy Guide',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _LoyaltyPalette.teal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.north_east, size: 14, color: _LoyaltyPalette.teal),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _offerThresholdsCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: _LoyaltyPalette.teal, size: 26),
              const SizedBox(width: 8),
              Text(
                'Offer Thresholds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _LoyaltyPalette.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('MINIMUM STAY DURATION (MONTHS)'),
          const SizedBox(height: 6),
          _suffixField(
            controller: controller.minStayController,
            hint: '12',
            suffix: 'Months',
            validator: controller.validateMinStay,
          ),
          const SizedBox(height: 14),
          _fieldLabel('TOTAL REVENUE THRESHOLD (TSH)'),
          const SizedBox(height: 6),
          _suffixField(
            controller: controller.revenueController,
            hint: '5,000,000',
            suffix: 'Tsh',
            validator: controller.validateRevenue,
          ),
        ],
      ),
    );
  }

  Widget _offerTypeCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: _LoyaltyPalette.teal, size: 24),
              const SizedBox(width: 8),
              Text(
                'Offer Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _LoyaltyPalette.navy,
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

  Widget _termsCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: _LoyaltyPalette.teal, size: 24),
              const SizedBox(width: 8),
              Text(
                'Terms & Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _LoyaltyPalette.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _fieldLabel('DESCRIPTION OF THE OFFER TERMS'),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.termsController,
            maxLines: 5,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: controller.validateTerms,
            style: const TextStyle(fontSize: 14, height: 1.4, color: _LoyaltyPalette.navy),
            decoration: InputDecoration(
              hintText:
                  'Ex: Resident receives a 10% reduction on the 13th month\'s rent upon successful completion of a 12-month lease cycle without arrears.',
              hintStyle: TextStyle(color: _LoyaltyPalette.muted.withValues(alpha: 0.85), fontSize: 13, height: 1.4),
              filled: true,
              fillColor: _LoyaltyPalette.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: _LoyaltyPalette.muted,
      ),
    );
  }

  static Widget _suffixField({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _LoyaltyPalette.navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _LoyaltyPalette.muted.withValues(alpha: 0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        isDense: false,
        filled: true,
        fillColor: _LoyaltyPalette.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        suffix: Text(
          suffix,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _LoyaltyPalette.muted,
          ),
        ),
      ),
    );
  }

  static Widget _offerTypeRow({
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
            color: _LoyaltyPalette.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _LoyaltyPalette.teal.withValues(alpha: 0.5) : Colors.transparent,
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
                    color: selected ? _LoyaltyPalette.teal : _LoyaltyPalette.muted.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  color: selected ? _LoyaltyPalette.teal.withValues(alpha: 0.15) : Colors.transparent,
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _LoyaltyPalette.teal,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _LoyaltyPalette.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:paa_yangu/app/modules/rent/widgets/rent_ui.dart';

import '../../../../core/base/base_view.dart';
import '../controllers/rent_active_loyalty_programs_controller.dart';

abstract class _LoyaltyDash {
  static const Color teal = Color(0xFF005B5C);
  static const Color navy = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE8E6E1);
  static const Color creamCard = Color(0xFFF5F3EF);
}

class RentActiveLoyaltyProgramsView extends BaseView<RentActiveLoyaltyProgramsController> {
  RentActiveLoyaltyProgramsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar('Loyalty & Resident Programs');

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Programs below are loaded from your real loyalty offers data.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: _LoyaltyDash.muted,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.onCreateNewOffer,
                style: FilledButton.styleFrom(
                  backgroundColor: _LoyaltyDash.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 22),
                label: const Text(
                  'CREATE NEW OFFER',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (controller.offers.isEmpty)
              _emptyStateCard()
            else
              ...controller.offers.map((offer) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _offerCard(offer),
                  )),
            const SizedBox(height: 16),
            Text(
              'Performance Insights',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _LoyaltyDash.navy,
              ),
            ),
            const SizedBox(height: 12),
            _insightCard(
              value: controller.retentionRateLabel,
              label: 'RETENTION RATE',
              subtext: '${controller.activeProgramsCount} active program(s)',
            ),
            const SizedBox(height: 10),
            _insightCard(
              value: '${controller.activeClaimsCount}',
              label: 'ACTIVE CLAIMS',
              subtext: 'Derived from active offers',
            ),
            const SizedBox(height: 10),
            _insightCard(
              value: controller.valueDistributedLabel,
              label: 'VALUE DISTRIBUTED',
              subtext: 'From current offer thresholds',
            ),
          ],
        ),
      );
    });
  }

  Widget _offerCard(ActiveLoyaltyProgramItem offer) {
    final created = DateFormat('MMM d, yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(offer.createdAtMs));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LoyaltyDash.border),
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
          Text(
            offer.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _LoyaltyDash.navy,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => controller.openEditOfferDialog(offer),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => controller.deleteOffer(offer.id),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'THRESHOLD: ${offer.thresholdLabel}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LoyaltyDash.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'REWARD VALUE: ${offer.rewardLabel}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _LoyaltyDash.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            offer.terms,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: _LoyaltyDash.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Created: $created',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _LoyaltyDash.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _LoyaltyDash.creamCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LoyaltyDash.border),
      ),
      child: const Text(
        'No active loyalty offers found. Create a new offer to start tracking real program data.',
        style: TextStyle(fontSize: 13, height: 1.4, color: _LoyaltyDash.muted),
      ),
    );
  }

  Widget _insightCard({
    required String value,
    required String label,
    required String subtext,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LoyaltyDash.creamCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LoyaltyDash.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _LoyaltyDash.teal,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: _LoyaltyDash.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LoyaltyDash.muted,
            ),
          ),
        ],
      ),
    );
  }
}

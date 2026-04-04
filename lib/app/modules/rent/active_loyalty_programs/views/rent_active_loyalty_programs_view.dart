import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/modules/rent/widgets/rent_ui.dart';

import '../../../../core/base/base_view.dart';
import '../controllers/rent_active_loyalty_programs_controller.dart';

/// Loyalty & Resident Programs — cream `#F8F7F2`, teal `#005B5C`, editorial serif.
abstract class _LoyaltyDash {
  static const Color teal = Color(0xFF005B5C);
  static const Color navy = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE8E6E1);
  static const Color creamCard = Color(0xFFF5F3EF);
  static const Color brick = Color(0xFF7C4A3A);
  static const Color activePillBg = Color(0xFFE3F2FD);
  static const Color activePillFg = Color(0xFF1565C0);
}

class RentActiveLoyaltyProgramsView extends BaseView<RentActiveLoyaltyProgramsController> {
  RentActiveLoyaltyProgramsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Loyalty & Resident Programs');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage rewards, monitor engagement, and tune thresholds so long-term residents feel recognized.',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 22),
              label: const Text(
                'CREATE NEW OFFER',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _platinumCard(),
          const SizedBox(height: 12),
          _referralCard(),
          const SizedBox(height: 12),
          _draftCard(),
          const SizedBox(height: 16),
          _featuredHolidayCard(),
          const SizedBox(height: 24),
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
            value: '98%',
            valueColor: _LoyaltyDash.teal,
            label: 'RETENTION RATE',
            subtext: '↗ +2.4% versus last quarter',
            subColor: _LoyaltyDash.muted,
          ),
          const SizedBox(height: 10),
          _insightCard(
            value: '124',
            valueColor: _LoyaltyDash.brick,
            label: 'ACTIVE CLAIMS',
            subtext: '• 12 pending approval',
            subColor: _LoyaltyDash.muted,
          ),
          const SizedBox(height: 10),
          _insightCard(
            value: '\$14k',
            valueColor: _LoyaltyDash.navy,
            label: 'VALUE DISTRIBUTED',
            subtext: '⚠ Optimization opportunity',
            subColor: _LoyaltyDash.brick,
          ),
        ],
      ),
    );
  }

  Widget _platinumCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _LoyaltyDash.activePillBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE CAMPAIGN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: _LoyaltyDash.activePillFg,
                  ),
                ),
              ),
              const Spacer(),
              Obx(
                () => Switch.adaptive(
                  value: controller.platinumEnabled.value,
                  onChanged: (v) => controller.platinumEnabled.value = v,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _LoyaltyDash.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Platinum Resident Perk',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _LoyaltyDash.navy,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _statBlock(
                  label: 'RETENTION THRESHOLD',
                  value: '> 12 months stay',
                  valueSerif: true,
                ),
              ),
              Expanded(
                child: _statBlock(
                  label: 'PROGRAM REWARD',
                  value: '10% Rent Reduction',
                  valueColor: _LoyaltyDash.brick,
                  valueSerif: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _avatarStack(),
              const SizedBox(width: 8),
              Text(
                '+4',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _LoyaltyDash.muted,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.onViewAnalytics,
                style: TextButton.styleFrom(
                  foregroundColor: _LoyaltyDash.teal,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VIEW ANALYTICS',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referralCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LoyaltyDash.creamCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LoyaltyDash.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.campaign_outlined, color: Colors.red.shade700, size: 22),
              ),
              const Spacer(),
              Obx(
                () => Switch.adaptive(
                  value: controller.referralEnabled.value,
                  onChanged: (v) => controller.referralEnabled.value = v,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _LoyaltyDash.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Referral Advocate',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _LoyaltyDash.navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'THRESHOLD: 1 Signed Referral',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LoyaltyDash.muted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'REWARD: \$500 Amazon Credit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _LoyaltyDash.navy,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.onEditReferralProgram,
              style: OutlinedButton.styleFrom(
                foregroundColor: _LoyaltyDash.teal,
                side: BorderSide(color: _LoyaltyDash.teal.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'EDIT PROGRAM',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _draftCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LoyaltyDash.creamCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LoyaltyDash.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: _LoyaltyDash.muted, size: 26),
              const Spacer(),
              Obx(
                () => Switch.adaptive(
                  value: controller.earlyRenewalEnabled.value,
                  onChanged: (v) => controller.earlyRenewalEnabled.value = v,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _LoyaltyDash.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Early Renewal',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _LoyaltyDash.navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'THRESHOLD: 90 Days Pre-Expiry',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _LoyaltyDash.muted),
          ),
          const SizedBox(height: 4),
          const Text(
            'REWARD: Free Tech Upgrade',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _LoyaltyDash.navy),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'DRAFT STATE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: _LoyaltyDash.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredHolidayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LoyaltyDash.teal,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _LoyaltyDash.teal.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PLANNED REWARD',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Holiday Hamper Selection',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.98),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seasonal hamper for residents who reach the long-stay milestone—curated locally.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'THRESHOLD: 24+ Month Stay',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'REWARD: Premium Hamper',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: Image.asset(
                'images/luxury_room_view.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: Icon(Icons.card_giftcard, size: 48, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statBlock({
    required String label,
    required String value,
    Color? valueColor,
    bool valueSerif = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: _LoyaltyDash.muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? _LoyaltyDash.navy,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  static Widget _avatarStack() {
    const size = 28.0;
    return SizedBox(
      width: size * 2.2,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: _LoyaltyDash.border,
                ),
                child: CircleAvatar(
                  radius: size / 2 - 1,
                  backgroundColor: _LoyaltyDash.border,
                  child: Icon(Icons.person, size: 14, color: _LoyaltyDash.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _insightCard({
    required String value,
    required Color valueColor,
    required String label,
    required String subtext,
    required Color subColor,
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
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: _LoyaltyDash.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
}

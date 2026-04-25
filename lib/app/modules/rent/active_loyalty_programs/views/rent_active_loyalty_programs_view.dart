import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_active_loyalty_programs_controller.dart';

class _ActiveLoyaltyUi {
  _ActiveLoyaltyUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);

  bool get dark => _t.brightness == Brightness.dark;

  static const Color teal = Color(0xFF005B5C);

  Color get brandTeal => dark ? const Color(0xFF4DB6AC) : teal;

  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF1A1A1A);

  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);

  Color get border => dark ? const Color(0xFF48484A) : const Color(0xFFE8E6E1);

  Color get tintedCard => dark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F3EF);

  Color get accentLabel => dark ? const Color(0xFFFFAB91) : const Color(0xFF7B311A);

  Color get card => _t.cardColor;

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class RentActiveLoyaltyProgramsView extends BaseView<RentActiveLoyaltyProgramsController> {
  RentActiveLoyaltyProgramsView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Zawadi' : 'Rewards');

  @override
  Widget body(BuildContext context) {
    final u = _ActiveLoyaltyUi(context);
    return Obx(() {
      if (controller.loading.value) {
        return Center(child: CircularProgressIndicator(color: u.brandTeal));
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSw ? 'RETENTION SUITE' : 'RETENTION SUITE',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: u.accentLabel,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSw ? 'Uaminifu na Programu za Wakazi' : 'Loyalty & Resident Programs',
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
              _isSw
                  ? 'Programu zilizo hapa chini zimepakuliwa kutoka data halisi ya ofa zako za uaminifu.'
                  : 'Programs below are loaded from your real loyalty offers data.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: u.muted,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.onCreateNewOffer,
                style: FilledButton.styleFrom(
                  backgroundColor: _ActiveLoyaltyUi.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 22),
                label: Text(
                  _isSw ? 'UNDA OFA MPYA' : 'CREATE NEW OFFER',
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
              _emptyStateCard(u)
            else
              ...controller.offers.map((offer) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _offerCard(u, offer),
                  )),
            const SizedBox(height: 16),
            Text(
              _isSw ? 'Maarifa ya Utendaji' : 'Performance Insights',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: u.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _insightCard(
              u,
              value: controller.retentionRateLabel,
              label: 'RETENTION RATE',
              subtext: '${controller.activeProgramsCount} active program(s)',
            ),
            const SizedBox(height: 10),
            _insightCard(
              u,
              value: '${controller.activeClaimsCount}',
              label: 'ACTIVE CLAIMS',
              subtext: _isSw ? 'Imechukuliwa kutoka ofa hai' : 'Derived from active offers',
            ),
            const SizedBox(height: 10),
            _insightCard(
              u,
              value: controller.valueDistributedLabel,
              label: 'VALUE DISTRIBUTED',
              subtext: _isSw ? 'Kutoka vizingiti vya ofa za sasa' : 'From current offer thresholds',
            ),
          ],
        ),
      );
    });
  }

  Widget _offerCard(_ActiveLoyaltyUi u, ActiveLoyaltyProgramItem offer) {
    final created = DateFormat('MMM d, yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(offer.createdAtMs));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: u.border.withValues(alpha: u.dark ? 0.85 : 1)),
        boxShadow: u.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => controller.openEditOfferDialog(offer),
                icon: Icon(Icons.edit_outlined, size: 16, color: u.brandTeal),
                label: Text(_isSw ? 'Hariri' : 'Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: u.brandTeal,
                  side: BorderSide(color: u.border),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => controller.deleteOffer(offer.id),
                icon: Icon(Icons.delete_outline, size: 16, color: u.brandTeal),
                label: Text(_isSw ? 'Futa' : 'Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: u.brandTeal,
                  side: BorderSide(color: u.border),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isSw ? 'KIZINGITI: ${offer.thresholdLabel}' : 'THRESHOLD: ${offer.thresholdLabel}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: u.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isSw ? 'THAMANI YA TUZO: ${offer.rewardLabel}' : 'REWARD VALUE: ${offer.rewardLabel}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            offer.terms,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: u.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isSw ? 'Imeundwa: $created' : 'Created: $created',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: u.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateCard(_ActiveLoyaltyUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.tintedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.border.withValues(alpha: 0.75)),
      ),
      child: Text(
        _isSw
            ? 'Hakuna ofa hai za uaminifu zilizopatikana. Unda ofa mpya kuanza kufuatilia data halisi ya programu.'
            : 'No active loyalty offers found. Create a new offer to start tracking real program data.',
        style: TextStyle(fontSize: 13, height: 1.4, color: u.muted),
      ),
    );
  }

  Widget _insightCard(
    _ActiveLoyaltyUi u, {
    required String value,
    required String label,
    required String subtext,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.tintedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: u.brandTeal,
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
              color: u.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: u.muted,
            ),
          ),
        ],
      ),
    );
  }
}

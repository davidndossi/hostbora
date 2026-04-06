import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_tenant_ledger_occupancy_controller.dart';

/// **Ledger overview** — tenancy, financial breakdown, payment timeline, CTA, residence card.
class RentTenantLedgerOccupancyView extends BaseView<RentTenantLedgerOccupancyController> {
  RentTenantLedgerOccupancyView({super.key});

  static const _teal = Color(0xFF0E6666);
  static const _tealMid = Color(0xFF4A9B9B);
  static const _pinkBar = Color(0xFFFCE1D9);
  static const _brownAlert = Color(0xFF5C4033);

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Tenant Ledger');

  @override
  Widget body(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Text(
              controller.displayTenantName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => _overviewParagraph()),
          const SizedBox(height: 16),
          _statusAlert(),
          const SizedBox(height: 20),
          Obx(() => _tenancyCard()),
          const SizedBox(height: 14),
          Obx(() => _financialBreakdownCard(currency)),
          const SizedBox(height: 22),
          _paymentTimelineSection(),
          const SizedBox(height: 22),
          _actionSection(),
          const SizedBox(height: 22),
          _residenceProfileCard(),
        ],
      ),
    );
  }

  Widget _overviewParagraph() {
    final bold = controller.propertyShortPhrase;
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14, height: 1.45, color: Colors.grey.shade800),
        children: [
          const TextSpan(text: 'Executive residency at '),
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const TextSpan(
            text: '. Currently entering the fifth month of professional tenancy.',
          ),
        ],
      ),
    );
  }

  Widget _statusAlert() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Status',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _pinkBar,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                color: _brownAlert,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'PARTIAL PAYMENT DETECTED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: _brownAlert,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tenancyCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.calendar_month_rounded, color: _teal.withValues(alpha: 0.9), size: 26),
              Text(
                'TENANCY',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current Stay',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.currentStayMonths} Months',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            controller.tenancyRangeLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Current Lease: ${controller.currentLeaseMonths} Months',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _financialBreakdownCard(NumberFormat currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINANCIAL LEDGER BREAKDOWN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Remaining Balance',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(controller.remainingBalanceTsh),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Due',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(controller.totalDueTsh),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Paid',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(controller.totalPaidTsh),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Timeline',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Detailed view of the billing cycle. Discrepancies noted in the current active month.',
          style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                Expanded(flex: 3, child: Container(color: _teal)),
                Expanded(flex: 3, child: Container(color: _teal)),
                Expanded(flex: 2, child: Container(color: _tealMid)),
                Expanded(flex: 2, child: Container(color: const Color(0xFFF5C4B8))),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _timelineLegend(),
      ],
    );
  }

  Widget _timelineLegend() {
    Widget cell(Color c, String label, {bool outline = false}) {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: outline ? Colors.white : c,
              border: outline ? Border.all(color: Colors.grey.shade500, width: 1.2) : null,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cell(_teal, 'FULLY PAID')),
            const SizedBox(width: 12),
            Expanded(child: cell(_tealMid, 'PARTIALLY PAID')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cell(const Color(0xFFF5C4B8), 'UNPAID')),
            const SizedBox(width: 12),
            Expanded(child: cell(Colors.white, 'UPCOMING', outline: true)),
          ],
        ),
      ],
    );
  }

  Widget _actionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Immediate Action Recommended',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Automate communication to resolve the pending balance for July and August.',
          style: TextStyle(fontSize: 14, height: 1.45, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.openPaymentReminder,
            icon: const Icon(Icons.campaign_outlined, size: 22),
            label: const Text(
              'SET PAYMENT REMINDER',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E5E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Signed Contract / Lease',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.contractFileName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: controller.pickAndUploadSignedContract,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload PDF/Word'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.openSignedContract,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.openEditLeaseTermsDialog,
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: const Text('Edit lease terms'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _residenceProfileCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Image.asset(
              'images/luxury_room_view.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade400,
                child: const Icon(Icons.apartment, size: 56, color: Colors.white),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESIDENCE PROFILE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Obx(
                  () => Text(
                    controller.displayPropertyFull,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(
                      RentTenantLedgerOccupancyController.residencyCity,
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.verified_user_outlined, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(
                      'Premium Tenant',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

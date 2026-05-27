import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_tenant_ledger_occupancy_controller.dart';

/// Semantic colors for ledger screen (light + dark).
class _LedgerUi {
  _LedgerUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);

  bool get dark => _t.brightness == Brightness.dark;

  static const Color teal = Color(0xFF0E6666);
  static const Color tealMid = Color(0xFF4A9B9B);

  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF1A1A1A);

  Color get onSurfaceSecondary => dark ? const Color(0xFFAEAEB2) : const Color(0xFF374151);

  Color get labelMuted => dark ? const Color(0xFF8E8E93) : const Color(0xFF757575);

  Color get card => _t.cardColor;

  Color get border => dark ? const Color(0xFF48484A) : const Color(0xFFE7E5E4);

  Color get alertBg => dark ? const Color(0xFF3D2A28) : const Color(0xFFFCE1D9);

  Color get alertAccent => dark ? const Color(0xFFFFAB91) : const Color(0xFF5C4033);

  Color get timelineUnpaid => dark ? const Color(0xFF8B4A3F) : const Color(0xFFF5C4B8);

  Color get timelineUpcomingFill => dark ? const Color(0xFF2C2C2E) : Colors.white;

  Color get timelineUpcomingBorder => dark ? const Color(0xFF636366) : Color(0xFFBDBDBD);

  Color get imagePlaceholder => dark ? const Color(0xFF3A3A3C) : Color(0xFFBDBDBD);

  Color get financialCardBg => teal;

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// **Ledger overview** — tenancy, financial breakdown, payment timeline, CTA, residence card.
class RentTenantLedgerOccupancyView extends RentBaseView<RentTenantLedgerOccupancyController> {
  RentTenantLedgerOccupancyView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  /// 1-based month of tenancy (e.g. after 4 full month boundaries → 5th month).
  static String _englishOrdinalMonth(int n) {
    final v = n.clamp(1, 999);
    if (v % 100 >= 11 && v % 100 <= 13) return '${v}th';
    switch (v % 10) {
      case 1:
        return '${v}st';
      case 2:
        return '${v}nd';
      case 3:
        return '${v}rd';
      default:
        return '${v}th';
    }
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(_isSw ? 'Daftari la Mpangaji' : 'Tenant Ledger');

  @override
  Widget body(BuildContext context) {
    final u = _LedgerUi(context);
    final currency = NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'MUHTASARI' : 'LEDGER OVERVIEW',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.displayTenantName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: u.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => _overviewParagraph(u)),
          const SizedBox(height: 16),
          Obx(() => _statusAlert(u)),
          const SizedBox(height: 20),
          Obx(() => _tenancyCard(u)),
          const SizedBox(height: 14),
          Obx(() => _financialBreakdownCard(u, currency)),
          const SizedBox(height: 22),
          _paymentTimelineSection(u),
          const SizedBox(height: 22),
          _actionSection(u),
          const SizedBox(height: 22),
          _residenceProfileCard(u),
        ],
      ),
    );
  }

  Widget _overviewParagraph(_LedgerUi u) {
    final bold = controller.propertyShortPhrase;
    final tenancyMonth = (controller.currentStayMonths + 1).clamp(1, 999);
    final tail = _isSw
        ? '. Kwa sasa anaingia mwezi wa $tenancyMonth wa upangaji.'
        : '. Currently entering the ${_englishOrdinalMonth(tenancyMonth)} month of tenancy.';
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14, height: 1.45, color: u.onSurfaceSecondary),
        children: [
          TextSpan(text: _isSw ? 'Mpangaji ' : 'Tenant at '),
          TextSpan(
            text: bold,
            style: TextStyle(fontWeight: FontWeight.w800, color: u.onSurface),
          ),
          TextSpan(text: tail),
        ],
      ),
    );
  }

  Color _paymentStatusAccent(_LedgerUi u, LedgerPaymentStatus s) {
    switch (s) {
      case LedgerPaymentStatus.fullyPaid:
        return u.dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      case LedgerPaymentStatus.notPaid:
        return u.dark ? const Color(0xFFFFAB91) : const Color(0xFFC62828);
      case LedgerPaymentStatus.partialPaid:
        return u.alertAccent;
    }
  }

  Color _paymentStatusAlertBg(_LedgerUi u, LedgerPaymentStatus s) {
    switch (s) {
      case LedgerPaymentStatus.fullyPaid:
        return u.dark ? const Color(0xFF1B3D24) : const Color(0xFFE8F5E9);
      case LedgerPaymentStatus.notPaid:
        return u.dark ? const Color(0xFF4A2632) : const Color(0xFFFFEBEE);
      case LedgerPaymentStatus.partialPaid:
        return u.alertBg;
    }
  }

  Widget _statusAlert(_LedgerUi u) {
    final s = controller.ledgerPaymentStatus;
    final accent = _paymentStatusAccent(u, s);
    final bg = _paymentStatusAlertBg(u, s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _isSw ? 'Hali ya Sasa' : 'Current Status',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: u.labelMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: u.dark ? Border.all(color: accent.withValues(alpha: 0.35)) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.ledgerPaymentStatusHeadline,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tenancyCard(_LedgerUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.cardShadow,
        border: u.dark ? Border.all(color: u.border.withValues(alpha: 0.65)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: u.dark ? const Color(0xFF80CBC4) : _LedgerUi.teal.withValues(alpha: 0.9),
                size: 26,
              ),
              Text(
                'TENANCY',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: u.labelMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isSw ? 'Ukaaji wa Sasa' : 'Current Stay',
            style: TextStyle(fontSize: 13, color: u.onSurfaceSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.currentStayMonths} Months',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            controller.tenancyRangeLabel,
            style: TextStyle(fontSize: 12, color: u.labelMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Current Lease: ${controller.currentLeaseMonths} Months',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: u.onSurfaceSecondary),
          ),
        ],
      ),
    );
  }

  Widget _financialBreakdownCard(_LedgerUi u, NumberFormat currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.financialCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.dark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
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
                      _isSw ? 'Jumla Inayodaiwa' : 'Total Due',
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
                      _isSw ? 'Jumla Iliyolipwa' : 'Total Paid',
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

  Widget _paymentTimelineSection(_LedgerUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Timeline',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Detailed view of the billing cycle. Discrepancies noted in the current active month.',
          style: TextStyle(fontSize: 13, height: 1.45, color: u.onSurfaceSecondary),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                Expanded(flex: 3, child: Container(color: _LedgerUi.teal)),
                Expanded(flex: 3, child: Container(color: _LedgerUi.teal)),
                Expanded(flex: 2, child: Container(color: _LedgerUi.tealMid)),
                Expanded(flex: 2, child: Container(color: u.timelineUnpaid)),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: u.timelineUpcomingFill,
                      border: Border.all(color: u.timelineUpcomingBorder, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _timelineLegend(u),
      ],
    );
  }

  Widget _timelineLegend(_LedgerUi u) {
    Widget cell(Color c, String label, {bool outline = false}) {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: outline ? u.timelineUpcomingFill : c,
              border: outline ? Border.all(color: u.timelineUpcomingBorder, width: 1.2) : null,
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
                color: u.onSurfaceSecondary,
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
            Expanded(child: cell(_LedgerUi.teal, 'FULLY PAID')),
            const SizedBox(width: 12),
            Expanded(child: cell(_LedgerUi.tealMid, 'PARTIALLY PAID')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cell(u.timelineUnpaid, 'UNPAID')),
            const SizedBox(width: 12),
            Expanded(child: cell(Colors.transparent, 'UPCOMING', outline: true)),
          ],
        ),
      ],
    );
  }

  Widget _actionSection(_LedgerUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Immediate Action Recommended',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Automate communication to resolve the pending balance for July and August.',
          style: TextStyle(fontSize: 14, height: 1.45, color: u.onSurfaceSecondary),
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
              backgroundColor: _LedgerUi.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.openSendSmsShortcut,
            icon: const Icon(Icons.sms_outlined, size: 20),
            label: Text(
              _isSw ? 'TUMA SMS / WHATSAPP' : 'SEND SMS / WHATSAPP',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: u.dark ? const Color(0xFF80CBC4) : _LedgerUi.teal,
              side: BorderSide(color: u.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
              color: u.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: u.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signed Contract / Lease',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: u.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.contractFileName,
                  style: TextStyle(fontSize: 12, color: u.onSurfaceSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: controller.pickAndUploadSignedContract,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(
                        _isSw ? 'Pakia PDF/Word' : 'Upload PDF/Word',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: u.dark ? const Color(0xFF80CBC4) : _LedgerUi.teal,
                        side: BorderSide(color: u.border),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.openSignedContract,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        _isSw ? 'Fungua' : 'Open',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: u.dark ? const Color(0xFF80CBC4) : _LedgerUi.teal,
                        side: BorderSide(color: u.border),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.openEditLeaseTermsDialog,
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: Text(
                        _isSw ? 'Hariri masharti ya mkataba' : 'Edit lease terms',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: u.dark ? const Color(0xFF80CBC4) : _LedgerUi.teal,
                        side: BorderSide(color: u.border),
                      ),
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

  Widget _residenceProfileCard(_LedgerUi u) {
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
                color: u.imagePlaceholder,
                child: Icon(Icons.apartment, size: 56, color: u.onSurface.withValues(alpha: 0.5)),
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
                      _isSw ? 'Mpangaji wa Hadhi' : 'Premium Tenant',
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

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_tenant_ledger_occupancy_controller.dart';
import '../utils/tenant_ledger_document_store.dart';

/// Semantic colors for ledger screen (light + dark).
class _LedgerUi {
  _LedgerUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);

  bool get dark => _t.brightness == Brightness.dark;

  static const Color teal = Color(0xFF0E6666);

  AppThemeTokens get _tokens => context.tokens;

  Color get onSurface => _tokens.textPrimary;

  Color get onSurfaceSecondary => _tokens.textSecondary;

  Color get labelMuted => _tokens.textMuted;

  Color get card => _tokens.cardBackground;

  Color get border => _tokens.border;

  Color get alertBg => dark ? const Color(0xFF3D2A28) : const Color(0xFFFCE1D9);

  Color get alertAccent =>
      dark ? const Color(0xFFFFAB91) : const Color(0xFF5C4033);

  Color get imagePlaceholder => _tokens.elevatedSurface;

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
class RentTenantLedgerOccupancyView
    extends RentBaseView<RentTenantLedgerOccupancyController> {
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
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
    _isSw ? 'Daftari la Mpangaji' : 'Tenant Ledger',
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: controller.goBackToTenancyInsights,
    ),
  );

  @override
  Widget body(BuildContext context) {
    final u = _LedgerUi(context);
    final currency = Get.find<CurrencyService>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) controller.goBackToTenancyInsights();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSw ? 'Muhtasari' : 'Ledger overview',
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
            Obx(() => _paymentHistorySection(u, currency)),
            const SizedBox(height: 22),
            Obx(() => _documentsSection(u)),
            const SizedBox(height: 22),
            _actionSection(u),
            const SizedBox(height: 22),
            _residenceProfileCard(u),
          ],
        ),
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
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: u.onSurfaceSecondary,
        ),
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
            border: u.dark
                ? Border.all(color: accent.withValues(alpha: 0.35))
                : null,
          ),
          child: Row(
            children: [
              Container(width: 10, height: 10, color: accent),
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
        border: u.dark
            ? Border.all(color: u.border.withValues(alpha: 0.65))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: u.dark
                    ? const Color(0xFF80CBC4)
                    : _LedgerUi.teal.withValues(alpha: 0.9),
                size: 26,
              ),
              Text(
                'Tenancy',
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
            controller.currentStayLabel,
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
            _isSw
                ? 'Mkataba: ${controller.leaseDurationLabel}'
                : 'Lease term: ${controller.leaseDurationLabel}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: u.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialBreakdownCard(_LedgerUi u, CurrencyService currency) {
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
            'Financial ledger breakdown',
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currency.formatBase(controller.remainingBalanceTsh),
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
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.formatBase(controller.totalDueTsh),
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
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.formatBase(controller.totalPaidTsh),
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

  Widget _paymentHistorySection(_LedgerUi u, CurrencyService currency) {
    final rows = controller.paymentHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Malipo yaliyofanywa' : 'Payments made',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text(
            _isSw ? 'Hakuna malipo yaliyorekodiwa bado.' : 'No payments recorded yet.',
            style: TextStyle(fontSize: 14, color: u.onSurfaceSecondary),
          )
        else
          ...rows.map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: u.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: u.border),
                boxShadow: u.cardShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.formatBase(p.amountTsh),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: u.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.category} · ${p.dateLabel}',
                          style: TextStyle(fontSize: 12, color: u.labelMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _isSw ? 'Tengeneza risiti' : 'Generate receipt',
                    onPressed: () => controller.generateReceipt(payment: p),
                    icon: const Icon(Icons.receipt_long_outlined),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _documentsSection(_LedgerUi u) {
    final docs = controller.documentHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Ankara na risiti' : 'Invoices & receipts',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (docs.isEmpty)
          Text(
            _isSw
                ? 'Hakuna hati zilizotengenezwa bado.'
                : 'No documents generated yet.',
            style: TextStyle(fontSize: 14, color: u.onSurfaceSecondary),
          )
        else
          ...docs.map((d) {
            final isInvoice = d.type == TenantLedgerDocumentType.invoice;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: u.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: u.border),
              ),
              child: Row(
                children: [
                  Icon(
                    isInvoice ? Icons.request_quote_outlined : Icons.receipt_outlined,
                    color: _LedgerUi.teal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: u.onSurface,
                          ),
                        ),
                        Text(
                          d.summary,
                          style: TextStyle(fontSize: 12, color: u.labelMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.openDocument(d),
                    icon: const Icon(Icons.open_in_new, size: 20),
                  ),
                  IconButton(
                    onPressed: () => controller.shareDocument(d, viaWhatsApp: true),
                    icon: const Icon(Icons.chat_outlined, size: 20),
                  ),
                  IconButton(
                    onPressed: () => controller.shareDocument(d, viaWhatsApp: false),
                    icon: const Icon(Icons.email_outlined, size: 20),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _actionSection(_LedgerUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Hatua inayopendekezwa' : 'Immediate Action Recommended',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.actionRecommendationText,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: u.onSurfaceSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.openRecordPayment,
            icon: const Icon(Icons.payments_outlined, size: 22),
            label: Text(
              _isSw ? 'Rekodi malipo' : 'Record payment',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _LedgerUi.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.generateInvoice,
                icon: const Icon(Icons.request_quote_outlined, size: 18),
                label: Text(
                  _isSw ? 'Ankara' : 'Invoice',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.generateReceipt(),
                icon: const Icon(Icons.receipt_outlined, size: 18),
                label: Text(
                  _isSw ? 'Risiti' : 'Receipt',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.shareLatestInvoiceViaWhatsApp,
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: Text(
                  'WhatsApp',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.shareLatestInvoiceViaEmail,
                icon: const Icon(Icons.email_outlined, size: 18),
                label: Text(
                  _isSw ? 'Barua pepe' : 'Email',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.openPaymentReminder,
            icon: const Icon(Icons.campaign_outlined, size: 22),
            label: const Text(
              'Set payment reminder',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _LedgerUi.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
              _isSw ? 'Tuma SMS / WhatsApp' : 'Send SMS / WhatsApp',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: u.dark
                  ? const Color(0xFF80CBC4)
                  : _LedgerUi.teal,
              side: BorderSide(color: u.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.onViewStory,
                icon: const Icon(Icons.timeline_outlined, size: 18),
                label: Text(
                  _isSw ? 'Historia' : 'View Story',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: u.dark
                      ? const Color(0xFF80CBC4)
                      : _LedgerUi.teal,
                  side: BorderSide(color: u.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.onEndTenancy(u.context),
                icon: const Icon(
                  Icons.exit_to_app_outlined,
                  size: 18,
                  color: Colors.red,
                ),
                label: Text(
                  _isSw ? 'Maliza Upangaji' : 'End Tenancy',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: u.onSurface,
                  ),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: u.dark
                            ? const Color(0xFF80CBC4)
                            : _LedgerUi.teal,
                        side: BorderSide(color: u.border),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.openSignedContract,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        _isSw ? 'Fungua' : 'Open',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: u.dark
                            ? const Color(0xFF80CBC4)
                            : _LedgerUi.teal,
                        side: BorderSide(color: u.border),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.openEditLeaseTermsDialog,
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: Text(
                        _isSw
                            ? 'Hariri masharti ya mkataba'
                            : 'Edit lease terms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: u.dark
                            ? const Color(0xFF80CBC4)
                            : _LedgerUi.teal,
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
                child: Icon(
                  Icons.apartment,
                  size: 56,
                  color: u.onSurface.withValues(alpha: 0.5),
                ),
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
                  'Residence profile',
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
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      RentTenantLedgerOccupancyController.residencyCity,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSw ? 'Mpangaji wa Hadhi' : 'Premium Tenant',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
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

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

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
    _isSw ? 'Mpangaji' : 'Tenant',
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_outlined),
      onPressed: controller.goBackToTenancyInsights,
    ),
  );

  @override
  Widget body(BuildContext context) {
    final u = _LedgerUi(context);
    final currency = Get.find<CurrencyService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   _isSw ? 'Muhtasari' : 'Ledger overview',
          //   style: TextStyle(
          //     fontSize: 10,
          //     letterSpacing: 1.4,
          //     fontWeight: FontWeight.w800,
          //     color: Colors.grey.shade600,
          //   ),
          // ),
          // Above the fold, in the order a host actually needs it: who this
          // is, whether they are paid up, what they owe, and how to reach
          // them. The old order opened with a 28px name, a full-width Edit
          // button and a prose paragraph, so the balance — the reason for
          // opening a ledger — sat below the first screen. Edit is now a
          // text button on the details card: it is maintenance, not
          // information, and belongs next to the fields it changes.
          const SizedBox(height: 4),
          Obx(() => _identityHeader(u)),
          const SizedBox(height: 14),
          Obx(() => _balanceSummary(u, currency)),
          const SizedBox(height: 12),
          Obx(() => _contactRow(u)),
          const SizedBox(height: 20),
          Obx(() => _tenantDetailsCard(u)),
          const SizedBox(height: 14),
          Obx(() => _tenancyCard(u)),
          const SizedBox(height: 14),
          Obx(() => _financialBreakdownCard(u, currency)),
          const SizedBox(height: 14),
          Obx(() => _lastInvoiceCard(u, currency)),
          const SizedBox(height: 22),
          Obx(() => _paymentHistorySection(u, currency)),
          const SizedBox(height: 22),
          Obx(() => _expenseHistorySection(u, currency)),
          const SizedBox(height: 22),
          Obx(() => _documentsSection(u)),
          const SizedBox(height: 22),
          _actionSection(u),
        ],
      ),
    );
  }

  /// Name, unit and payment status in one block.
  ///
  /// The status pill sits beside the name rather than in its own labelled
  /// section further down, because "who" and "are they paid" are read
  /// together and were previously separated by about a screen of height.
  Widget _identityHeader(_LedgerUi u) {
    final status = controller.ledgerPaymentStatus;
    final accent = _paymentStatusAccent(u, status);
    final bg = _paymentStatusAlertBg(u, status);
    final unit = controller.tenantUnitLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.displayTenantName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: u.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unit.isEmpty
                    ? controller.propertyShortPhrase
                    : '$unit · ${controller.propertyShortPhrase}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: u.onSurfaceSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Text(
            controller.ledgerPaymentStatusHeadline,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }

  /// The figure the screen exists to answer, stated once and large.
  ///
  /// Shows outstanding when there is one and paid-to-date when there is not,
  /// rather than printing "Outstanding 0" — which is true but makes the host
  /// read a number to learn there is nothing to read.
  Widget _balanceSummary(_LedgerUi u, CurrencyService currency) {
    final outstanding = controller.remainingBalanceTsh;
    final settled = outstanding <= 0;
    final status = controller.ledgerPaymentStatus;
    final accent = settled
        ? _paymentStatusAccent(u, LedgerPaymentStatus.fullyPaid)
        : _paymentStatusAccent(u, status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: u.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settled
                ? (_isSw ? 'JUMLA ILIYOLIPWA' : 'PAID TO DATE')
                : (_isSw ? 'SALIO LINALODAIWA' : 'OUTSTANDING'),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: u.labelMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currency.formatBase(
              settled ? controller.totalPaidTsh : outstanding,
            ),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1.05,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSw
                ? 'Imelipwa ${currency.formatBase(controller.totalPaidTsh)} kati ya ${currency.formatBase(controller.totalDueTsh)} · ${controller.currentStayLabel}'
                : '${currency.formatBase(controller.totalPaidTsh)} paid of ${currency.formatBase(controller.totalDueTsh)} · ${controller.currentStayLabel}',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: u.onSurfaceSecondary,
            ),
          ),
          if (!settled) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.openRecordPayment,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(
                  _isSw ? 'Rekodi malipo' : 'Record payment',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _LedgerUi.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Call, message and WhatsApp, reachable without scrolling.
  ///
  /// Returns nothing at all when no number is stored: three dead buttons
  /// would imply the contact exists and the app is failing to use it.
  Widget _contactRow(_LedgerUi u) {
    if (!controller.tenantHasPhone) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _contactAction(
            u,
            icon: Icons.call_outlined,
            label: _isSw ? 'Piga simu' : 'Call',
            onTap: controller.callTenant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _contactAction(
            u,
            icon: Icons.sms_outlined,
            label: _isSw ? 'SMS' : 'Message',
            onTap: controller.openSendSmsShortcut,
          ),
        ),
        if (controller.tenantHasWhatsapp) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _contactAction(
              u,
              icon: Icons.chat_outlined,
              label: 'WhatsApp',
              onTap: controller.whatsappTenant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _contactAction(
    _LedgerUi u, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final accent = u.dark ? const Color(0xFF80CBC4) : _LedgerUi.teal;
    return Material(
      color: accent.withValues(alpha: u.dark ? 0.18 : 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The tenant's own particulars — previously absent from this screen
  /// entirely. The bottom of the page carried a stock photo captioned
  /// "Premium Tenant" and a hardcoded city instead, which told the host
  /// nothing about the person whose ledger they had opened.
  ///
  /// Rows are omitted when the underlying field is empty, so the card never
  /// shows a dash that could be mistaken for stored data.
  ///
  /// Deliberately holds only the person's own particulars. Rent, rate and
  /// lease dates live in [_tenancyCard] directly below — repeating them here
  /// would state the same fact twice from two different getters, which is how
  /// two figures end up disagreeing after one of them is changed.
  Widget _tenantDetailsCard(_LedgerUi u) {
    final phone = controller.tenantPhone;
    final email = controller.tenantEmail;
    final gender = controller.tenantGender;
    final unit = controller.tenantUnitLabel;

    final rows = <Widget>[
      if (phone.isNotEmpty)
        _detailRow(
          u,
          icon: Icons.phone_outlined,
          label: _isSw ? 'Simu' : 'Phone',
          value: controller.tenantHasWhatsapp ? '$phone  ·  WhatsApp' : phone,
          onTap: controller.copyTenantPhone,
          trailing: Icons.copy_outlined,
        ),
      if (email.isNotEmpty)
        _detailRow(
          u,
          icon: Icons.mail_outline,
          label: _isSw ? 'Barua pepe' : 'Email',
          value: email,
        ),
      if (unit.isNotEmpty)
        _detailRow(
          u,
          icon: Icons.meeting_room_outlined,
          label: _isSw ? 'Chumba' : 'Unit',
          value: unit,
        ),
      if (gender.isNotEmpty)
        _detailRow(
          u,
          icon: Icons.person_outline,
          label: _isSw ? 'Jinsia' : 'Gender',
          value: gender,
        ),
      // Nothing on file at all. Says so and points at Edit, rather than
      // rendering a titled card with an empty body.
      if (phone.isEmpty && email.isEmpty && unit.isEmpty && gender.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            _isSw
                ? 'Hakuna maelezo ya mawasiliano yaliyohifadhiwa. Gusa Hariri ili kuongeza simu au barua pepe.'
                : 'No contact details on file. Tap Edit to add a phone number or email.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: u.onSurfaceSecondary,
            ),
          ),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: u.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSw ? 'MAELEZO YA MPANGAJI' : 'TENANT DETAILS',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: u.labelMuted,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: controller.openEditLeaseTermsDialog,
                icon: const Icon(Icons.edit_outlined, size: 15),
                style: TextButton.styleFrom(
                  foregroundColor: u.dark
                      ? const Color(0xFF80CBC4)
                      : _LedgerUi.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  visualDensity: VisualDensity.compact,
                ),
                label: Text(
                  _isSw ? 'Hariri' : 'Edit',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(
    _LedgerUi u, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    IconData? trailing,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 17, color: u.labelMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: u.onSurfaceSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: u.onSurface,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Icon(trailing, size: 15, color: u.labelMuted),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
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
                Icons.calendar_month_outlined,
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
                  fontWeight: FontWeight.w700,
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
              fontWeight: FontWeight.w600,
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
          const SizedBox(height: 14),
          Divider(height: 1, color: u.border.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          Text(
            controller.rateCaption,
            style: TextStyle(fontSize: 12, color: u.onSurfaceSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            controller.rateLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: u.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lastInvoiceCard(_LedgerUi u, CurrencyService currency) {
    final invoice = controller.lastRentInvoice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.cardShadow,
        border: Border.all(color: u.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Ankara ya mwisho ya kodi' : 'Last rent invoice',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: u.labelMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (invoice == null)
            Text(
              _isSw
                  ? 'Hakuna ankara iliyotengenezwa bado.'
                  : 'No invoice generated yet.',
              style: TextStyle(fontSize: 14, color: u.onSurfaceSecondary),
            )
          else ...[
            Text(
              invoice.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: u.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currency.formatBase(invoice.amountTsh),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: u.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${invoice.summary} · ${controller.lastInvoiceDateLabel(invoice)}',
              style: TextStyle(fontSize: 12, color: u.labelMuted),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => controller.openDocument(invoice),
                icon: const Icon(Icons.open_in_new_outlined, size: 18),
                label: Text(_isSw ? 'Fungua' : 'Open'),
              ),
            ),
          ],
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
              fontWeight: FontWeight.w700,
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
              fontWeight: FontWeight.w600,
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

  Widget _expenseHistorySection(_LedgerUi u, CurrencyService currency) {
    final rows = controller.expenseHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Orodha ya gharama' : 'Expenses',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text(
            _isSw
                ? 'Hakuna gharama zilizohusishwa na mpangaji/mali hii.'
                : 'No expenses linked to this tenant/property yet.',
            style: TextStyle(fontSize: 14, color: u.onSurfaceSecondary),
          )
        else
          ...rows.map(
            (e) => Container(
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
                          e.item,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: u.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${e.category} · ${e.dateLabel}',
                          style: TextStyle(fontSize: 12, color: u.labelMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currency.formatBase(e.amountTsh),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: u.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text(
            _isSw
                ? 'Hakuna malipo yaliyorekodiwa bado.'
                : 'No payments recorded yet.',
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
                            fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w700,
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
                    isInvoice
                        ? Icons.request_quote_outlined
                        : Icons.receipt_outlined,
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
                    icon: const Icon(Icons.open_in_new_outlined, size: 20),
                  ),
                  IconButton(
                    onPressed: () =>
                        controller.shareDocument(d, viaWhatsApp: true),
                    icon: const Icon(Icons.chat_outlined, size: 20),
                  ),
                  IconButton(
                    onPressed: () =>
                        controller.shareDocument(d, viaWhatsApp: false),
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
            fontWeight: FontWeight.w700,
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
        // Record payment is not repeated here. It now sits on the balance
        // card above, next to the figure it settles, which is both earlier in
        // the page and the only place it appears.
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.generateInvoice,
                icon: const Icon(Icons.request_quote_outlined, size: 18),
                label: Text(
                  _isSw ? 'Ankara' : 'Invoice',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
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
                fontWeight: FontWeight.w700,
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                        _isSw ? 'PDF, Word, au picha' : 'PDF, Word, or image',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
                      icon: const Icon(Icons.open_in_new_outlined, size: 18),
                      label: Text(
                        _isSw ? 'Fungua' : 'Open',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
}

import 'package:flutter/material.dart';
import '../../../../core/widget/skeleton_presets.dart';

import '../../../../core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';
import '../../../../core/base/rent_base_view.dart';
import '../../../../core/utils/rent_expected_payment_schedule.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../rent_theme.dart';
import '../controllers/rent_expected_payment_schedule_controller.dart';

class RentExpectedPaymentScheduleView
    extends RentBaseView<RentExpectedPaymentScheduleController> {
  RentExpectedPaymentScheduleView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  static const _propertyColWidth = 132.0;
  static const _monthColWidth = 72.0;
  static const _teal = Color(0xFF005F5F);

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
        appBarTitleText: _isSw
            ? 'Ratiba ya Malipo ${controller.displayYear}'
            : 'Expected Payments ${controller.displayYear}',
        showLanguageToggle: false,
        showThemeToggle: false,
      );

  @override
  Widget body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? context.tokens.cardBackground : Colors.white;
    final muted = isDark ? const Color(0xFFAEAEB2) : RentTheme.muted;
    final text = isDark ? Colors.white : RentTheme.navy;
    final currency = Get.find<CurrencyService>();

    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }

      final snap = controller.schedule.value;
      if (snap == null) {
        return Center(
          child: Text(
            _isSw ? 'Hakuna data' : 'No data',
            style: TextStyle(color: muted),
          ),
        );
      }

      final now = DateTime.now();
      final currentMonthIndex = snap.year == now.year ? now.month - 1 : -1;

      return RefreshIndicator(
        color: _teal,
        onRefresh: controller.loadSchedule,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _summaryCard(snap, currency, card, text, muted),
            const SizedBox(height: 16),
            Text(
              _isSw
                  ? 'Miezi unayotarajiwa kulipwa na wapangaji (mali zote)'
                  : 'Months you are expected to be paid by tenants (all properties)',
              style: TextStyle(fontSize: 13, height: 1.4, color: muted),
            ),
            const SizedBox(height: 12),
            if (snap.properties.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    _isSw
                        ? 'Hakuna mikataba hai yenye kodi kwa mwaka huu.'
                        : 'No active leases with rent due this year.',
                    style: TextStyle(color: muted, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              _scheduleTable(
                context: context,
                snap: snap,
                currency: currency,
                card: card,
                text: text,
                muted: muted,
                currentMonthIndex: currentMonthIndex,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _legend(muted),
            ],
          ],
        ),
      );
    });
  }

  Widget _summaryCard(
    ExpectedPaymentScheduleSnapshot snap,
    CurrencyService currency,
    Color card,
    Color text,
    Color muted,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'JUMLA YA MWAKA' : 'YEAR TOTAL EXPECTED',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currency.formatBase(snap.grandTotal.round()),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isSw
                ? '${snap.properties.length} mali • ${snap.year}'
                : '${snap.properties.length} properties • ${snap.year}',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _scheduleTable({
    required BuildContext context,
    required ExpectedPaymentScheduleSnapshot snap,
    required CurrencyService currency,
    required Color card,
    required Color text,
    required Color muted,
    required int currentMonthIndex,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF48484A) : const Color(0xFFE6E1D7),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(snap, muted, currentMonthIndex, context, isDark),
              _totalRow(
                label: _isSw ? 'Jumla' : 'Total',
                amounts: snap.monthTotals,
                yearTotal: snap.grandTotal,
                currency: currency,
                text: text,
                muted: muted,
                highlight: false,
                isDark: isDark,
                bold: true,
              ),
              const Divider(height: 1),
              ...snap.properties.map((p) {
                final expanded = controller.isPropertyExpanded(p.propertyKey);
                return Column(
                  children: [
                    InkWell(
                      onTap: () =>
                          controller.togglePropertyExpanded(p.propertyKey),
                      child: _totalRow(
                        label: p.propertyLabel,
                        amounts: p.monthlyAmounts,
                        yearTotal: p.yearTotal,
                        currency: currency,
                        text: text,
                        muted: muted,
                        highlight: false,
                        isDark: isDark,
                        bold: false,
                        leading: Icon(
                          expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 18,
                          color: muted,
                        ),
                        propertyColWidth: _propertyColWidth,
                      ),
                    ),
                    if (expanded)
                      ...p.tenantRows.map(
                        (t) => _tenantRow(
                          t,
                          currency,
                          muted,
                          currentMonthIndex,
                          isDark,
                        ),
                      ),
                    const Divider(height: 1),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow(
    ExpectedPaymentScheduleSnapshot snap,
    Color muted,
    int currentMonthIndex,
    BuildContext context, bool isDark,
  ) {
    return Container(
      color: isDark ? context.tokens.scaffoldBackground : const Color(0xFFF4F1EA),
      child: Row(
        children: [
          SizedBox(
            width: _propertyColWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Text(
                _isSw ? 'Mali' : 'Property',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: muted,
                ),
              ),
            ),
          ),
          ...List.generate(12, (i) {
            final highlight = i == currentMonthIndex;
            return Container(
              width: _monthColWidth,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: highlight
                  ? BoxDecoration(
                      color: _teal.withValues(alpha: 0.12),
                      border: Border(
                        bottom: BorderSide(color: _teal, width: 2),
                      ),
                    )
                  : null,
              child: Text(
                ExpectedPaymentScheduleSnapshot.monthLabels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: highlight ? _teal : muted,
                ),
              ),
            );
          }),
          SizedBox(
            width: _monthColWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Text(
                _isSw ? 'Mwaka' : 'Year',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow({
    required String label,
    required List<double> amounts,
    required double yearTotal,
    required CurrencyService currency,
    required Color text,
    required Color muted,
    required bool highlight,
    required bool isDark,
    required bool bold,
    Widget? leading,
    double propertyColWidth = _propertyColWidth,
  }) {
    return Row(
      children: [
        SizedBox(
          width: propertyColWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
            child: Row(
              children: [
                if (leading != null) leading,
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...List.generate(12, (i) => _amountCell(
              amounts[i],
              currency,
              muted,
              bold: bold,
            )),
        _amountCell(yearTotal, currency, muted, bold: bold, wide: true),
      ],
    );
  }

  Widget _tenantRow(
    TenantExpectedPaymentRow t,
    CurrencyService currency,
    Color muted,
    int currentMonthIndex,
    bool isDark,
  ) {
    return Container(
      color: isDark
          ? const Color(0xFF252528)
          : const Color(0xFFFAFAF8),
      child: Row(
        children: [
          SizedBox(
            width: _propertyColWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 6, 4, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.tenantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  if (t.unitLabel.isNotEmpty)
                    Text(
                      t.unitLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: muted.withValues(alpha: 0.8)),
                    ),
                ],
              ),
            ),
          ),
          ...List.generate(12, (i) => _amountCell(
                t.monthlyAmounts[i],
                currency,
                muted,
                bold: false,
                dimEmpty: true,
              )),
          _amountCell(t.yearTotal, currency, muted, bold: false, wide: true),
        ],
      ),
    );
  }

  Widget _amountCell(
    double amount,
    CurrencyService currency,
    Color muted, {
    required bool bold,
    bool wide = false,
    bool dimEmpty = false,
  }) {
    final empty = amount <= 0;
    final label = empty
        ? '—'
        : _compactMoney(currency.formatBase(amount.round()));
    return SizedBox(
      width: wide ? _monthColWidth : _monthColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: empty && dimEmpty
                ? muted.withValues(alpha: 0.45)
                : (empty ? muted : (bold ? _teal : muted)),
          ),
        ),
      ),
    );
  }

  static String _compactMoney(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length <= 6) return formatted;
    final n = int.tryParse(digits) ?? 0;
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).round()}k';
    }
    return formatted;
  }

  Widget _legend(Color muted) {
    return Text(
      _isSw
          ? 'Makadirio kutoka kwa kodi, mzunguko wa malipo, na tarehe za mkataba. Bofya mali kuona wapangaji.'
          : 'Estimates from rent amount, payment frequency, and lease dates. Tap a property to see tenants.',
      style: TextStyle(fontSize: 11, height: 1.35, color: muted),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_tenant_residency_payment_tracker_controller.dart';

/// **Tenancy Insights** — overview metrics, search, tenant residency cards, FAB, bottom nav.
class RentTenantResidencyPaymentTrackerView
    extends BaseView<RentTenantResidencyPaymentTrackerController> {
  RentTenantResidencyPaymentTrackerView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  static const _teal = Color(0xFF004D40);

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(controller.tenantsScreenTitle);

  @override
  Widget body(BuildContext context) {
    final currency = NumberFormat.currency(symbol: r'TZS', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'MUHTASARI' : 'OVERVIEW',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _overviewMetricsCard(context),
          const SizedBox(height: 18),
          _searchRow(context),
          const SizedBox(height: 18),
          Obx(() {
            final list = controller.filteredTenants;
            return Column(
              children: list
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _tenantCard(t, currency),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget? floatingActionButton() {
    return FloatingActionButton(
      onPressed: () => controller.openSendSmsForFilteredTenants,
      child: const Icon(Icons.chat_bubble_outline),
    );
  }

  Widget _overviewMetricsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final labelMuted = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade600;
    final dividerColor = isDark
        ? const Color(0xFF3A3A3C)
        : Colors.grey.shade300;
    final shadowAlpha = isDark ? 0.32 : 0.04;
    final activeLeaseColor = isDark ? const Color(0xFF5EC9C3) : _teal;
    final collectionColor = isDark
        ? const Color(0xFFFF8A80)
        : const Color(0xFF8B3A3A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw ? 'MIKATABA HAI' : 'ACTIVE LEASES',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: labelMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${controller.activeLeasesCount}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: activeLeaseColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 52, color: dividerColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSw ? 'KIWANGO CHA MAKUSANYO' : 'COLLECTION RATE',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: labelMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.collectionRatePct}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: collectionColor,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final hintColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade500;
    final inputColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final borderSide = isDark
        ? const BorderSide(color: Color(0xFF3A3A3C))
        : BorderSide.none;
    final filterIconColor = isDark
        ? const Color(0xFF5EC9C3)
        : _teal.withValues(alpha: 0.85);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            style: TextStyle(color: inputColor, fontSize: 14),
            cursorColor: isDark ? const Color(0xFF5EC9C3) : _teal,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fieldBg,
              hintText: _isSw ? 'Tafuta wapangaji' : 'Search tenants',
              hintStyle: TextStyle(color: hintColor, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: hintColor, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: borderSide,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: borderSide,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: isDark
                    ? const BorderSide(color: Color(0xFF5EC9C3), width: 1.2)
                    : BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: controller.onFilterPressed,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.tune_rounded, color: filterIconColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tenantCard(TenantInsight t, NumberFormat currency) {
    final pct = (t.leaseProgress * 100).round();
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryText = isDark
        ? const Color(0xFFB0B3BA)
        : Colors.grey.shade700;
    final tertiaryText = isDark
        ? const Color(0xFF8E8E93)
        : Colors.grey.shade600;
    final progressBg = isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200;

    return Material(
      color: cardBg,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.openTenantLedger(t),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: _teal.withValues(alpha: 0.1),
                      alignment: Alignment.center,
                      child: Text(
                        t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _teal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.home_outlined,
                              size: 16,
                              color: tertiaryText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                t.propertyLine,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _isSw
                            ? 'MUDA WA JUMLA WA UKAAJI'
                            : 'TOTAL STAY DURATION',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                          color: tertiaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.totalStayLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_isSw ? 'MAENDELEO YA MKATABA' : 'LEASE PROGRESS'} (${t.leasePeriodLabel})',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: secondaryText,
                      ),
                    ),
                  ),
                  Text(
                    _isSw ? '$pct% IMEKAMILIKA' : '$pct% COMPLETE',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: t.leaseProgress,
                  minHeight: 8,
                  backgroundColor: progressBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(_teal),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isSw
                    ? 'DAFTARI LA HALI YA MALIPO (MUDA WA SASA)'
                    : 'PAYMENT STATUS LEDGER (CURRENT TERM)',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: tertiaryText,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: Row(
                  children: List.generate(
                    t.monthStatuses.length,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i < t.monthStatuses.length - 1 ? 6 : 0,
                        ),
                        child: _monthBox(
                          i + 1,
                          t.monthStatuses[i],
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  t.onSchedule
                      ? _onScheduleBadge(isDark: isDark)
                      : _statusLegend(isDark: isDark),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _isSw ? 'MUHTASARI WA FEDHA' : 'FINANCIAL SUMMARY',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: tertiaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          children: [
                            TextSpan(
                              text: currency.format(t.paidAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _teal,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${currency.format(t.totalAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: tertiaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthBox(
    int monthIndex,
    ResidencyMonthStatus s, {
    required bool isDark,
  }) {
    late Color bg;
    late Color fg;
    switch (s) {
      case ResidencyMonthStatus.paid:
        bg = _teal;
        fg = Colors.white;
      case ResidencyMonthStatus.partial:
        bg = const Color(0xFFFFCDD2);
        fg = const Color(0xFF5D1A1A);
      case ResidencyMonthStatus.upcoming:
        bg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8);
        fg = isDark ? const Color(0xFFB0B3BA) : Colors.grey.shade700;
    }
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'M$monthIndex',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _onScheduleBadge({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? _teal.withValues(alpha: 0.24)
            : _teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _isSw ? 'KATIKA RATIBA' : 'ON SCHEDULE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: _teal,
        ),
      ),
    );
  }

  Widget _statusLegend({required bool isDark}) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _legendDot(_teal, _isSw ? 'IMELIPWA' : 'PAID', isDark: isDark),
        _legendDot(
          const Color(0xFFFFCDD2),
          _isSw ? 'SEHEMU' : 'PARTIAL',
          dark: true,
          isDark: isDark,
        ),
        _legendDot(
          isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8),
          _isSw ? 'INAKUJA' : 'UPCOMING',
          dark: true,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _legendDot(
    Color c,
    String label, {
    bool dark = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: dark
                ? (isDark ? const Color(0xFFB0B3BA) : Colors.grey.shade700)
                : _teal,
          ),
        ),
      ],
    );
  }
}

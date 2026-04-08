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
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(_isSw ? 'Maarifa ya Upangaji' : 'Tenancy Insights');

  @override
  Widget body(BuildContext context) {
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

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
          _overviewMetricsCard(),
          const SizedBox(height: 18),
          _searchRow(),
          const SizedBox(height: 18),
          Obx(
            () {
              final list = controller.filteredTenants;
              return Column(
                children: list
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _tenantCard(t, currency),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _overviewMetricsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${controller.activeLeasesCount}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 52, color: Colors.grey.shade300),
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.collectionRatePct}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B3A3A),
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

  Widget _searchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              hintText: _isSw ? 'Tafuta wapangaji au mali' : 'Search tenants or properties',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: controller.onFilterPressed,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.tune_rounded, color: _teal.withValues(alpha: 0.85)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tenantCard(TenantInsight t, NumberFormat currency) {
    final pct = (t.leaseProgress * 100).round();

    return Material(
      color: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.home_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            t.propertyLine,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
                    _isSw ? 'MUDA WA JUMLA WA UKAAJI' : 'TOTAL STAY DURATION',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.totalStayLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
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
                  (_isSw ? 'MAENDELEO YA MKATABA' : 'LEASE PROGRESS') + ' (${t.leasePeriodLabel})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.grey.shade700,
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
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_teal),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isSw ? 'DAFTARI LA HALI YA MALIPO (MUDA WA SASA)' : 'PAYMENT STATUS LEDGER (CURRENT TERM)',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
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
                    padding: EdgeInsets.only(right: i < t.monthStatuses.length - 1 ? 6 : 0),
                    child: _monthBox(i + 1, t.monthStatuses[i]),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: t.onSchedule ? _onScheduleBadge() : _statusLegend()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'FINANCIAL SUMMARY',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, fontFamily: 'Roboto'),
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
                            color: Colors.grey.shade500,
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

  Widget _monthBox(int monthIndex, ResidencyMonthStatus s) {
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
        bg = const Color(0xFFE8E8E8);
        fg = Colors.grey.shade700;
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _onScheduleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.12),
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

  Widget _statusLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _legendDot(_teal, _isSw ? 'IMELIPWA' : 'PAID'),
        _legendDot(const Color(0xFFFFCDD2), _isSw ? 'SEHEMU' : 'PARTIAL', dark: true),
        _legendDot(const Color(0xFFE8E8E8), _isSw ? 'INAKUJA' : 'UPCOMING', dark: true),
      ],
    );
  }

  Widget _legendDot(Color c, String label, {bool dark = false}) {
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
            color: dark ? Colors.grey.shade700 : _teal,
          ),
        ),
      ],
    );
  }
}

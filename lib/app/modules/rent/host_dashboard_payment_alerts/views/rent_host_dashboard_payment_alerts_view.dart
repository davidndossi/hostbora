import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';
import '../../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';
import 'package:paa_yangu/app/modules/rent/widgets/rent_ui.dart';

import '../../../../core/base/rent_base_view.dart';
import '../controllers/rent_host_dashboard_payment_alerts_controller.dart';

class RentHostDashboardPaymentAlertsView extends RentBaseView<RentHostDashboardPaymentAlertsController> {
  RentHostDashboardPaymentAlertsView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
    _isSw ? 'Dashibodi ya Mwenyeji' : 'Host Dashboard'
  );

  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFFBFAF6);

  @override
  Widget body(BuildContext context) => Obx(() {
    final c = FormSurfaceColors.of(context);
    if (controller.loadingRealData.value) {
      return const DefaultScreenSkeleton();
    }
    final d = controller.realData.value;
    if (d == null) {
      return Center(
        child: Text(
          _isSw ? 'Hakuna data ya tahadhari za malipo bado.' : 'No payment alerts data available yet.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadAll,
      color: const Color(0xFF0A5C5C),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          const SizedBox(height: 14),
          Text(
            controller.estateName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: c.isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSw
                ? 'Karibu tena,\n${controller.hostDisplayName.value}'
                : 'Welcome back,\n${controller.hostDisplayName.value}',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 0.95,
              color: c.isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          _headlineMetrics(context),
          const SizedBox(height: 18),
          if (controller.urgentAlerts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: c.isDark ? const Color(0xFF323232) : const Color(0xFFE8E6E1),
                ),
              ),
              child: Text(
                _isSw
                    ? 'Hakuna wapangaji wenye salio linalosubiri ndani ya muda wa mkataba.'
                    : 'No tenants with pending balance found in the lease period.',
                style: TextStyle(
                  fontSize: 12,
                  color: c.isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            )
          else ...[
            _alertsHeader(context),
            const SizedBox(height: 10),
            ...controller.urgentAlerts.map((item) => _alertCard(context, item)),
            const SizedBox(height: 12),
            // _optimizeCard(context),
            // const SizedBox(height: 12),
            ...controller.urgentAlerts.skip(1).map((item) => _compactAlertRow(context, item)),
          ],
          // const SizedBox(height: 10),
          // Center(
          //   child: OutlinedButton.icon(
          //     onPressed: controller.onMonitorNewTenant,
          //     icon: const Icon(Icons.add_circle_outline_rounded),
          //     label: Text(_isSw ? 'Fuatilia Wapangaji Wote' : 'MONITOR ALL TENANTS'),
          //   ),
          // ),
          const SizedBox(height: 18),
          Text(
            _isSw ? 'Muhtasari wa Estate' : 'Estate Overview',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          _overviewTile(
            context: context,
            label: _isSw ? 'Mapato ya Mwezi' : 'Monthly Revenue',
            value: 'Tsh ${controller.formatMoney(controller.expectedRevenue)}',
            trailing: Text(
              '+0.4%',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // _overviewTile(
          //   context: context,
          //   label: _isSw ? 'Vitengo Vilivyojazwa' : 'Active Bookings',
          //   value: '${controller.activeBookings} Units',
          //   trailing: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //     decoration: BoxDecoration(
          //       color: c.isDark ? const Color(0xFF30364A) : const Color(0xFFEEF2FF),
          //       borderRadius: BorderRadius.circular(10),
          //     ),
          //     child: Text(
          //       'Kijego 360',
          //       style: TextStyle(
          //         fontSize: 10,
          //         fontWeight: FontWeight.w700,
          //         color: c.isDark ? Colors.white : null,
          //       ),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 8),
          _overviewTile(
            context: context,
            label: _isSw ? 'Viwango vya Ujazaji' : 'Occupancy Rate',
            value: '${controller.collectionRate.toStringAsFixed(1)}%',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircleAvatar(radius: 8, backgroundColor: Color(0xFF111827)),
                SizedBox(width: 4),
                CircleAvatar(radius: 8, backgroundColor: Color(0xFF374151)),
              ],
            ),
          ),
        ],
      ),
    );
  });

  Widget _headlineMetrics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _metricChip(
            context: context,
            label: _isSw ? 'Kiwango cha Makusanyo' : 'Collection Rate',
            value: '${controller.collectionRate.toStringAsFixed(1)}%',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricChip(
            context: context,
            label: _isSw ? 'Mapato Yanayotarajiwa' : 'Expected Revenue',
            value: 'Tsh ${controller.formatMoney(controller.expectedRevenue)}',
          ),
        ),
      ],
    );
  }

  Widget _metricChip({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final c = FormSurfaceColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.isDark ? const Color(0xFF323232) : const Color(0xFFEAE8E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: c.isDark ? Colors.white70 : const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: c.isDark ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertsHeader(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            _isSw ? 'Dharura: Malipo ya Sehemu' : 'Urgent: Partial Payments',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
        TextButton(
          onPressed: controller.onViewAllDelinquencies,
          child: Text(_isSw ? 'Tazama Yote' : 'View All'),
        ),
      ],
    );
  }

  Widget _alertCard(BuildContext context, HostPaymentAlertItem item) {
    final c = FormSurfaceColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.25 : 0.07),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD32F2F), width: 2),
                  color: c.isDark ? const Color(0xFF2A2E36) : const Color(0xFF111827),
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tenant,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: c.isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      item.propertyLabel,
                      style: TextStyle(fontSize: 11, color: c.isDark ? Colors.white70 : const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _smallStat(
                  context: context,
                  label: _isSw ? 'Malipo Hadi Sasa' : 'Paid To Date',
                  value: 'Tsh ${controller.formatMoney(item.paidToDate)}',
                ),
              ),
              Expanded(
                child: _smallStat(
                  context: context,
                  label: _isSw ? 'Baki' : 'Balance',
                  value: 'Tsh ${controller.formatMoney(item.balance)}',
                ),
              ),
              Expanded(
                child: _smallStat(
                  context: context,
                  label: _isSw ? 'Tarehe ya Mwisho' : 'Due Date',
                  value: controller.formatDueDate(item.dueDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: item.progressPaid,
              backgroundColor: c.isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB),
              color: const Color(0xFF0A5C5C),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => controller.onSendLateNotice(item),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C5C),
                foregroundColor: Colors.white,
              ),
              child: Text(_isSw ? 'Weka Kikumbusho' : 'Set Reminder'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStat({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final c = FormSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: c.isDark ? Colors.white70 : const Color(0xFF6B7280))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: c.isDark ? Colors.white : null,
          ),
        ),
      ],
    );
  }

  Widget _optimizeCard(BuildContext context) {
    return Container(
      height: 125,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage('images/bed-and-breakfast.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0x66000000), BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Optimize Cash Flow',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            Text(
              _isSw
                  ? 'AI inapendekeza kuhamisha mikakati ya malipo ya wapangaji.'
                  : 'AI smart reminders can help improve rent collection by up to 40%.',
              style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactAlertRow(BuildContext context, HostPaymentAlertItem item) {
    final c = FormSurfaceColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.isDark ? const Color(0xFF323232) : const Color(0xFFE7E5DD)),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.tenant,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: c.isDark ? Colors.white : null,
                  ),
                ),
                Text(
                  item.propertyLabel,
                  style: TextStyle(fontSize: 10, color: c.isDark ? Colors.white70 : const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Tsh ${controller.formatMoney(item.balance)}',
                style: TextStyle(fontWeight: FontWeight.w700, color: c.isDark ? Colors.white : null),
              ),
              Text(
                controller.formatDueDate(item.dueDate),
                style: TextStyle(fontSize: 10, color: c.isDark ? Colors.white70 : const Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => controller.onSendLateNotice(item),
            child: Text(_isSw ? 'Kumbusha' : 'Send Late Notice'),
          ),
        ],
      ),
    );
  }

  Widget _overviewTile({
    required BuildContext context,
    required String label,
    required String value,
    required Widget trailing,
  }) {
    final c = FormSurfaceColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.isDark ? const Color(0xFF323232) : const Color(0xFFE8E6E1)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF4EF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.credit_score_rounded, size: 14, color: Color(0xFF0A5C5C)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: c.isDark ? Colors.white70 : const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.isDark ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

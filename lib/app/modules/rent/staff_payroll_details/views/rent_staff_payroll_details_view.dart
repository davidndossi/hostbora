import 'package:flutter/material.dart';
import 'package:host_bora/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../routes/app_pages.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_staff_payroll_details_controller.dart';

class RentStaffPayrollDetailsView extends RentBaseView<RentStaffPayrollDetailsController> {
  RentStaffPayrollDetailsView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Mishahara ya Wafanyakazi' : 'Staff payroll');

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }
      return RefreshIndicator(
        onRefresh: controller.loadPayroll,
        color: RentTheme.teal,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            rentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSw ? 'JUMLA YA MISHARA YA MWEZI' : 'TOTAL MONTHLY PAYROLL',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      color: RentTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.totalMonthlyFormatted,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: RentTheme.teal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.monthlyContractCount.value > 0
                        ? (_isSw
                            ? 'Mikataba ya mwezi: ${controller.monthlyContractCount.value} · ${controller.rows.length} wafanyakazi'
                            : 'Monthly contracts: ${controller.monthlyContractCount.value} · ${controller.rows.length} staff')
                        : (_isSw
                            ? 'Hakuna malipo ya mwezi yaliyowekwa — ona viwango vya saa/kazi hapa chini.'
                            : 'No monthly salaries set — hourly / per-job rates appear below.'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: RentTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            rentSectionLabel(_isSw ? 'Kipindi cha malipo' : 'Pay period'),
            Text(
              controller.payPeriodLabel.value,
              style: TextStyle(color: RentTheme.muted),
            ),
            const SizedBox(height: 16),
            rentSectionLabel(_isSw ? 'Wafanyakazi' : 'Staff'),
            const SizedBox(height: 8),
            if (controller.rows.isEmpty)
              rentCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        _isSw
                            ? 'Bado hakuna wafanyakazi waliosajiliwa.'
                            : 'No staff registered yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: RentTheme.muted),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Get.toNamed(Routes.RENT_STAFF_MANAGEMENT)
                            ?.then((_) => controller.loadPayroll()),
                        child: Text(
                          _isSw ? 'Fungua usimamizi wa wafanyakazi' : 'Open staff management',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              rentCard(
                child: Column(
                  children: [
                    for (var i = 0; i < controller.rows.length; i++) ...[
                      if (i > 0) const Divider(),
                      _staffRow(controller.rows[i]),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  Widget _staffRow(RentStaffPayrollUiRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: RentTheme.teal.withValues(alpha: 0.2),
            child: Text(
              row.initial,
              style: const TextStyle(
                color: RentTheme.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  row.jobTitle,
                  style: const TextStyle(color: RentTheme.muted, fontSize: 12),
                ),
                if (row.payDayNote != null && row.payDayNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    row.payDayNote!,
                    style: TextStyle(
                      color: RentTheme.muted.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.payLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

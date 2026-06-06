import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../rent/staff_payroll_details/controllers/rent_staff_payroll_details_controller.dart';

/// Inline payroll breakdown (merged from rent staff payroll details).
class ListingDetailsPayrollPanel extends StatelessWidget {
  const ListingDetailsPayrollPanel({super.key, required this.isSw});

  final bool isSw;

  String _t(String en, String sw) => isSw ? sw : en;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RentStaffPayrollDetailsController>();
    final textColor = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).hintColor;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;

    return Obx(() {
      if (c.loading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('TOTAL MONTHLY PAYROLL', 'JUMLA YA MISHARA YA MWEZI'),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.totalMonthlyFormatted,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.colorPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.monthlyContractCount.value > 0
                      ? _t(
                          'Monthly contracts: ${c.monthlyContractCount.value} · ${c.rows.length} staff',
                          'Mikataba ya mwezi: ${c.monthlyContractCount.value} · ${c.rows.length} wafanyakazi',
                        )
                      : _t(
                          'No monthly salaries set — hourly / per-job rates appear below.',
                          'Hakuna malipo ya mwezi yaliyowekwa — ona viwango vya saa/kazi hapa chini.',
                        ),
                  style: TextStyle(fontSize: 12, height: 1.35, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _t('Pay period', 'Kipindi cha malipo'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            c.payPeriodLabel.value,
            style: TextStyle(fontSize: 14, color: muted),
          ),
          const SizedBox(height: 16),
          Text(
            _t('Payroll breakdown', 'Muhtasari wa mishahara'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          if (c.rows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                _t('No staff registered yet.', 'Bado hakuna wafanyakazi waliosajiliwa.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < c.rows.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: borderColor),
                    _staffRow(c.rows[i], textColor, muted),
                  ],
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _staffRow(
    RentStaffPayrollUiRow row,
    Color textColor,
    Color muted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.colorPrimary.withValues(alpha: 0.12),
            child: Text(
              row.initial,
              style: const TextStyle(
                color: AppColors.colorPrimary,
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
                  style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
                ),
                Text(
                  row.jobTitle,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                if (row.payDayNote != null && row.payDayNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    row.payDayNote!,
                    style: TextStyle(
                      color: muted.withValues(alpha: 0.9),
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
            style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }
}

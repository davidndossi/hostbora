import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../routes/app_pages.dart';
import '../../rent_theme.dart';
import '../controllers/manage_payments_controller.dart';
import '../widgets/date_range_box.dart';

class ManagePaymentsView extends RentBaseView<ManagePaymentsController> {
  ManagePaymentsView({super.key});

  static final DateFormat _day = DateFormat('d MMM yyyy');

  @override
  Color pageBackgroundColor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8F7F4);
  }

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.managePaymentsTitle,
      showLanguageToggle: false,
      showThemeToggle: false,
      actions: [
        IconButton(
          tooltip: _isSw ? 'Ratiba ya mwaka' : 'Year schedule',
          onPressed: () => Get.toNamed(Routes.RENT_EXPECTED_PAYMENT_SCHEDULE),
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? context.tokens.cardBackground : Colors.white;
    final titleColor = isDark ? Colors.white : RentTheme.navy;
    final muted = isDark ? const Color(0xFFAEAEB2) : RentTheme.muted;

    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }
      return RefreshIndicator(
        onRefresh: controller.refreshRows,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (controller.isFutureMonth)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  appLocalization.managePaymentsExpectedHint,
                  style: TextStyle(fontSize: 13, height: 1.35, color: muted),
                ),
              ),
            _monthRow(context, muted),
            const SizedBox(height: 12),
            _totalCard(context, card, titleColor),
            const SizedBox(height: 12),
            _filtersCard(context, card, titleColor, muted, isDark),
            const SizedBox(height: 16),
            if (controller.rows.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    appLocalization.managePaymentsNoRows,
                    style: TextStyle(color: muted, fontSize: 15),
                  ),
                ),
              )
            else
              ...controller.rows.map((r) => _paymentTile(context, r, card, titleColor, muted)),
          ],
        ),
      );
    });
  }

  Widget _monthRow(BuildContext context, Color muted) {
    return Row(
      children: [
        Expanded(
          child: Text(
            appLocalization.managePaymentsMonth,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: controller.selectedMonthIndex.value.clamp(
                  0,
                  controller.monthChoices.length - 1,
                ),
                items: [
                  for (var i = 0; i < controller.monthChoices.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        ManagePaymentsController.monthFormat.format(controller.monthChoices[i]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: controller.setMonthIndex,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _totalCard(BuildContext context, Color card, Color titleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalization.managePaymentsTotal,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 6),
          Text(
            controller.totalLabel,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: titleColor),
          ),
        ],
      ),
    );
  }

  Widget _filtersCard(
    BuildContext context,
    Color card,
    Color titleColor,
    Color muted,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalization.managePaymentsFilters,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: muted),
          ),
          const SizedBox(height: 10),
          Text(appLocalization.managePaymentsApartment, style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: controller.apartmentKeys.contains(controller.selectedApartmentKey.value)
                    ? controller.selectedApartmentKey.value
                    : '',
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(appLocalization.managePaymentsAllApartments, overflow: TextOverflow.ellipsis),
                  ),
                  ...controller.apartmentKeys
                      .where((k) => k.isNotEmpty)
                      .map(
                        (k) => DropdownMenuItem(
                          value: k,
                          child: Text(k, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                ],
                onChanged: controller.setApartmentFilter,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(appLocalization.managePaymentsStatus, style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ManagePaymentStatusFilter>(
                isExpanded: true,
                value: controller.statusFilter.value,
                items: [
                  DropdownMenuItem(
                    value: ManagePaymentStatusFilter.all,
                    child: Text(appLocalization.managePaymentsStatusAll),
                  ),
                  DropdownMenuItem(
                    value: ManagePaymentStatusFilter.full,
                    child: Text(appLocalization.managePaymentsStatusFull),
                  ),
                  DropdownMenuItem(
                    value: ManagePaymentStatusFilter.partial,
                    child: Text(appLocalization.managePaymentsStatusPartial),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) controller.setStatusFilter(v);
                },
              ),
            ),
          ),
          if (!controller.isFutureMonth) ...[
            const SizedBox(height: 12),
            Text(
              '${appLocalization.managePaymentsStartDate} / ${appLocalization.managePaymentsEndDate}',
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 6),
            // Wrap(
            //   spacing: 8,
            //   runSpacing: 8,
            //   children: [
            //     OutlinedButton(
            //       onPressed: controller.pickFilterStart,
            //       child: Text(
            //         controller.filterStart.value != null
            //             ? _day.format(controller.filterStart.value!)
            //             : appLocalization.managePaymentsStartDate,
            //       ),
            //     ),
            //     OutlinedButton(
            //       onPressed: controller.pickFilterEnd,
            //       child: Text(
            //         controller.filterEnd.value != null
            //             ? _day.format(controller.filterEnd.value!)
            //             : appLocalization.managePaymentsEndDate,
            //       ),
            //     ),
            //     TextButton(
            //       onPressed: controller.clearDateFilters,
            //       child: Text(appLocalization.managePaymentsClearDates),
            //     ),
            //   ],
            // ),
            DateRangeBox(
              startDate: controller.filterStart.value != null
                  ? _day.format(controller.filterStart.value!)
                  : '',
              endDate: controller.filterEnd.value != null
                  ? _day.format(controller.filterEnd.value!)
                  : '',
              onStartTap: () {
                // show start date picker
                controller.pickFilterStart();
              },
              onEndTap: () {
                // show end date picker
                controller.pickFilterEnd();
              },
            )
          ],
        ],
      ),
    );
  }

  Widget _paymentTile(
    BuildContext context,
    ManagePaymentsRowUi r,
    Color card,
    Color titleColor,
    Color muted,
  ) {
    final amountLabel =
        Get.find<CurrencyService>().formatBase(r.amountTsh.round());
    final statusText = r.isExpected
        ? appLocalization.managePaymentsScheduled
        : !r.hasRentComparableStatus
            ? appLocalization.managePaymentsUnknownStatus
            : r.isFullPayment
                ? appLocalization.managePaymentsStatusFull
                : appLocalization.managePaymentsStatusPartial;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: card,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.tenantName.isEmpty ? '—' : r.tenantName,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: titleColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.apartmentLine.isEmpty ? '—' : r.apartmentLine,
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(amountLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: titleColor)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: RentTheme.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: RentTheme.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!r.isExpected) ...[
                const SizedBox(height: 8),
                Text(
                  r.paidDate != null
                      ? '${appLocalization.date}: ${_day.format(r.paidDate!)}'
                      : '${appLocalization.date}: —',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                if (r.categoryLabel.isNotEmpty)
                  Text(
                    '${appLocalization.managePaymentsCategory}: ${r.categoryLabel}',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

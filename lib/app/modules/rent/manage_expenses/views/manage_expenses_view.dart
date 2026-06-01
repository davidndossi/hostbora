import 'package:flutter/material.dart';
import 'package:host_bora/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widget/app_skeleton.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../core/models/item_sync_status.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../core/widget/app_interactive_card.dart';
import '../../../../core/widget/expense_row_quick_actions_sheet.dart';
import '../../../../core/widget/sync_status_chip.dart';
import '../../manage_payments/widgets/date_range_box.dart';
import '../../rent_theme.dart';
import '../controllers/manage_expenses_controller.dart';

class ManageExpensesView extends RentBaseView<ManageExpensesController> {
  ManageExpensesView({super.key});

  static final DateFormat _day = DateFormat('d MMM yyyy');

  @override
  Color pageBackgroundColor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8F7F4);
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.manageExpensesTitle,
      showLanguageToggle: false,
      showThemeToggle: false,
    );
  }

  @override
  Widget body(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = tokens.cardBackground;
    final titleColor = isDark ? tokens.textPrimary : RentTheme.navy;
    final muted = isDark ? tokens.textSecondary : RentTheme.muted;

    return Obx(() {
      if (controller.loading.value) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const AppSkeleton(width: double.infinity, height: 44, borderRadius: 8),
            const SizedBox(height: 12),
            const AppSkeleton(width: double.infinity, height: 72, borderRadius: 12),
            const SizedBox(height: 16),
            for (var i = 0; i < 5; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 120, height: 14, borderRadius: 4),
                    SizedBox(height: 8),
                    AppSkeleton(width: 180, height: 12, borderRadius: 4),
                    SizedBox(height: 8),
                    AppSkeleton(width: 80, height: 16, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ],
        );
      }
      return RefreshIndicator(
        onRefresh: controller.refreshRows,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
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
                    appLocalization.manageExpensesNoRows,
                    style: TextStyle(color: muted, fontSize: 15),
                  ),
                ),
              )
            else
              ...controller.rows.map((r) => _expenseTile(context, r, card, titleColor, muted)),
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
                        ManageExpensesController.monthFormat.format(controller.monthChoices[i]),
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
          Text(appLocalization.manageExpensesCategoryFilter, style: TextStyle(fontSize: 12, color: muted)),
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
                value: controller.categoryKeys.contains(controller.selectedCategoryKey.value)
                    ? controller.selectedCategoryKey.value
                    : '',
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(appLocalization.manageExpensesAllCategories, overflow: TextOverflow.ellipsis),
                  ),
                  ...controller.categoryKeys
                      .where((k) => k.isNotEmpty)
                      .map(
                        (k) => DropdownMenuItem(
                          value: k,
                          child: Text(k, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                ],
                onChanged: controller.setCategoryFilter,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${appLocalization.managePaymentsStartDate} / ${appLocalization.managePaymentsEndDate}',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 6),
          DateRangeBox(
            startDate: controller.filterStart.value != null
                ? _day.format(controller.filterStart.value!)
                : '',
            endDate: controller.filterEnd.value != null
                ? _day.format(controller.filterEnd.value!)
                : '',
            onStartTap: controller.pickFilterStart,
            onEndTap: controller.pickFilterEnd,
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(
    BuildContext context,
    ManageExpensesRowUi r,
    Color card,
    Color titleColor,
    Color muted,
  ) {
    final amountLabel =
        Get.find<CurrencyService>().formatBase(r.amountTsh.round());
    final title = r.tenantName.isNotEmpty
        ? r.tenantName
        : (r.categoryLabel.isNotEmpty ? r.categoryLabel : '—');

    final isSw = Get.locale?.languageCode == 'sw';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppInteractiveCard(
        color: card,
        borderRadius: 16,
        dismissKey: ValueKey('expense_row_${r.localExpenseId}'),
        onLongPress: () => showExpenseRowQuickActionsSheet(
          context: context,
          row: r,
          onRetrySync: r.syncStatus == ItemSyncStatus.failed
              ? () => controller.retryExpenseSync(r)
              : () {},
        ),
        onSwipeEndToStart: r.syncStatus == ItemSyncStatus.failed
            ? () async => controller.retryExpenseSync(r)
            : null,
        swipeEndLabel: isSw ? 'Sawazisha' : 'Retry sync',
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
                          title,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: titleColor),
                        ),
                        if (r.apartmentLine.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            r.apartmentLine,
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (r.showSyncBadge) ...[
                        SyncStatusChip(
                          status: r.syncStatus,
                          onRetry: r.syncStatus == ItemSyncStatus.failed
                              ? () => controller.retryExpenseSync(r)
                              : null,
                          compact: true,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        amountLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${appLocalization.date}: ${_day.format(r.paidDate)}',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              if (r.categoryLabel.isNotEmpty && r.tenantName.isNotEmpty)
                Text(
                  '${appLocalization.managePaymentsCategory}: ${r.categoryLabel}',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              if (r.notes.isNotEmpty)
                Text(
                  r.notes,
                  style: TextStyle(fontSize: 12, color: muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

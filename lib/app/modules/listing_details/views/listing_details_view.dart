import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/loading_button.dart';
import '../../../core/widget/property_financial_trend_charts.dart';
import '../../../core/widget/property_listing_image.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../data/local/service/currency_service.dart';
import '../controllers/listing_details_controller.dart';
import '../models/listing_activity_vm.dart';
import '../models/listing_details_tab.dart';
import '../widgets/listing_details_payroll_panel.dart';
import '../widgets/listing_details_staff_panel.dart';

class ListingDetailsView extends BaseView<ListingDetailsController> {
  ListingDetailsView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: controller.listingTitle.value.isEmpty
        ? (_isSw ? 'Maelezo ya Mali' : 'Listing Details')
        : controller.listingTitle.value,
    isCentered: true,
  );

  @override
  Color pageBackgroundColor(BuildContext context) {
    return FormSurfaceColors.of(context).scaffold;
  }

  @override
  Widget body(BuildContext context) {
    final u = FormSurfaceColors.of(context);
    return Obx(() {
      if (controller.loadingListing.value) {
        return const Center(child: DefaultScreenSkeleton());
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tabBar(u),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  controller.loadListingDetail(),
                  controller.loadRealDataSnapshot(),
                ]);
              },
              child: _tabBody(context, u),
            ),
          ),
        ],
      );
    });
  }

  Widget _tabBar(FormSurfaceColors u) {
    return Obx(() {
      final tabs = controller.visibleTabs;
      final selected = controller.selectedTab.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: tabs.map((tab) {
                final isSelected = tab == selected;
                final label = _isSw ? tab.labelSw() : tab.labelEn();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => controller.selectTab(tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.colorPrimary
                            : u.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.colorPrimary
                              : u.border,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.colorPrimary
                                      .withValues(alpha: 0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : u.secondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, thickness: 1, color: u.border),
        ],
      );
    });
  }

  Widget _tabBody(BuildContext context, FormSurfaceColors u) {
    return Obx(() {
      switch (controller.selectedTab.value) {
        case ListingDetailsTab.overview:
          return _overviewTab(context, u);
        case ListingDetailsTab.bnb:
          return _workspaceUnitsTab(u, workspace: 'bnb');
        case ListingDetailsTab.rent:
          return _workspaceUnitsTab(u, workspace: 'rent');
        case ListingDetailsTab.finance:
          return _financeTab(u);
        case ListingDetailsTab.staff:
          return _staffTab(u);
        case ListingDetailsTab.maintenance:
          return _maintenanceTab(u);
      }
    });
  }

  Widget _overviewTab(BuildContext context, FormSurfaceColors u) {
    final currencyCode = Get.find<CurrencyService>().baseCurrency.value;
    return ListView(
      controller: controller.listingScrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _hero(u),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _kpiOccupancy(
                u,
                percent: controller.occupancyPercent.value.clamp(0, 100).toDouble(),
                onTap: controller.onOpenUnitOccupancy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _kpiMinimal(
                    u,
                    label: _isSw ? 'Jumla ya Mapato' : 'Total income',
                    value: controller.totalIncomeLabel.value,
                    prefix: currencyCode,
                    onTap: controller.onShowIncomeBreakdown,
                  ),
                  const SizedBox(height: 12),
                  _kpiMinimal(
                    u,
                    label: _isSw
                        ? 'Mapato yanayotarajiwa (kwa mwezi)'
                        : 'Expected income (monthly)',
                    value: controller.expectedIncomeLabel.value,
                    prefix: currencyCode,
                  ),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiMinimal(
                u,
                label: _isSw ? 'Jumla ya Matumizi' : 'Total expenses',
                value: controller.totalExpensesLabel.value,
                prefix: currencyCode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiMinimal(
                u,
                label: _isSw ? 'Faida halisi' : 'Net income',
                value: controller.netIncomeLabel.value,
                prefix: currencyCode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _propertyRoiAnalysisLink(u),
        if (controller.propertyWorkspaceMode.value == 'rent' ||
            controller.propertyWorkspaceMode.value == 'both') ...[
          const SizedBox(height: 10),
          _tenancyInsightsLink(u),
          const SizedBox(height: 10),
          _tenantChargesLink(u),
          const SizedBox(height: 10),
          _apartmentReportsLink(u),
        ],
        const SizedBox(height: 10),
        _estimationCostsLink(u),
        const SizedBox(height: 12),
        _inventoryTrackingLink(u),
        const SizedBox(height: 20),
        _quickManagement(u),
        const SizedBox(height: 16),
        _calendarSyncEntry(context, u),
        const SizedBox(height: 16),
        _paymentFollowUpBanner(u),
        const SizedBox(height: 16),
        _activity(u),
        const SizedBox(height: 20),
        _removeButton(),
      ],
    );
  }

  Widget _financeTab(FormSurfaceColors u) {
    return ListView(
      controller: controller.listingScrollController,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        Text(
          _isSw ? 'Mwelekeo wa Fedha' : 'Financial Trends',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: u.headline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isSw
              ? 'Geuza mwonekano kwa kutumia kichaguo'
              : 'Switch view using the dropdown on the chart',
          style: TextStyle(fontSize: 12.5, color: u.secondary),
        ),
        const SizedBox(height: 14),
        Obx(
          () => PropertyFinancialTrendCharts(
            series: controller.financialTrends.value,
            loading: controller.financialTrendsLoading.value,
          ),
        ),
      ],
    );
  }

  Widget _staffTab(FormSurfaceColors u) {
    return ListView(
      controller: controller.listingScrollController,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSw ? 'Wafanyakazi Waliopangiwa' : 'Staff Assigned',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: u.headline,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.onAddStaff,
              child: Text(
                _isSw ? 'Ongeza mfanyakazi' : 'Add staff',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListingDetailsPayrollPanel(isSw: _isSw),
        const SizedBox(height: 20),
        ListingDetailsStaffPanel(
          isSw: _isSw,
          compactListOnly: false,
          showPayrollSummary: false,
          onStaffChanged: controller.refreshStaffPanel,
        ),
      ],
    );
  }

  static const _btnShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );

  Widget _maintenanceTab(FormSurfaceColors u) {
    return ListView(
      controller: controller.listingScrollController,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        Text(
          _isSw ? 'Matengenezo' : 'Maintenance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: u.headline,
          ),
        ),
        const SizedBox(height: 14),

        // ── Assignment card ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: u.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: u.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSw ? 'Mkabidhi kwa mfanyakazi' : 'Assign to staff',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: u.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                final options = controller.assigneeStaffOptions;
                final selected = controller.selectedAssigneeStaffId.value;
                return DropdownButtonFormField<String>(
                  initialValue: selected != null &&
                          options.any((s) => s.id.toString() == selected)
                      ? selected
                      : null,
                  decoration: InputDecoration(
                    hintText:
                        _isSw ? 'Chagua mfanyakazi' : 'Select staff member',
                    filled: true,
                    fillColor: u.fill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: u.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: u.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.colorPrimary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                  items: options
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id.toString(),
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: controller.updateAssigneeStaff,
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Action buttons ───────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: controller.onScheduleMaintenance,
                  style: OutlinedButton.styleFrom(
                    shape: _btnShape,
                    side: BorderSide(color: u.border, width: 1.5),
                    foregroundColor: u.headline,
                    padding: EdgeInsets.zero,
                  ),
                  icon: Icon(
                    Icons.calendar_today_outlined,
                    size: 17,
                    color: u.secondary,
                  ),
                  label: Text(
                    _isSw ? 'Panga matengenezo' : 'Schedule',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: controller.onAddMaintenanceTask,
                  style: FilledButton.styleFrom(
                    shape: _btnShape,
                    backgroundColor: AppColors.colorPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.add_task_outlined, size: 17),
                  label: Text(
                    _isSw ? 'Ongeza kazi' : 'Add task',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ── Scheduled maintenance list ────────────────────────────────────
        Obx(() {
          final rows = controller.maintenanceRows;
          if (rows.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: u.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: u.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: u.secondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isSw
                        ? 'Hakuna matengenezo yaliyopangwa.'
                        : 'No scheduled maintenance yet.',
                    style: TextStyle(fontSize: 14, color: u.secondary),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: rows.map((r) => _maintenanceCard(u, r)).toList(),
          );
        }),

        const SizedBox(height: 24)
      ],
    );
  }

  Color _priorityBadgeBg(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'high':
        return const Color(0xFFFEE2E2);
      case 'medium':
      case 'normal':
        return const Color(0xFFFEF9C3);
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  Color _priorityBadgeFg(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'high':
        return const Color(0xFFB91C1C);
      case 'medium':
      case 'normal':
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF15803D);
    }
  }

  Widget _maintenanceCard(FormSurfaceColors u, ListingMaintenanceRowVm row) {
    final badgeBg = _priorityBadgeBg(row.priority);
    final badgeFg = _priorityBadgeFg(row.priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: u.headline,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  row.priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          if (row.description.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              row.description,
              style: TextStyle(fontSize: 13, color: u.secondary, height: 1.35),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 13, color: u.secondary),
              const SizedBox(width: 5),
              Text(
                row.scheduledLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: u.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workspaceUnitsTab(FormSurfaceColors u, {required String workspace}) {
    return ListView(
      controller: controller.listingScrollController,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      children: [
        if (workspace == 'rent') ...[
          _tenancyInsightsLink(u),
          const SizedBox(height: 10),
          _apartmentReportsLink(u),
          const SizedBox(height: 12),
        ],
        _units(u, workspace: workspace),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppValues.largePadding),
          child: Obx(
            () => LoadingButton(
              label: _isSw ? 'Ongeza unit mpya' : 'Add new unit',
              icon: Icons.add_circle_outline,
              onPressed: () => controller.onAddNewUnit(workspace),
              isLoading: controller.isBusy.value,
            ),
          ),
        )
      ],
    );
  }

  Widget _paymentFollowUpBanner(FormSurfaceColors u) {
    return Obx(() {
      final banner = controller.paymentFollowUp.value;
      if (banner == null) return const SizedBox.shrink();
      return Material(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: controller.onPaymentFollowUpTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.warning_amber_outlined,
                    color: Color(0xFFD97706),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    banner.message,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ),
                if (banner.actionLabel != null) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.actionLabel!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right_outlined,
                    size: 16,
                    color: Color(0xFFD97706),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _hero(FormSurfaceColors u) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 186,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Obx(
              () => PropertyListingImage(
                imagePath: controller.heroImagePath.value,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(
                    () => Text(
                      controller.heroOverlayTitle.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: controller.onEditListing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isSw ? 'Hariri listing' : 'Edit listing',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _estimationCostsLink(FormSurfaceColors u) {
  //   return Material(
  //     color: u.card,
  //     borderRadius: BorderRadius.circular(14),
  //     child: InkWell(
  //       onTap: controller.onAddPropertyEstimationCosts,
  //       borderRadius: BorderRadius.circular(14),
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(14),
  //           border: Border.all(color: u.border),
  //         ),
  //         child: Row(
  //           children: [
  //             Icon(Icons.calculate_outlined, color: AppColors.colorPrimary, size: 22),
  //             const SizedBox(width: 10),
  //             Expanded(
  //               child: Text(
  //                 _isSw ? 'Ongeza makadirio ya gharama za mali' : 'Add Property Estimation Costs',
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w700,
  //                   color: AppColors.colorPrimary,
  //                 ),
  //               ),
  //             ),
  //             Icon(Icons.chevron_right_outlined, color: u.secondary, size: 22),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _inventoryTrackingLink(FormSurfaceColors u) {
    return Material(
      color: u.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: controller.onOpenInventoryTracking,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.colorPrimary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.colorPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSw ? 'Ufuatiliaji wa vifaa' : 'Inventory tracking',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: u.headline,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isSw
                          ? 'Fuatilia vifaa, bidhaa na mabadiliko kwa kila unit'
                          : 'Track items, stock levels and changes per unit',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: u.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: u.border.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_outlined,
                  color: AppColors.colorPrimary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estimationCostsLink(FormSurfaceColors u) {
    return _detailNavLink(
      u,
      icon: Icons.calculate_outlined,
      title: _isSw ? 'Makadirio ya gharama' : 'Property Estimation Costs',
      subtitle: _isSw
          ? 'Ongeza gharama za ujenzi, matengenezo au huduma'
          : 'Add construction, maintenance or service costs',
      onTap: controller.onAddPropertyEstimationCosts,
    );
  }

  Widget _propertyRoiAnalysisLink(FormSurfaceColors u) {
    return _detailNavLink(
      u,
      icon: Icons.trending_up_outlined,
      title: _isSw ? 'Uchambuzi wa ROI' : 'Property ROI Analysis',
      subtitle: _isSw
          ? 'Linganisha mtaji, mapato na umiliki'
          : 'Compare principal cost, income and break-even',
      onTap: controller.onOpenPropertyRoiAnalysis,
    );
  }

  Widget _tenancyInsightsLink(FormSurfaceColors u) {
    return _detailNavLink(
      u,
      icon: Icons.groups_outlined,
      title: _isSw ? 'Wapangaji' : 'Tenants',
      subtitle: _isSw
          ? 'Wapangaji, malipo, Excel na chati'
          : 'Tenants, payments, Excel exports and charts',
      onTap: controller.onOpenTenancyInsights,
    );
  }

  Widget _tenantChargesLink(FormSurfaceColors u) {
    return _detailNavLink(
      u,
      icon: Icons.payments_outlined,
      title: _isSw ? 'Bainisha tozo za mpangaji' : 'Define tenant charges',
      subtitle: _isSw
          ? 'Depositi, tozo ya huduma, na ada nyingine'
          : 'Deposits, service charges, and other fees',
      onTap: controller.onOpenTenantCharges,
    );
  }

  Widget _apartmentReportsLink(FormSurfaceColors u) {
    return _detailNavLink(
      u,
      icon: Icons.picture_as_pdf_outlined,
      title: _isSw ? 'Ripoti za vyumba (PDF)' : 'Apartment reports (PDF)',
      subtitle: _isSw
          ? 'Ripoti ya kodi na tozo ya huduma kwa kila chumba'
          : 'Rent and service charge PDF per apartment',
      onTap: controller.onOpenApartmentReports,
    );
  }

  Widget _detailNavLink(
    FormSurfaceColors u, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: u.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.colorPrimary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.colorPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: u.headline,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: u.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: u.border.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_outlined,
                  color: AppColors.colorPrimary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Occupancy KPI card with a circular ring instead of a progress bar.
  Widget _kpiOccupancy(
    FormSurfaceColors u, {
    required double percent,
    VoidCallback? onTap,
  }) {
    final label = _isSw ? 'Ukaaji wa sasa' : 'Current occupancy';
    final ringColor = percent >= 75
        ? const Color(0xFF16A34A)
        : percent >= 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final inner = Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: u.secondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_outlined, size: 16, color: u.secondary),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(
                painter: _OccupancyRingPainter(
                  progress: (percent / 100).clamp(0.0, 1.0),
                  ringColor: ringColor,
                  trackColor: u.border,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${percent.round()}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: u.headline,
                          height: 1,
                        ),
                      ),
                      Text(
                        '%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: u.secondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );

    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: inner,
      ),
    );
  }

  Widget _kpiMinimal(
    FormSurfaceColors u, {
    required String label,
    required String value,
    String prefix = '',
    String suffix = '',
    double? progress,
    VoidCallback? onTap,
  }) {
    final valueColor = u.isDark
        ? const Color(0xFFF2F2F7)
        : AppColors.colorPrimary;
    final inner = Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: u.secondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_outlined,
                  size: 16,
                  color: u.secondary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    if (prefix.isNotEmpty)
                      TextSpan(
                        text: '$prefix ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: u.secondary,
                          height: 1,
                        ),
                      ),
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        color: valueColor,
                      ),
                    ),
                    if (suffix.isNotEmpty)
                      TextSpan(
                        text: suffix,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          color: u.headline,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: u.border,
                color: AppColors.colorPrimaryDark,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: inner,
      ),
    );
  }

  Widget _calendarSyncEntry(BuildContext context, FormSurfaceColors u) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: u.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: controller.onOpenCalendarSync,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: u.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sync_outlined,
                  color: AppColors.colorPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.calendarSyncOpenFromListing,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: u.headline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.calendarSyncOpenFromListingHint,
                      style: TextStyle(fontSize: 12, color: u.secondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_outlined, color: u.secondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickManagement(FormSurfaceColors u) {
    final mode = controller.propertyWorkspaceMode.value;
    final showRentTools = mode == 'rent' || mode == 'both';
    final items = <(IconData, String, int)>[
      (
        Icons.person_add_alt_1_outlined,
        _isSw ? 'Ongeza mpangaji' : 'Add tenant',
        0,
      ),
      (Icons.payments_outlined, _isSw ? 'Ongeza mapato' : 'Add income', 1),
      (
        Icons.receipt_long_outlined,
        _isSw ? 'Ongeza matumizi' : 'Add expense',
        2,
      ),
      (
        Icons.calendar_today_outlined,
        _isSw ? 'Panga\nmatengenezo' : 'Schedule\nmaintenance',
        3,
      ),
      (
        Icons.lock_open,
        _isSw ? 'Dhibiti kufuli\nya unit' : 'Unit lock\ncontrol',
        4,
      ),
      (
        Icons.bolt_outlined,
        _isSw ? 'Dashibodi ya\nHuduma' : 'Utility\nDashboard',
        5,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Usimamizi wa Haraka' : 'Quick Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: u.headline,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final item = items[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.onQuickAction(item.$3),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: u.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: u.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.colorPrimary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.$1,
                          size: 22,
                          color: AppColors.colorPrimary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .25,
                          color: u.headline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _units(FormSurfaceColors u, {required String workspace}) {
    final isBnb = workspace == 'bnb';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isBnb
                    ? (_isSw ? 'Uniti za BnB' : 'BnB Units')
                    : (_isSw ? 'Uniti za Kodi' : 'Rent Units'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: u.headline,
                ),
              ),
            ),
            // TextButton(
            //   onPressed: () => controller.onAddNewUnit(workspace),
            //   child: Text(
            //     _isSw ? 'Ongeza unit mpya' : 'Add new unit',
            //     style: const TextStyle(
            //       fontSize: 12,
            //       fontWeight: FontWeight.w800,
            //     ),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 4),
        Obx(() {
          final rows = isBnb ? controller.bnbUnitRows : controller.rentUnitRows;
          if (rows.isEmpty) {
            return Text(
              _isSw ? 'Hakuna units.' : 'No units listed.',
              style: TextStyle(fontSize: 12, color: u.secondary),
            );
          }
          final allOccupied = rows.isNotEmpty &&
              rows.every((row) => row.status == ListingUnitStatus.occupied);
          return Column(
            children: rows
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _unitCard(
                      u,
                      r,
                      workspace: workspace,
                      replaceTenant: allOccupied,
                    ),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _unitCard(
    FormSurfaceColors u,
    ListingUnitRowVm row, {
    required String workspace,
    bool replaceTenant = false,
  }) {
    final due = row.status == ListingUnitStatus.dueDate;
    final occupied = row.status == ListingUnitStatus.occupied;
    final hasAttachedTenant = row.tenantName.trim().isNotEmpty;

    final badgeBg = due
        ? const Color(0xFFFEEAEA)
        : occupied
        ? const Color(0xFFEAF6EC)
        : const Color(0xFFF2F2F2);
    final badgeFg = due
        ? const Color(0xFFB42318)
        : occupied
        ? const Color(0xFF1B6B3A)
        : const Color(0xFF6B7280);
    final badgeText = due
        ? 'Due date'
        : occupied
        ? 'Occupied'
        : 'Short';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: due ? const Color(0xFFFCA5A5) : u.border,
          width: due ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: u.headline,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: .4,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: _isSw ? 'Hariri unit' : 'Edit unit',
                onPressed: () => controller.onEditUnitDetails(row),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: u.secondary,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              IconButton(
                tooltip: _isSw ? 'Futa unit' : 'Delete unit',
                onPressed: () => controller.onDeleteUnit(row),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Color(0xFFB42318),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            row.subtitle,
            style: TextStyle(fontSize: 13, color: u.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 9),
          if (hasAttachedTenant) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB7E1C0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outlined,
                    size: 16,
                    color: Color(0xFF1B6B3A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.tenantName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B6B3A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (replaceTenant) const SizedBox(height: 8),
          ],
          if (!hasAttachedTenant || replaceTenant)
            SizedBox(
              height: 40,
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () =>
                    controller.onUnitPrimaryActionForWorkspace(row, workspace),
                style: FilledButton.styleFrom(
                  backgroundColor: due
                      ? const Color(0xFFFFF3F2)
                      : occupied
                      ? AppColors.colorPrimary
                      : u.fill,
                  foregroundColor: due
                      ? const Color(0xFFB42318)
                      : occupied
                      ? Colors.white
                      : AppColors.colorPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  controller.primaryButtonLabel(row, _isSw),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _activity(FormSurfaceColors u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSw ? 'Shughuli za Karibuni' : 'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: u.headline,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showAllActivityLogs(u.context, u),
              child: const Text(
                'View all log',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Obx(() {
          final rows = controller.recentActivity;
          if (rows.isEmpty) {
            return Text(
              'No recent activity',
              style: TextStyle(fontSize: 13, color: u.secondary),
            );
          }
          return Column(
            children: rows
                .take(3)
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: a.accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: a.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: u.headline,
                                ),
                              ),
                              Text(
                                a.subtitle,
                                style: TextStyle(fontSize: 12.5, color: u.secondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              a.trailing,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: u.headline,
                              ),
                            ),
                            Text(
                              a.timeLabel,
                              style: TextStyle(fontSize: 11.5, color: u.secondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  void _showAllActivityLogs(BuildContext context, FormSurfaceColors u) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: u.card,
      builder: (context) {
        final sheetHeight = MediaQuery.sizeOf(context).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: sheetHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                  child: Text(
                    _isSw ? 'Kumbukumbu zote' : 'All Activity Logs',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: u.headline,
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final rows = controller.recentActivity;
                    if (rows.isEmpty) {
                      return Center(
                        child: Text(
                          _isSw ? 'Hakuna shughuli.' : 'No activity logs',
                          style: TextStyle(fontSize: 14, color: u.secondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _activityLogTile(u, rows[index]),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _activityLogTile(FormSurfaceColors u, ListingActivityVm activity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: u.fill.withValues(alpha: u.isDark ? 0.35 : 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: activity.accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: activity.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: u.headline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: TextStyle(fontSize: 13, color: u.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.trailing,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: u.headline,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activity.canEdit)
                    _activityActionLink(
                      label: _isSw ? 'Hariri' : 'Edit',
                      color: Theme.of(u.context).colorScheme.primary,
                      onTap: () async {
                        Navigator.of(u.context).maybePop();
                        await controller.onEditActivity(activity);
                      },
                    ),
                  if (activity.canEdit && activity.canDelete)
                    Text(
                      ' • ',
                      style: TextStyle(fontSize: 12, color: u.secondary),
                    ),
                  if (activity.canDelete)
                    _activityActionLink(
                      label: _isSw ? 'Futa' : 'Delete',
                      color: const Color(0xFFEF4444),
                      onTap: () async {
                        Navigator.of(u.context).maybePop();
                        await controller.onDeleteActivity(activity);
                      },
                    ),
                  if (activity.canEdit || activity.canDelete)
                    Text(
                      ' • ',
                      style: TextStyle(fontSize: 12, color: u.secondary),
                    ),
                  Text(
                    activity.timeLabel,
                    style: TextStyle(fontSize: 12, color: u.secondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityActionLink({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _removeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: controller.onDeleteProperty,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB91C1C),
          side: const BorderSide(color: Color(0xFFB91C1C), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(AppValues.padding),
        ),
        icon: const Icon(Icons.delete_outline),
        label: Text(
          _isSw ? 'Futa mjengo' : 'Remove property',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// ─── Ring painter for the occupancy KPI card ─────────────────────────────────

class _OccupancyRingPainter extends CustomPainter {
  const _OccupancyRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;

  static const double _strokeWidth = 9.0;
  static const double _startAngle = -math.pi / 2; // 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - _strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    // Full track.
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc.
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_OccupancyRingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor;
}

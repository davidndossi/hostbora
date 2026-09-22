import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/access/staff_access.dart';
import '../../inventory_tracking/views/inventory_low_stock_banner.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/widget/hub_insight_banner.dart';
import '../../../core/widget/managing_for_banner.dart';
import '../../../core/widget/property_listing_image.dart';
import '/app/core/base/base_view.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../core/widget/sync_status_chip.dart';
import '../../../core/models/item_sync_status.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/model/check_in_item.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/home_controller.dart';
import 'home_guest_quick_actions_sheet.dart';

// ignore: must_be_immutable
class HomeView extends BaseView<HomeController> {
  HomeView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.home,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        if (controller.homeInitialLoading.value) {
          return const HomeScreenSkeleton();
        }
        if (!controller.hasAnyProperty.value) {
          return RefreshIndicator(
            onRefresh: () => controller.loadHomeData(refresh: true),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: _buildEmptyHomeState(context),
                ),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadHomeData(refresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() {
              final firstWeek = controller.isFirstWeekHome;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ManagingForBanner(),
                  const SizedBox(height: 8),
                  if (controller.showWorkspaceFilterChips) ...[
                    _buildWorkspaceFilter(context),
                    const SizedBox(height: 16),
                  ],
                  _buildTodayBlock(context),
                  const SizedBox(height: 20),
                  if (firstWeek) ...[
                    _buildFirstWeekStarter(context),
                    const SizedBox(height: 20),
                    _buildCreateCta(context),
                    const SizedBox(height: 100),
                  ] else ...[
                    _buildSnapshotBlock(context),
                    const SizedBox(height: 16),
                    _buildRecentPaymentsBlock(context),
                    const SizedBox(height: 12),
                    const HubInsightBanner(compact: true, dismissible: true),
                    const SizedBox(height: 8),
                    if (_staffCanCreate()) _buildCreateCta(context),
                    const SizedBox(height: 20),
                    _buildGoToBlock(context),
                    const SizedBox(height: 100),
                  ],
                  const SizedBox(height: 28),
                ],
              );
            }),
          ),
        );
      }),
    );
  }

  /// Prominent Create entry (AI stays on the FAB so they don't compete).
  Widget _buildCreateCta(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: controller.openCreateMenu,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.colorPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _t(context, 'Create', 'Unda'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// First-week: three clear next steps only.
  Widget _buildFirstWeekStarter(BuildContext context) {
    final showBnb = controller.showBnbHomeContent;
    final showRent = controller.showRentHomeContent;
    final primaryLabel = showBnb && !showRent
        ? _t(context, 'Add Booking', 'Ongeza Uhifadhi')
        : showRent && !showBnb
            ? _t(context, 'Add Tenant', 'Ongeza Mpangaji')
            : _t(context, 'Add Booking or Tenant', 'Ongeza Uhifadhi au Mpangaji');
    final primaryIcon = showBnb && !showRent
        ? Icons.event_available_outlined
        : Icons.person_add_alt_1_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Get started', 'Anza'),
        const SizedBox(height: 4),
        Text(
          _t(
            context,
            'Three steps to put Host Bora to work this week.',
            'Hatua tatu kuanza kutumia Host Bora wiki hii.',
          ),
          style: TextStyle(fontSize: 12, color: context.tokens.textSecondary),
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          materialIcon: primaryIcon,
          label: primaryLabel,
          onTap: controller.openPrimaryCreateAction,
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          materialIcon: Icons.payments_outlined,
          label: _t(context, 'Record Payment', 'Rekodi Malipo'),
          onTap: controller.addPayment,
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          materialIcon: Icons.apartment_outlined,
          label: _t(context, 'Open Properties', 'Fungua Mali'),
          onTap: controller.openPropertiesTab,
        ),
      ],
    );
  }

  Widget _buildWorkspaceFilter(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    final isSw = Localizations.localeOf(context).languageCode == 'sw';

    return Obx(() {
      final selected = controller.homeWorkspaceFilter.value;

      Widget chip(String label, String value, Color color) {
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => controller.setHomeWorkspaceFilter(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? color
                    : (c.isDark
                        ? theme.colorScheme.outlineVariant
                        : const Color(0xFFDDE1E7)),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (c.isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : const Color(0xFF64748B)),
              ),
            ),
          ),
        );
      }

      return Row(
        children: [
          chip(isSw ? 'Zote' : 'All', 'all', AppColors.designAccent),
          const SizedBox(width: 8),
          chip('BnB', 'bnb', const Color(0xFF0D7377)),
          const SizedBox(width: 8),
          chip(isSw ? 'Kodi' : 'Rent', 'rent', const Color(0xFF4F46E5)),
        ],
      );
    });
  }

  Widget _sectionTitle(BuildContext context, String en, String sw) {
    return Text(
      _t(context, en, sw),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: context.tokens.textPrimary,
      ),
    );
  }

  bool _staffCanCreate() {
    return _staffAllows(StaffPermissions.editProperties) ||
        _staffAllows(StaffPermissions.manageTenants) ||
        _staffAllows(StaffPermissions.messageGuest) ||
        _staffAllows(StaffPermissions.recordPayment) ||
        _staffAllows(StaffPermissions.manageExpenses) ||
        _staffAllows(StaffPermissions.manageBookings);
  }

  bool _staffAllows(String key) {
    if (!Get.isRegistered<StaffAccessStore>()) return true;
    final access = Get.find<StaffAccessStore>();
    access.restricted.value;
    access.permissions.length;
    return access.allows(key);
  }

  /// Block 1 — what needs attention today (compact alerts, expand on tap).
  Widget _buildTodayBlock(BuildContext context) {
    return Obx(() {
      final showBnb = controller.showBnbHomeContent;
      final showRent = controller.showRentHomeContent;
      final checkIns = showBnb ? controller.checkInsToday.length : 0;
      final checkOuts = showBnb ? controller.checkOutsToday.length : 0;
      final upcoming = showBnb ? controller.checkIns.length : 0;
      final maintenance = controller.visibleUpcomingMaintenance;
      final maintenanceCount = maintenance.length;
      final accessOk = _staffAllows;
      final showBookings = accessOk(StaffPermissions.viewBookings);
      final showTasks = accessOk(StaffPermissions.viewTasks);
      final showPayments = accessOk(StaffPermissions.viewPayments);
      final collectionLow =
          showPayments &&
          showRent && controller.collectionRate.value > 0 && controller.collectionRate.value < 70;
      final hasAlerts = (showBookings && (checkIns > 0 || checkOuts > 0 || upcoming > 0)) ||
          collectionLow ||
          (showTasks && maintenanceCount > 0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Today', 'Leo'),
          const SizedBox(height: 10),
          if (!hasAlerts)
            _TodayQuietCard(
              label: _t(
                context,
                'Nothing urgent today — you\'re all clear.',
                'Hakuna cha dharura leo — mambo yako sawa.',
              ),
            )
          else ...[
            if (showBookings && checkOuts > 0)
              _TodayAlertTile(
                icon: Icons.logout_rounded,
                title: _t(context, 'Check-outs today', 'Wanatoka leo'),
                count: checkOuts,
                expanded: controller.todayExpandedKey.value == 'checkout',
                onTap: () => controller.toggleTodayDetail('checkout'),
              ),
            if (controller.todayExpandedKey.value == 'checkout' &&
                controller.checkOutsToday.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildHorizontalGuestSection(
                context,
                title: '',
                list: controller.checkOutsToday,
              ),
            ],
            if (showBookings && checkIns > 0) ...[
              const SizedBox(height: 8),
              _TodayAlertTile(
                icon: Icons.login_rounded,
                title: _t(context, 'Check-ins today', 'Wanaoingia leo'),
                count: checkIns,
                expanded: controller.todayExpandedKey.value == 'checkin',
                onTap: () => controller.toggleTodayDetail('checkin'),
              ),
            ],
            if (controller.todayExpandedKey.value == 'checkin' &&
                controller.checkInsToday.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildHorizontalGuestSection(
                context,
                title: '',
                list: controller.checkInsToday,
              ),
            ],
            if (showBookings && upcoming > 0) ...[
              const SizedBox(height: 8),
              _TodayAlertTile(
                icon: Icons.event_available_rounded,
                title: _t(context, 'Upcoming check-ins', 'Wanaoingia hivi karibuni'),
                count: upcoming,
                expanded: controller.todayExpandedKey.value == 'upcoming',
                onTap: () => controller.toggleTodayDetail('upcoming'),
              ),
            ],
            if (controller.todayExpandedKey.value == 'upcoming' &&
                controller.checkIns.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildHorizontalGuestSection(
                context,
                title: '',
                list: controller.checkIns,
                onSeeAll: controller.seeAllCheckIns,
                seeAllLabel: _t(context, 'See All', 'Ona Yote'),
              ),
            ],
            if (showTasks && maintenanceCount > 0) ...[
              const SizedBox(height: 8),
              _TodayAlertTile(
                icon: Icons.build_outlined,
                title: _t(
                  context,
                  'Maintenance this week',
                  'Matengenezo wiki hii',
                ),
                count: maintenanceCount,
                subtitle: _t(
                  context,
                  'Tap to open calendar',
                  'Gusa kufungua kalenda',
                ),
                expanded: controller.todayExpandedKey.value == 'maintenance',
                onTap: () => controller.toggleTodayDetail('maintenance'),
              ),
            ],
            if (controller.todayExpandedKey.value == 'maintenance' &&
                maintenance.isNotEmpty) ...[
              const SizedBox(height: 8),
              _UpcomingMaintenanceList(
                items: maintenance,
                onSeeAll: controller.openScheduledMaintenance,
                seeAllLabel: _t(context, 'See calendar', 'Angalia kalenda'),
              ),
            ],
            if (collectionLow) ...[
              const SizedBox(height: 8),
              _TodayAlertTile(
                icon: Icons.payments_outlined,
                title: _t(
                  context,
                  'Collection at ${controller.collectionRate.value}%',
                  'Ukusanyaji uko ${controller.collectionRate.value}%',
                ),
                count: null,
                subtitle: _t(
                  context,
                  'Tap to manage rent payments',
                  'Gusa kusimamia malipo ya kodi',
                ),
                expanded: false,
                onTap: controller.openTodayRevenue,
              ),
            ],
          ],
          const SizedBox(height: 8),
          const InventoryLowStockBanner(),
        ],
      );
    });
  }

  /// Block 2 — 3–4 key numbers for the selected workspace.
  Widget _buildSnapshotBlock(BuildContext context) {
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    return Obx(() {
      final showBnb = controller.showBnbHomeContent;
      final showRent = controller.showRentHomeContent;
      final showProperties = _staffAllows(StaffPermissions.viewProperties);
      final showBookings = _staffAllows(StaffPermissions.viewBookings);
      final showTenants = _staffAllows(StaffPermissions.viewTenants);
      final showMoney = _staffAllows(StaffPermissions.viewPayments) ||
          _staffAllows(StaffPermissions.viewReports);
      final hasCards = showBnb && showRent
          ? showProperties || showTenants || showMoney
          : showBnb
              ? showBookings || showMoney || showProperties
              : showTenants || showProperties || showMoney;
      if (!hasCards && !_staffAllows(StaffPermissions.viewReports)) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle(context, 'Summary', 'Muhtasari')),
              if (_staffAllows(StaffPermissions.viewReports))
              TextButton(
                onPressed: controller.viewTrends,
                child: Text(
                  _t(context, 'View trends', 'Angalia mwelekeo'),
                  style: TextStyle(
                    color: AppColors.colorPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (showBnb && showRent) ...[
            if (showProperties)
              Row(
                children: [
                  Expanded(
                    child: _BnbOverviewCard(
                      title: isSw ? 'Jumla ya Mali' : 'Total Properties',
                      value: '${controller.totalPropertiesCount.value}',
                      subtitle: 'BnB + Rent',
                      onTap: controller.openProperties,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BnbOverviewCard(
                      title: isSw ? 'Jumla ya Vyumba' : 'Total Units',
                      value: '${controller.totalUnitsCount.value}',
                      subtitle: 'BnB + Rent',
                      onTap: controller.openProperties,
                    ),
                  ),
                ],
              ),
            if (showProperties) const SizedBox(height: 12),
            if (showTenants || showMoney)
              Row(
                children: [
                  if (showTenants)
                    Expanded(
                      child: _BnbOverviewCard(
                        title: isSw ? 'Wapangaji' : 'Tenants',
                        value: '${controller.rentTenantsCount.value}',
                        subtitle: isSw ? 'Wanaokaa sasa' : 'Active now',
                        onTap: controller.openAllTenants,
                      ),
                    ),
                  if (showTenants && showMoney) const SizedBox(width: 12),
                  if (showMoney)
                    Expanded(
                      child: _BnbOverviewCard(
                        title: isSw ? 'Ukusanyaji' : 'Collection',
                        value: '${controller.collectionRate.value}%',
                        subtitle: isSw ? 'Mwezi huu' : 'This month',
                        onTap: controller.openTodayRevenue,
                      ),
                    ),
                ],
              ),
            if (showTenants || showMoney) const SizedBox(height: 12),
            if (showMoney)
            _MonthIncomeCard(
              title: isSw ? 'Mapato ya mwezi' : 'Income this month',
              expectedLabel: isSw ? 'Inayotarajiwa' : 'Expected',
              collectedLabel: isSw ? 'Iliyokusanywa' : 'Collected',
              expectedValue: controller.expectedIncomeLabel.value,
              collectedValue: controller.collectedIncomeLabel.value,
              onTap: controller.openTodayRevenue,
            ),
          ] else if (showBnb) ...[
            if (showBookings || showMoney)
              Row(
                children: [
                  if (showBookings)
                    Expanded(
                      child: _BnbOverviewCard(
                        title: isSw ? 'Uhifadhi Hai' : 'Active Bookings',
                        value: '${controller.activeBookings.value}',
                        subtitle: controller.bookingsChange.value,
                        onTap: controller.openBookings,
                      ),
                    ),
                  if (showBookings && showMoney) const SizedBox(width: 12),
                  if (showMoney)
                    Expanded(
                      child: _BnbOverviewCard(
                        title: isSw ? 'Mapato ya Mwezi' : 'Monthly Revenue',
                        value: controller.monthlyRevenue.value,
                        subtitle: controller.revenueChange.value,
                        onTap: controller.viewTrends,
                      ),
                    ),
                ],
              ),
            if (showProperties) const SizedBox(height: 12),
            if (showProperties)
              Row(
                children: [
                  Expanded(
                    child: _BnbOverviewCard(
                      title: isSw ? 'Ukaaji wa BnB' : 'BnB Occupancy',
                      value: '${controller.bnbOccupancyRate.value}%',
                      subtitle: isSw ? 'Wiki hii' : 'This week',
                      onTap: controller.openBnbProperties,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BnbOverviewCard(
                      title: isSw ? 'Vyumba' : 'Units',
                      value: '${controller.bnbUnitsCount.value}',
                      subtitle: 'BnB',
                      onTap: controller.openBnbProperties,
                    ),
                  ),
                ],
              ),
          ] else ...[
            if (showTenants || showProperties)
              Row(
                children: [
                  if (showTenants)
                    Expanded(
                      child: _BnbOverviewCard(
                        title: isSw ? 'Wapangaji' : 'Tenants',
                        value: '${controller.rentTenantsCount.value}',
                        subtitle: isSw ? 'Wanaokaa sasa' : 'Active now',
                        onTap: controller.openAllTenants,
                      ),
                    ),
                  if (showTenants && showProperties) const SizedBox(width: 12),
                  if (showProperties)
                    Expanded(
                      child: _BnbOverviewCard(
                        title: isSw ? 'Ukaaji wa Rent' : 'Rent Occupancy',
                        value: '${controller.rentOccupancyRate.value}%',
                        subtitle: isSw ? 'Vyumbo vilivyokaliwa' : 'Units occupied',
                        onTap: controller.openRentProperties,
                      ),
                    ),
                ],
              ),
            if (showMoney) const SizedBox(height: 12),
            if (showMoney)
            _CollectionRateCard(
              title: isSw ? 'Ukusanyaji wa Kodi' : 'Collection',
              rate: controller.collectionRate.value,
              tenantCount: controller.rentTenantsCount.value,
              subtitle: isSw
                  ? 'Kodi iliyokusanywa mwezi huu'
                  : 'Rent collected this month',
              onTap: controller.openTodayRevenue,
            ),
            if (showMoney) const SizedBox(height: 12),
            if (showMoney)
            _MonthIncomeCard(
              title: isSw ? 'Mapato ya mwezi' : 'Income this month',
              expectedLabel: isSw ? 'Inayotarajiwa' : 'Expected',
              collectedLabel: isSw ? 'Iliyokusanywa' : 'Collected',
              expectedValue: controller.expectedIncomeLabel.value,
              collectedValue: controller.collectedIncomeLabel.value,
              onTap: controller.openTodayRevenue,
            ),
          ],
        ],
      );
    });
  }

  Widget _buildRecentPaymentsBlock(BuildContext context) {
    return Obx(() {
      // Touch Rx so filter changes rebuild the list.
      controller.homeWorkspaceFilter.value;
      controller.recentPayments.length;
      if (!_staffAllows(StaffPermissions.viewPayments)) {
        return const SizedBox.shrink();
      }
      final payments = controller.visibleRecentPayments;
      if (payments.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(context, 'Recent payments', 'Malipo ya hivi karibuni'),
              ),
              TextButton(
                onPressed: controller.openAllRecentPayments,
                child: Text(
                  _t(context, 'See all', 'Ona yote'),
                  style: TextStyle(
                    color: AppColors.colorPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RecentPaymentsList(payments: payments),
        ],
      );
    });
  }

  /// Block 3 — navigate to tools (Create is the button above; AI is the FAB).
  Widget _buildGoToBlock(BuildContext context) {
    return Obx(() {
      final showBnb = controller.showBnbHomeContent;
      final showRent = controller.showRentHomeContent;
      // One label → one destination ([HomeController.openPeople] → All Tenants).
      final peopleLabel = showBnb && !showRent
          ? _t(context, 'Guests', 'Wageni')
          : showRent && !showBnb
              ? _t(context, 'Tenants', 'Wapangaji')
              : _t(context, 'Tenants & Guests', 'Wapangaji na Wageni');

      final tiles = <Widget>[
        if (_staffAllows(StaffPermissions.viewBookings))
          _QuickActionTile(
            materialIcon: Icons.calendar_today_outlined,
            label: _t(context, 'Calendar', 'Kalenda'),
            onTap: controller.calendar,
          ),
        if (_staffAllows(StaffPermissions.viewTenants) ||
            _staffAllows(StaffPermissions.viewBookings))
          _QuickActionTile(
            materialIcon: Icons.people_outline_rounded,
            label: peopleLabel,
            onTap: controller.openPeople,
          ),
        if (_staffAllows(StaffPermissions.messageGuest))
          _QuickActionTile(
            materialIcon: Icons.sms_outlined,
            label: _t(context, 'SMS / WhatsApp', 'SMS / WhatsApp'),
            onTap: controller.sendSmsWhatsapp,
          ),
        if (_staffAllows(StaffPermissions.viewReports))
          _QuickActionTile(
            materialIcon: Icons.assessment_outlined,
            label: _t(context, 'Reports', 'Ripoti'),
            onTap: controller.reports,
          ),
      ];
      if (tiles.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Go to', 'Nenda'),
          const SizedBox(height: 4),
          Text(
            _t(
              context,
              'Shortcuts — use Create above to add records',
              'Njia za haraka — tumia Unda hapo juu kuongeza',
            ),
            style: TextStyle(
              fontSize: 12,
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            // Taller cells so icon + 2-line labels fit without overflow.
            childAspectRatio: 1.2,
            children: tiles,
          ),
          const SizedBox(height: 4),
          if (_staffAllows(StaffPermissions.viewReports))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: controller.viewTrends,
              child: Text(
                _t(
                  context,
                  'View finances & reports →',
                  'Angalia fedha na ripoti →',
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyHomeState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.colorPrimaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_home_work_rounded,
                size: 44,
                color: AppColors.colorPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _t(
                context,
                "Let's add your first property",
                'Tuongeze mali yako ya kwanza',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                context,
                'Add a property to start tracking bookings, tenants, income and expenses — everything else on this screen fills in automatically.',
                'Ongeza mali ili kuanza kufuatilia uhifadhi, wapangaji, mapato na matumizi — vitu vingine kwenye skrini hii vitajaa kiotomatiki.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: context.tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.addListing,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  _t(context, 'Add Property', 'Ongeza Mali'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t(
                context,
                'Takes less than a minute',
                'Inachukua chini ya dakika moja',
              ),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              _t(
                context,
                'Tip: you can also add properties anytime from the Properties tab below.',
                'Kidokezo: unaweza pia kuongeza mali wakati wowote kutoka kichupo cha Mali chini.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalGuestSection(
    BuildContext context, {
    required String title,
    required RxList<CheckInItem> list,
    VoidCallback? onSeeAll,
    String? seeAllLabel,
  }) {
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty || (onSeeAll != null && seeAllLabel != null))
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title.isNotEmpty)
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.tokens.textPrimary,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (onSeeAll != null && seeAllLabel != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    seeAllLabel,
                    style: TextStyle(
                      color: AppColors.colorPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        if (title.isNotEmpty || (onSeeAll != null && seeAllLabel != null))
          const SizedBox(height: 12),
        Obx(() {
          if (list.isEmpty) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                return _CheckInCard(
                  item: item,
                  onTap: () => controller.openBookingDetails(item),
                  onLongPress: () => showHomeGuestQuickActionsSheet(
                    context: context,
                    item: item,
                    controller: controller,
                  ),
                  onRetrySync: item.syncStatus == ItemSyncStatus.failed
                      ? () => controller.retryBookingSync(item)
                      : null,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _TodayQuietCard extends StatelessWidget {
  const _TodayQuietCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.isDark ? Colors.white12 : const Color(0xFFE8ECF0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: c.isDark
              ? AppColors.textColorSecondary
              : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _TodayAlertTile extends StatelessWidget {
  const _TodayAlertTile({
    required this.icon,
    required this.title,
    required this.expanded,
    required this.onTap,
    this.count,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final int? count;
  final String? subtitle;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: c.isDark ? Colors.white12 : const Color(0xFFE8ECF0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.colorPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.headline,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.isDark
                              ? AppColors.textColorSecondary
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.colorPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                ),
              if (count != null) const SizedBox(width: 4),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.chevron_right_rounded,
                color: c.isDark
                    ? AppColors.textColorSecondary
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final CheckInItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetrySync;

  const _CheckInCard({
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onRetrySync,
  });

  Widget _imagePlaceholder({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      color: AppColors.lightGreyColor,
      child: const Icon(
        Icons.image_not_supported,
        color: AppColors.textColorSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final textColor = c.headline;
    final subTextColor = c.secondary;
    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: item.imageUrl.isEmpty
                    ? _imagePlaceholder(height: 100, width: double.infinity)
                    : PropertyListingImage(
                        imagePath: item.imageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.lightGreyColor,
                          backgroundImage: item.guestAvatarUrl.isNotEmpty
                              ? NetworkImage(item.guestAvatarUrl)
                              : null,
                          child: item.guestAvatarUrl.isEmpty
                              ? Text(
                                  item.guestName.isNotEmpty
                                      ? item.guestName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.guestName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.showSyncBadge) ...[
                          SyncStatusChip(
                            status: item.syncStatus,
                            onRetry: onRetrySync,
                            compact: true,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (item.isCancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .bookingCancelledLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          )
                        else if (item.isConfirmed && !item.isInactive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.colorPrimaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'sw'
                                  ? 'Imethibitishwa'
                                  : 'Confirmed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.colorPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.propertyType,
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                    Text(
                      item.dates,
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String? icon;
  final IconData? materialIcon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    this.icon,
    this.materialIcon,
    required this.label,
    required this.onTap,
  }) : assert(icon != null || materialIcon != null);

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.colorPrimaryLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: materialIcon != null
                              ? Icon(
                                  materialIcon,
                                  size: 22,
                                  color: AppColors.colorPrimary,
                                )
                              : SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: SvgPicture.asset(
                                    'images/$icon',
                                    fit: BoxFit.contain,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.colorPrimary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.headline,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthIncomeCard extends StatelessWidget {
  const _MonthIncomeCard({
    required this.title,
    required this.expectedLabel,
    required this.collectedLabel,
    required this.expectedValue,
    required this.collectedValue,
    this.onTap,
  });

  final String title;
  final String expectedLabel;
  final String collectedLabel;
  final String expectedValue;
  final String collectedValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.isDark ? Colors.white70 : AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expectedLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.hint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expectedValue,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.headline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: c.isDark ? Colors.white12 : const Color(0xFFE8ECF0),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collectedLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.hint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        collectedValue,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.colorPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: card,
    );
  }
}

class _RecentPaymentsList extends StatelessWidget {
  const _RecentPaymentsList({required this.payments});

  final List<IncomeRecord> payments;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final currency = Get.find<CurrencyService>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: c.isDark ? Colors.white12 : const Color(0xFFE8ECF0),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < payments.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: c.isDark ? Colors.white12 : const Color(0xFFE8ECF0),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payments[i].tenantName.trim().isEmpty
                              ? (payments[i].apartment.trim().isEmpty
                                  ? '—'
                                  : payments[i].apartment.trim())
                              : payments[i].tenantName.trim(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.headline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (payments[i].datePaidIso.trim().isNotEmpty)
                              payments[i].datePaidIso.trim(),
                            if (payments[i].apartment.trim().isNotEmpty &&
                                payments[i].tenantName.trim().isNotEmpty)
                              payments[i].apartment.trim(),
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: c.hint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currency.formatBaseShort(payments[i].amountValue),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingMaintenanceList extends StatelessWidget {
  const _UpcomingMaintenanceList({
    required this.items,
    required this.onSeeAll,
    required this.seeAllLabel,
  });

  final List<RentScheduledMaintenanceRecord> items;
  final VoidCallback onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final show = items.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.isDark ? Colors.white12 : const Color(0xFFE8ECF0),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < show.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: c.isDark ? Colors.white12 : const Color(0xFFE8ECF0),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          show[i].category.trim().isEmpty
                              ? show[i].description.trim()
                              : show[i].category.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.headline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            show[i].scheduledDateIso.trim(),
                            if (show[i].propertyLabel.trim().isNotEmpty)
                              show[i].propertyLabel.trim(),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: TextStyle(fontSize: 12, color: c.hint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          InkWell(
            onTap: onSeeAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Text(
                    seeAllLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.colorPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BnbOverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  const _BnbOverviewCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: c.isDark ? Colors.white70 : AppColors.textColorSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: c.isDark
                    ? Colors.white38
                    : AppColors.textColorSecondary.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: card,
    );
  }
}

// ── Collection rate card with donut chart ─────────────────────────────────────

class _CollectionRateCard extends StatelessWidget {
  final String title;
  final int rate; // 0–100+ (clamped to 100 visually)
  final int tenantCount;
  final String subtitle;
  final VoidCallback? onTap;

  const _CollectionRateCard({
    required this.title,
    required this.rate,
    required this.tenantCount,
    required this.subtitle,
    this.onTap,
  });

  static const _green = Color(0xFF4CAF82);
  static const _track = Color(0xFFE8ECF0);

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = c.isDark;
    final trackColor = isDark ? const Color(0xFF2A2A2A) : _track;
    final filled = rate.clamp(0, 100).toDouble();
    final empty = (100 - filled).clamp(0.0, 100.0);

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Left: text info ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark ? Colors.white54 : AppColors.textColorSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$rate%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white38
                        : AppColors.textColorSecondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$tenantCount tenants',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ── Right: donut chart ─────────────────────────────────────────
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 34,
                    sections: [
                      PieChartSectionData(
                        value: filled > 0 ? filled : 0.01,
                        color: _green,
                        radius: 14,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: empty > 0 ? empty : 0.01,
                        color: trackColor,
                        radius: 14,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rate%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rate >= 80 ? 'healthy' : rate >= 50 ? 'fair' : 'low',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white54 : AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: card,
    );
  }
}

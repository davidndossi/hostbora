import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../inventory_tracking/views/inventory_low_stock_banner.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/local/service/currency_service.dart';
import '/app/core/base/base_view.dart';
import '../../../core/widget/hub_insight_banner.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../core/widget/sync_status_chip.dart';
import '../../../core/models/item_sync_status.dart';
import '../../../data/model/check_in_item.dart';
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
        return RefreshIndicator(
          onRefresh: () => controller.loadHomeData(refresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPropertyOverview(context),
                const SizedBox(height: 12),
                const HubInsightBanner(),
                const SizedBox(height: 12),
                const InventoryLowStockBanner(),
                const SizedBox(height: 12),
                // const SizedBox(height: 12),
                // const Center(child: _PulsingDownArrow()),
                // const SizedBox(height: 20),
                _buildOverviewSection(context),
                _buildBnbWeeklyReportsSection(context),
                if (controller.checkInsToday.isNotEmpty) ...[
                  _buildHorizontalGuestSection(
                    context,
                    title: appLocalization.homeCheckInGuestsToday,
                    list: controller.checkInsToday,
                  ),
                  const SizedBox(height: 24),
                ],
                if (controller.checkOutsToday.isNotEmpty) ...[
                  _buildHorizontalGuestSection(
                    context,
                    title: appLocalization.homeCheckOutGuestsToday,
                    list: controller.checkOutsToday,
                  ),
                  const SizedBox(height: 24),
                ],
                if (controller.checkIns.isNotEmpty) ...[
                  _buildUpcomingCheckIns(context),
                  const SizedBox(height: 24),
                ],
                _buildQuickActions(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPropertyOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _t(context, 'Property Overview', 'Muhtasari wa Mali'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.tokens.textPrimary,
              ),
            ),
            TextButton(
              onPressed: controller.viewTrends,
              child: Text(
                _t(context, 'View Trends', 'Angalia Mwelekeo'),
                style: TextStyle(
                  color: AppColors.colorPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: _t(context, 'Active Bookings', 'Uhifadhi Hai'),
                  value: '${controller.activeBookings.value}',
                  subtitle: controller.bookingsChange.value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: _t(context, 'Monthly Revenue', 'Mapato ya Mwezi'),
                  value: controller.monthlyRevenue.value,
                  subtitle: controller.revenueChange.value,
                ),
              ),
            ],
          ),
        ),
      ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
              ),
            ),
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

  Widget _buildUpcomingCheckIns(BuildContext context) {
    if (controller.checkIns.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildHorizontalGuestSection(
      context,
      title: _t(context, 'Upcoming Check-ins', 'Wanaoingia Hivi Karibuni'),
      list: controller.checkIns,
      onSeeAll: controller.seeAllCheckIns,
      seeAllLabel: _t(context, 'See All', 'Ona Yote'),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, 'Quick Actions', 'Vitendo vya Haraka'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _QuickActionTile(
              materialIcon: Icons.calendar_today_outlined,
              label: _t(context, 'Calendar', 'Kalenda'),
              onTap: controller.calendar,
            ),
            _QuickActionTile(
              icon: 'ic_group.svg',
              label: _t(context, 'Tenants / Guests', 'Wapangaji / Wageni'),
              onTap: controller.tenants,
            ),
            _QuickActionTile(
              materialIcon: Icons.sms_outlined,
              label: _t(context, 'Send SMS / WhatsApp', 'Tuma SMS / WhatsApp'),
              onTap: controller.sendSmsWhatsapp,
            ),
            // _QuickActionTile(
            //   materialIcon: Icons.chat_outlined,
            //   label: _t(context, 'WhatsApp templates', 'Violezo vya WhatsApp'),
            //   onTap: controller.whatsappTemplates,
            // ),
            _QuickActionTile(
              icon: 'ic_calendar.svg',
              label: _t(context, 'Add Booking', 'Ongeza Uhifadhi'),
              onTap: controller.addNewBooking,
            ),
            // _QuickActionTile(icon: 'ic_smart_key.svg', label: 'Smart Access', onTap: controller.smartAccess),
            // _QuickActionTile(
            //   icon: 'ic_completion.svg',
            //   label: _t(context, 'Maintenance & Tasks', 'Matengenezo na Kazi'),
            //   onTap: controller.tasks,
            // ),
            _QuickActionTile(
              icon: 'ic_design_studio.svg',
              label: _t(context, 'Design', 'Ubunifu'),
              onTap: () => _showDesignQuickActions(context),
            ),
            _QuickActionTile(
              icon: 'ic_reports.svg',
              label: _t(context, 'Reports', 'Ripoti'),
              onTap: controller.reports,
            ),
          ],
        ),
      ],
    );
  }

  void _showDesignQuickActions(BuildContext context) {
    final isSw = Get.locale?.languageCode == 'sw';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(isSw ? 'Studio ya ubunifu' : 'Design studio'),
              onTap: () {
                Navigator.pop(ctx);
                controller.designStudio();
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: Text(isSw ? 'Moodboard' : 'Moodboards'),
              onTap: () {
                Navigator.pop(ctx);
                controller.designMoodboards();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, 'Overview', 'Muhtasari'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Row 1 – total units | BnB occupancy
          Row(
            children: [
              Expanded(
                child: _BnbOverviewCard(
                  title: isSw ? 'Jumla ya Vyumba' : 'Total Units',
                  value: '${controller.totalUnitsCount.value}',
                  subtitle: isSw ? 'BnB + Rent' : 'BnB + Rent',
                  onTap: controller.openProperties,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BnbOverviewCard(
                  title: isSw ? 'Ukaaji wa BnB' : 'BnB Occupancy',
                  value: '${controller.bnbOccupancyRate.value}%',
                  subtitle: isSw ? 'Wiki hii' : 'This week',
                  onTap: controller.openBnbProperties,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2 – rent occupancy | tenants
          Row(
            children: [
              Expanded(
                child: _BnbOverviewCard(
                  title: isSw ? 'Ukaaji wa Rent' : 'Rent Occupancy',
                  value: '${controller.rentOccupancyRate.value}%',
                  subtitle: isSw ? 'Vyumbo vilivyokaliwa' : 'Units occupied',
                  onTap: controller.openRentProperties,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BnbOverviewCard(
                  title: isSw ? 'Wapangaji' : 'Tenants',
                  value: '${controller.rentTenantsCount.value}',
                  subtitle: isSw ? 'Wanaokaa sasa' : 'Active now',
                  onTap: controller.openAllTenants,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3 – collection rate (full width with donut chart)
          _CollectionRateCard(
            title: isSw ? 'Ukusanyaji wa Kodi' : 'Collection',
            rate: controller.collectionRate.value,
            tenantCount: controller.rentTenantsCount.value,
            subtitle: isSw
                ? 'Kodi iliyokusanywa mwezi huu'
                : 'Rent collected this month',
            onTap: controller.openTodayRevenue,
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildBnbWeeklyReportsSection(BuildContext context) {
    return Obx(() {
      // Observe list contents so charts update after quiet reloads.
      final revenue = List<double>.from(controller.weeklyRevenue);
      final occupancy = List<double>.from(controller.weeklyOccupancyPercent);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyBarChartCard(
            context,
            title: appLocalization.dashboardWeeklyRevenue,
            subtitle: appLocalization.dashboardWeekTrend,
            values: revenue,
            maxYCap: null,
            formatTooltip: (v) =>
                Get.find<CurrencyService>().formatBase(v.round()),
          ),
          const SizedBox(height: 16),
          _buildWeeklyBarChartCard(
            context,
            title: appLocalization.dashboardWeeklyOccupancy,
            subtitle: appLocalization.dashboardWeekTrend,
            values: occupancy,
            maxYCap: 100,
            formatTooltip: (v) => '${v.round()}%',
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildWeeklyBarChartCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required List<double> values,
        required double? maxYCap,
        required String Function(double) formatTooltip,
      }) {
    final data = values;
    final maxVal = data.fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxYCap ?? (maxVal <= 0 ? 1.0 : maxVal * 1.12);
    final peakValue = maxVal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card.copyWith(
        color: FormSurfaceColors.of(context).isDark
            ? const Color(0xFF1F1F1F)
            : AppColors.colorWhite,
        border: Border.all(
          color: FormSurfaceColors.of(context).isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: FormSurfaceColors.of(context).isDark ? 0.28 : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: context.tokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        formatTooltip(rod.toY),
                        TextStyle(
                          color: context.tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 ||
                            i >= HomeController.weeklyDayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            HomeController.weeklyDayLabels[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (FormSurfaceColors.of(context).isDark
                        ? Colors.white
                        : AppColors.designInputBorder)
                        .withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  HomeController.weeklyDayLabels.length,
                      (i) {
                    final v = i < data.length ? data[i] : 0.0;
                    final isPeak = peakValue > 0 && v == peakValue;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          fromY: 0,
                          toY: v,
                          width: 18,
                          color: isPeak
                              ? AppColors.designAccent
                              : AppColors.designAccent.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              duration: const Duration(milliseconds: 150),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDownArrow extends StatefulWidget {
  const _PulsingDownArrow();

  @override
  State<_PulsingDownArrow> createState() => _PulsingDownArrowState();
}

class _PulsingDownArrowState extends State<_PulsingDownArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'More content below',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final progress = _pulse.value;
          return Opacity(
            opacity: 0.55 + (progress * 0.45),
            child: Transform.translate(
              offset: Offset(0, progress * 6),
              child: Transform.scale(
                scale: 0.92 + (progress * 0.08),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.colorPrimary.withValues(alpha: 0.12),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.colorPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
              fontSize: 14,
              color: c.isDark
                  ? AppColors.textColorSecondary
                  : AppColors.textColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.headline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: c.isDark
                  ? AppColors.textColorSecondary
                  : AppColors.textColorSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

  Widget _buildNetworkImage({
    required String url,
    required double height,
    required double width,
    required BoxFit fit,
  }) {
    if (url.isEmpty) {
      return _imagePlaceholder(height: height, width: width);
    }
    return _NetworkImageFromUrl(
      url: url,
      height: height,
      width: width,
      fit: fit,
      placeholder: _imagePlaceholder(height: height, width: width),
    );
  }

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
                    : _buildNetworkImage(
                        url: item.imageUrl,
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
                        if (item.isConfirmed)
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

/// Loads an image via Dio with browser-like headers so it works when Image.network fails.
class _NetworkImageFromUrl extends StatefulWidget {
  final String url;
  final double height;
  final double width;
  final BoxFit fit;
  final Widget placeholder;

  const _NetworkImageFromUrl({
    required this.url,
    required this.height,
    required this.width,
    required this.fit,
    required this.placeholder,
  });

  @override
  State<_NetworkImageFromUrl> createState() => _NetworkImageFromUrlState();
}

class _NetworkImageFromUrlState extends State<_NetworkImageFromUrl> {
  Uint8List? _bytes;
  Uint8List? _svgBytes;
  bool _failed = false;

  static final Dio _dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
        'Accept': 'image/*,*/*',
      },
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _NetworkImageFromUrl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _svgBytes = null;
      _failed = false;
      _load();
    }
  }

  /// Returns true if bytes look like SVG (e.g. placehold.co returns SVG).
  bool _isSvgBytes(Uint8List bytes) {
    if (bytes.length < 5) return false;
    final start = String.fromCharCodes(bytes.take(100));
    return start.trimLeft().startsWith('<svg') ||
        start.trimLeft().startsWith('<?xml');
  }

  /// Returns true if bytes look like a raster image (JPEG, PNG, GIF, WebP).
  bool _isRasterImageBytes(Uint8List bytes) {
    if (bytes.length < 4) {
      return false;
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return true;
    }
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    return false;
  }

  Future<void> _load() async {
    if (widget.url.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    try {
      final response = await _dio.get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null && response.data!.isNotEmpty && mounted) {
        final bytes = Uint8List.fromList(response.data!);
        if (_isSvgBytes(bytes)) {
          setState(() {
            _svgBytes = bytes;
            _bytes = null;
            _failed = false;
          });
        } else if (_isRasterImageBytes(bytes)) {
          setState(() {
            _bytes = bytes;
            _svgBytes = null;
            _failed = false;
          });
        } else {
          setState(() => _failed = true);
        }
      } else if (mounted) {
        setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _bytes != null || _svgBytes != null;
    if (_failed || !hasContent) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: !hasContent && !_failed
            ? Center(
                child: CircularProgressIndicator(color: AppColors.designAccent),
              )
            : widget.placeholder,
      );
    }
    if (_svgBytes != null) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: SvgPicture.memory(
          _svgBytes!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }
    return Image.memory(
      _bytes!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        height: widget.height,
        width: widget.width,
        child: widget.placeholder,
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.colorPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: materialIcon != null
                      ? Icon(
                          materialIcon,
                          size: 24,
                          color: AppColors.colorPrimary,
                        )
                      : SizedBox(
                          width: 20,
                          height: 20,
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
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.headline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Material(
      color: isSelected
          ? AppColors.designAccent
          : (c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite),
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: isSelected
                ? null
                : Border.all(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.designInputBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.textColorSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
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

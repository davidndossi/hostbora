import 'package:flutter/material.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/model/check_in_item.dart';
import '../controllers/host_dashboard_controller.dart';

class HostDashboardView extends BaseView<HostDashboardController> {
  HostDashboardView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.hostDashboard,
      isBackButtonEnabled: false,
      actions: [
        IconButton(
          onPressed: controller.openNotifications,
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.appBarIconColor,
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyOverview(context),
            const SizedBox(height: 24),
            _buildUpcomingCheckIns(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
              _t(context, en: 'Property Overview', sw: 'Muhtasari wa Mali'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isDark(context)
                    ? Colors.white
                    : AppColors.textColorPrimary,
              ),
            ),
            TextButton(
              onPressed: controller.viewTrends,
              child: Text(
                _t(context, en: 'View Trends', sw: 'Angalia Mwelekeo'),
                style: TextStyle(
                  color: AppColors.colorPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: _t(context, en: 'Active Bookings', sw: 'Uhifadhi Hai'),
                value: '${controller.activeBookings}',
                subtitle: controller.bookingsChange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: _t(
                  context,
                  en: 'Monthly Revenue',
                  sw: 'Mapato ya Mwezi',
                ),
                value: controller.monthlyRevenue,
                subtitle: controller.revenueChange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingCheckIns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _t(
                context,
                en: 'Upcoming Check-ins',
                sw: 'Wanaoingia Hivi Karibuni',
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isDark(context)
                    ? Colors.white
                    : AppColors.textColorPrimary,
              ),
            ),
            TextButton(
              onPressed: controller.seeAllCheckIns,
              child: Text(
                _t(context, en: 'See All', sw: 'Ona Yote'),
                style: TextStyle(
                  color: AppColors.colorPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.checkIns.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = controller.checkIns[index];
              return _CheckInCard(
                item: item,
                onTap: () => controller.openBookingDetails(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, en: 'Quick Actions', sw: 'Vitendo vya Haraka'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _isDark(context) ? Colors.white : AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _QuickActionTile(
              icon: Icons.add_home_work_outlined,
              label: _t(context, en: 'Add Listing', sw: 'Ongeza Tangazo'),
              onTap: controller.addListing,
            ),
            _QuickActionTile(
              icon: Icons.calendar_today_outlined,
              label: _t(context, en: 'Add Booking', sw: 'Ongeza Uhifadhi'),
              onTap: controller.addNewBooking,
            ),
            _QuickActionTile(
              icon: Icons.key,
              label: _t(context, en: 'Smart Access', sw: 'Ufikiaji Mahiri'),
              onTap: controller.smartAccess,
            ),
            _QuickActionTile(
              icon: Icons.calendar_month_outlined,
              label: _t(context, en: 'View Calendar', sw: 'Angalia Kalenda'),
              onTap: controller.viewCalendar,
            ),
            _QuickActionTile(
              icon: Icons.assignment_outlined,
              label: _t(context, en: 'Assign Tasks', sw: 'Panga Kazi'),
              onTap: controller.assignTasks,
            ),
            _QuickActionTile(
              icon: Icons.bar_chart_outlined,
              label: _t(context, en: 'Reports', sw: 'Ripoti'),
              onTap: controller.reports,
            ),
          ],
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
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
              color: isDark ? Colors.white70 : AppColors.textColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : AppColors.textColorSecondary,
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

  const _CheckInCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                item.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: AppColors.lightGreyColor,
                  child: Icon(
                    Icons.image_not_supported,
                    color: isDark
                        ? Colors.white60
                        : AppColors.textColorSecondary,
                  ),
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
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.textColorSecondary,
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
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                                fontSize: 11,
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      item.dates,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textColorSecondary,
                      ),
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
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: AppColors.colorPrimary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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

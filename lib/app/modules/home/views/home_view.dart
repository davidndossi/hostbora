import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_controller.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_view.dart';
import '../controllers/home_controller.dart';

// ignore: must_be_immutable
class HomeView extends BaseView<HomeController> {
  HomeView({super.key});
  final WorkspaceContextService _workspaceContext =
      Get.find<WorkspaceContextService>();

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.home,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  final ws = _workspaceContext.currentWorkspace.value;
                  final activeLabel = ws == 'bnb' ? 'BnB' : 'RENT';
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.colorPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activeLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
                InkWell(
                  onTap: () async {
                    await _workspaceContext.switchWorkspace('rent');
                    Get.offNamed(Routes.RENT_HUB);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Text(
                      'RENT',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.6,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '|',
                    style: TextStyle(
                      color: AppColors.textColorSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  'BnB',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.4,
                    color: AppColors.colorPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // IconButton(
        //   onPressed: () => Get.toNamed(Routes.NOTIFICATIONS),
        //   icon: Obx(
        //     () => controller.unreadCount.value > 0
        //         ? Badge.count(
        //             count: controller.unreadCount.value,
        //             child: const Icon(Icons.notifications_none_outlined))
        //         : const Icon(Icons.notifications_none_outlined),
        //   ),
        // ),
        // IconButton(
        //   onPressed: () => Get.toNamed(Routes.SETTINGS),
        //   icon: const Icon(Icons.more_vert_outlined)
        // )
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return SafeArea(
      child: Obx(() {
        if (controller.homeLoading.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return SingleChildScrollView(
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
        );
      }),
    );
  }

  Widget _buildThemeSwitch(
    BuildContext context,
    ThemeController themeController,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3A3C)
              : AppColors.designInputBorder,
        ),
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
          Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.dark_mode
                : Icons.light_mode,
            size: 22,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.colorPrimaryLight
                : AppColors.colorPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t(context, 'Dark theme', 'Mandhari ya giza'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textColorPrimary,
              ),
            ),
          ),
          Obx(
            () => Switch(
              value: themeController.isDarkMode.value,
              onChanged: (_) => themeController.toggleTheme(),
              activeTrackColor: AppColors.colorPrimaryLight,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.colorPrimary;
                }
                return AppColors.designInputBorder;
              }),
            ),
          ),
        ],
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
              _t(context, 'Property Overview', 'Muhtasari wa Mali'),
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

  Widget _buildUpcomingCheckIns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _t(context, 'Upcoming Check-ins', 'Wanaoingia Hivi Karibuni'),
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
                _t(context, 'See All', 'Ona Yote'),
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
          final list = controller.checkIns;
          if (list.isEmpty) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  _t(
                    context,
                    'No upcoming check-ins',
                    'Hakuna wanaoingia hivi karibuni',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : AppColors.textColorSecondary,
                  ),
                ),
              ),
            );
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
                );
              },
            ),
          );
        }),
      ],
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
          childAspectRatio: 1.3,
          children: [
            _QuickActionTile(
              icon: 'ic_properties.svg',
              label: _t(context, 'Properties', 'Mali'),
              onTap: controller.properties,
            ),
            _QuickActionTile(
              icon: 'ic_add_property.svg',
              label: _t(context, 'Add Listing', 'Ongeza Tangazo'),
              onTap: controller.addListing,
            ),
            _QuickActionTile(
              icon: 'ic_calendar.svg',
              label: _t(context, 'Add Booking', 'Ongeza Uhifadhi'),
              onTap: controller.addNewBooking,
            ),
            // _QuickActionTile(icon: 'ic_smart_key.svg', label: 'Smart Access', onTap: controller.smartAccess),
            _QuickActionTile(
              icon: 'ic_completion.svg',
              label: _t(context, 'Maintenance & Tasks', 'Matengenezo na Kazi'),
              onTap: controller.tasks,
            ),
            // _QuickActionTile(icon: 'ic_design_studio.svg', label: 'Design Studio', onTap: controller.designStudio),
            // _QuickActionTile(icon: 'ic_pinterest.svg', label: 'Moodboards', onTap: controller.designMoodboards),
            // _QuickActionTile(icon: 'ic_ai_manager.svg', label: 'AI Manager', onTap: controller.aiManager),
            // _QuickActionTile(icon: 'ic_ai_insights.svg', label: 'AI Insights', onTap: controller.aiInsights),
            // _QuickActionTile(icon: 'ic_robot.svg', label: 'AI Automations', onTap: controller.aiAutomations),
            _QuickActionTile(
              icon: 'ic_reports.svg',
              label: _t(context, 'Reports', 'Ripoti'),
              onTap: controller.reports,
            ),
            _QuickActionTile(
              icon: 'ic_vault.svg',
              label: _t(context, 'Vault', 'Hifadhi'),
              onTap: controller.documents,
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
              color: isDark
                  ? AppColors.textColorSecondary
                  : AppColors.textColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark
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

  const _CheckInCard({required this.item, this.onTap});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textColorPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textColorSecondary;
    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
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
  final String icon;
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
                  child: SizedBox(
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
                    color: isDark ? Colors.white : AppColors.textColorPrimary,
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

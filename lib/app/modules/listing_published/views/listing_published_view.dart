import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/listing_published_controller.dart';

class ListingPublishedView extends BaseView<ListingPublishedController> {
  ListingPublishedView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.newProperty,
      actions: [
        IconButton(
          onPressed: controller.close,
          icon: const Icon(Icons.close, size: 24),
          color: AppColors.textColorPrimary,
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildImageSection(context),
            const SizedBox(height: 24),
            Text(
              _t(context, en: 'Congratulations!', sw: 'Hongera!'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : AppColors.textColorPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                context,
                en: 'Your listing is now live and ready for bookings.',
                sw: 'Tangazo lako sasa lipo hewani na tayari kwa nafasi.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.textColorSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.viewListing,
                icon: const Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  _t(context, en: 'View Listing', sw: 'Tazama Tangazo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: controller.goToDashboard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? theme.colorScheme.onSurface
                      : AppColors.textColorPrimary,
                  side: BorderSide(
                    color: isDark
                        ? theme.colorScheme.outlineVariant
                        : AppColors.designInputBorder,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                  ),
                ),
                child: Text(
                  _t(context, en: 'Go to Dashboard', sw: 'Nenda Dashibodi'),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: AppColors.textColorSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t(
                      context,
                      en: 'Tip: Complete your profile to build trust',
                      sw: 'Dokezo: Kamilisha wasifu wako kujenga uaminifu',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : AppColors.textColorSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.lightGreyColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppValues.radius_12),
          ),
          child: Icon(
            Icons.home_work_outlined,
            size: 80,
            color: AppColors.designPlaceholder,
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.colorPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _t(context, en: 'LIVE', sw: 'HEWANI'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColorWhite,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHigh
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.check, size: 26, color: AppColors.colorPrimary),
          ),
        ),
      ],
    );
  }
}

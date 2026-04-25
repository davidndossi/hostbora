import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/booking_details_controller.dart';

class BookingDetailsView extends BaseView<BookingDetailsController> {
  BookingDetailsView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.bookingDetails,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Obx(() {
      final isListingMode = controller.isListingMode;
      return Column(
        children: [
          _buildHeader(context, topPadding),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isListingMode) ...[
                    _buildCheckAvailabilitySection(context),
                  ] else ...[
                    _buildGuestCard(context),
                    const SizedBox(height: 16),
                    _buildCheckInOutRow(context),
                    const SizedBox(height: 20),
                    _buildPaymentRow(context),
                    const SizedBox(height: 24),
                    _buildSectionLabel(
                      context,
                      _t(
                        context,
                        en: 'RESERVATION DETAILS',
                        sw: 'MAELEZO YA UHIFADHI',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMessageGuestButton(context),
                    const SizedBox(height: 12),
                    _buildModifyBookingLink(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCheckAvailabilitySection(BuildContext context) {
    return Obx(() {
      final mode = controller.availabilityMode.value;
      final selectedMonth = controller.selectedMonth.value;
      final selectedDate = controller.selectedDate.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, en: 'Check availability', sw: 'Angalia upatikanaji'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _isDark(context)
                  ? Colors.white
                  : AppColors.textColorPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              context,
              en: 'View availability for today, a month, or a specific date.',
              sw: 'Tazama upatikanaji wa leo, mwezi mzima, au tarehe maalum.',
            ),
            style: TextStyle(
              fontSize: 14,
              color: _isDark(context)
                  ? Colors.white70
                  : AppColors.textColorSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel(
            context,
            _t(context, en: 'SHOW AVAILABILITY', sw: 'ONYESHA UPATIKANAJI'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _availabilityChip(
                  context,
                  label: _t(context, en: 'Today', sw: 'Leo'),
                  selected: mode == 'today',
                  onTap: () => controller.setAvailabilityMode('today'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _availabilityChip(
                  context,
                  label: _t(context, en: 'Month', sw: 'Mwezi'),
                  selected: mode == 'month',
                  onTap: () => controller.setAvailabilityMode('month'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _availabilityChip(
                  context,
                  label: _t(context, en: 'Month + Date', sw: 'Mwezi + Tarehe'),
                  selected: mode == 'month_date',
                  onTap: () => controller.setAvailabilityMode('month_date'),
                ),
              ),
            ],
          ),
          if (mode == 'month') ...[
            const SizedBox(height: 16),
            _buildSectionLabel(context, _t(context, en: 'MONTH', sw: 'MWEZI')),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => controller.pickMonth(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                side: const BorderSide(color: AppColors.designInputBorder),
                backgroundColor: _isDark(context)
                    ? const Color(0xFF1F1F1F)
                    : AppColors.colorWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: AppColors.colorPrimary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedMonth != null
                        ? '${_monthName(selectedMonth.month)} ${selectedMonth.year}'
                        : _t(context, en: 'Select month', sw: 'Chagua mwezi'),
                    style: TextStyle(
                      color: _isDark(context)
                          ? Colors.white
                          : AppColors.textColorPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (mode == 'month_date') ...[
            const SizedBox(height: 16),
            _buildSectionLabel(
              context,
              _t(context, en: 'MONTH & DATE', sw: 'MWEZI NA TAREHE'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.pickMonth(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: AppColors.designInputBorder,
                      ),
                      backgroundColor: _isDark(context)
                          ? const Color(0xFF1F1F1F)
                          : AppColors.colorWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppValues.radius_6),
                      ),
                    ),
                    child: Text(
                      selectedMonth != null
                          ? '${_monthName(selectedMonth.month)} ${selectedMonth.year}'
                          : _t(context, en: 'Month', sw: 'Mwezi'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _isDark(context)
                            ? Colors.white
                            : AppColors.textColorPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.pickDate(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: AppColors.designInputBorder,
                      ),
                      backgroundColor: _isDark(context)
                          ? const Color(0xFF1F1F1F)
                          : AppColors.colorWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppValues.radius_6),
                      ),
                    ),
                    child: Text(
                      selectedDate != null
                          ? '${selectedDate.day}'
                          : _t(context, en: 'Date', sw: 'Tarehe'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _isDark(context)
                            ? Colors.white
                            : AppColors.textColorPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionLabel(
            context,
            _t(context, en: 'AVAILABILITY', sw: 'UPATIKANAJI'),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDark(context)
                  ? const Color(0xFF1F1F1F)
                  : AppColors.colorWhite,
              borderRadius: BorderRadius.circular(AppValues.radius_12),
              border: Border.all(color: AppColors.designInputBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isDark(context) ? 0.28 : 0.06,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.availabilitySummary,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isDark(context)
                        ? Colors.white
                        : AppColors.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.colorPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.availabilityStatus,
                      style: TextStyle(
                        fontSize: 15,
                        color: _isDark(context)
                            ? Colors.white70
                            : AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  Widget _availabilityChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = _isDark(context);
    return Material(
      color: selected
          ? AppColors.colorPrimaryLight.withValues(alpha: 0.5)
          : (isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite),
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: Border.all(
              color: selected
                  ? AppColors.colorPrimary
                  : AppColors.designInputBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.colorPrimary
                    : (isDark ? Colors.white70 : AppColors.textColorSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double topPadding) {
    final height = MediaQuery.sizeOf(context).height * 0.38;
    return Obx(
      () => SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              controller.propertyImageUrl.value,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.lightGreyColor,
                child: Icon(
                  Icons.home_work_outlined,
                  size: 64,
                  color: AppColors.textColorSecondary,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(top: topPadding > 0 ? 0 : 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _headerIconButton(
                      onPressed: controller.goBack,
                      icon: Icons.arrow_back,
                    ),
                    Row(
                      children: [
                        _headerIconButton(
                          onPressed: controller.share,
                          icon: Icons.share_outlined,
                        ),
                        const SizedBox(width: 12),
                        _headerIconButton(
                          onPressed: controller.moreOptions,
                          icon: Icons.more_horiz,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.propertyTitle.value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.propertyLocation.value,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark(context)
            ? const Color(0xFF1F1F1F)
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDark(context) ? 0.28 : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.colorPrimaryLight,
            backgroundImage: controller.guestAvatarUrl.isNotEmpty
                ? NetworkImage(controller.guestAvatarUrl)
                : null,
            child: controller.guestAvatarUrl.isEmpty
                ? Text(
                    controller.guestName.isNotEmpty
                        ? controller.guestName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colorPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.guestName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _isDark(context)
                        ? Colors.white
                        : AppColors.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.colorSuccessGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${controller.guestRating} (${controller.guestReviewCount} ${_t(context, en: 'reviews', sw: 'maoni')})',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.colorSuccessGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: controller.messageGuest,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.colorPrimary, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 22,
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInOutRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateCard(
            context: context,
            label: 'CHECK-IN',
            date: controller.checkInDate,
            time: controller.checkInTime,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateCard(
            context: context,
            label: 'CHECK-OUT',
            date: controller.checkOutDate,
            time: controller.checkOutTime,
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard({
    required BuildContext context,
    required String label,
    required String date,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark(context)
            ? const Color(0xFF1F1F1F)
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDark(context) ? 0.28 : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: _isDark(context)
                  ? Colors.white70
                  : AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _isDark(context)
                  ? Colors.white
                  : AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: _isDark(context)
                  ? Colors.white70
                  : AppColors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, en: 'Payment Status', sw: 'Hali ya Malipo'),
                style: TextStyle(
                  fontSize: 13,
                  color: _isDark(context)
                      ? Colors.white70
                      : AppColors.textColorSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _t(context, en: 'PAID', sw: 'IMELIPWA'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, en: 'Total Payout', sw: 'Jumla ya Malipo'),
                style: TextStyle(
                  fontSize: 13,
                  color: _isDark(context)
                      ? Colors.white70
                      : AppColors.textColorSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.totalPayout,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colorPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: _isDark(context) ? Colors.white70 : AppColors.textColorSecondary,
      ),
    );
  }

  Widget _buildMessageGuestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.messageGuest,
        icon: const Icon(Icons.mail_outline, size: 22, color: Colors.white),
        label: Text(
          _t(context, en: 'Message Guest', sw: 'Tuma Ujumbe kwa Mgeni'),
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
    );
  }

  Widget _buildModifyBookingLink(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: controller.modifyBooking,
        child: Text(
          _t(context, en: 'Modify Booking', sw: 'Hariri Uhifadhi'),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.colorPrimary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

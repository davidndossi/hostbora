import 'package:flutter/material.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/models/item_sync_status.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/sync_status_chip.dart';
import '../controllers/booking_details_controller.dart';

class BookingDetailsView extends BaseView<BookingDetailsController> {
  BookingDetailsView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  Color _surfaceCard(BuildContext context) => context.tokens.cardBackground;

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
                    const SizedBox(height: 12),
                    _buildRecordPaymentButton(context),
                    const SizedBox(height: 24),
                    _buildSectionLabel(
                      context,
                      _t(
                        context,
                        en: 'Reservation details',
                        sw: 'Maelezo ya uhifadhi',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isCancelled.value) {
                        return _buildCancelledBanner(context);
                      }
                      if (controller.isCheckedOut.value) {
                        return _buildCheckedOutBanner(context);
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 12),
                    _buildGuestMessagingActions(context),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.isCheckedOut.value ||
                          controller.isCancelled.value) {
                        return const SizedBox.shrink();
                      }
                      return _buildStayActions(context);
                    }),
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
              color: context.tokens.textPrimary,
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
              color: context.tokens.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel(
            context,
            _t(context, en: 'Show availability', sw: 'Onyesha upatikanaji'),
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
            _buildSectionLabel(context, _t(context, en: 'Month', sw: 'Mwezi')),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => controller.pickMonth(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                side: const BorderSide(color: AppColors.designInputBorder),
                backgroundColor: _surfaceCard(context),
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
                      color: context.tokens.textPrimary,
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
              _t(context, en: 'Month & date', sw: 'Mwezi na tarehe'),
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
                      backgroundColor: _surfaceCard(context),
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
                        color: context.tokens.textPrimary,
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
                      backgroundColor: _surfaceCard(context),
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
                        color: context.tokens.textPrimary,
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
            _t(context, en: 'Availability', sw: 'Upatikanaji'),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceCard(context),
              borderRadius: BorderRadius.circular(AppValues.radius_12),
              border: Border.all(color: AppColors.designInputBorder),
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
                Text(
                  controller.availabilitySummary,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.textPrimary,
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
                        color: context.tokens.textSecondary,
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
    final c = FormSurfaceColors.of(context);
    return Material(
      color: selected
          ? AppColors.colorPrimaryLight.withValues(alpha: 0.5)
          : context.tokens.cardBackground,
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
                    : (c.secondary),
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
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x4D000000),
                    Color(0xBF000000),
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
            // Keep actions above the gradient / title so taps always register.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    topPadding > 0 ? 0 : 12,
                    12,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _headerIconButton(
                        onPressed: controller.goBack,
                        icon: Icons.arrow_back,
                      ),
                      Row(
                        children: [
                          Builder(
                            builder: (btnCtx) => _headerIconButton(
                              onPressed: () => controller.share(btnCtx),
                              icon: Icons.share_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Builder(
                            builder: (btnCtx) => _headerIconButton(
                              onPressed: () => controller.moreOptions(btnCtx),
                              icon: Icons.more_horiz,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
        color: _surfaceCard(context),
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.colorPrimaryLight,
            backgroundImage: controller.guestAvatarUrl.value.isNotEmpty
                ? NetworkImage(controller.guestAvatarUrl.value)
                : null,
            child: controller.guestAvatarUrl.value.isEmpty
                ? Text(
                    controller.guestName.value.isNotEmpty
                        ? controller.guestName.value[0].toUpperCase()
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
                Obx(
                  () => Text(
                    controller.guestName.value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.tokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Obx(() {
                  final cancelled = controller.isCancelled.value;
                  final checkedOut = controller.isCheckedOut.value;
                  final label = cancelled
                      ? appLocalization.bookingCancelledLabel
                      : checkedOut
                          ? appLocalization.bookingCheckedOut
                          : _t(context, en: 'Confirmed', sw: 'Imethibitishwa');
                  final bg = cancelled
                      ? Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.12)
                      : checkedOut
                          ? AppColors.textColorSecondary.withValues(alpha: 0.15)
                          : AppColors.colorPrimaryLight;
                  final fg = cancelled
                      ? Theme.of(context).colorScheme.error
                      : checkedOut
                          ? context.tokens.textSecondary
                          : AppColors.colorPrimary;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  );
                }),
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
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildDateCard(
              context: context,
              label: 'Check-in',
              date: controller.checkInDate.value,
              time: controller.checkInTime,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDateCard(
              context: context,
              label: 'Check-out',
              date: controller.checkOutDate.value,
              time: controller.checkOutTime,
            ),
          ),
        ],
      ),
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
        color: _surfaceCard(context),
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(BuildContext context) {
    return Obx(() {
      final paid = controller.isPaid.value;
      final payout = controller.totalPayout.value;
      final loading = controller.paymentSummaryLoading.value;
      final syncStatus = controller.paymentSyncStatus.value;
      final statusColor = paid ? AppColors.colorPrimary : const Color(0xFFE67E22);
      final statusIcon = paid ? Icons.check : Icons.schedule;

      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalization.paymentStatus,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (loading)
                  const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              paid
                                  ? appLocalization.paid
                                  : appLocalization.pending,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (controller.showPaymentSyncBadge)
                        SyncStatusChip(
                          status: syncStatus,
                          onRetry: syncStatus ==
                                  ItemSyncStatus.failed
                              ? controller.retryPaymentSync
                              : null,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalization.totalPayout,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '…' : payout,
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
    });
  }

  Widget _buildRecordPaymentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: controller.recordPayment,
        icon: const Icon(Icons.payments_outlined, size: 20),
        label: Text(appLocalization.recordPayment),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.colorPrimary),
          foregroundColor: AppColors.colorPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: context.tokens.textSecondary,
      ),
    );
  }

  Widget _buildGuestMessagingActions(BuildContext context) {
    return Obx(() {
      if (controller.isCheckedOut.value || controller.isCancelled.value) {
        return const SizedBox.shrink();
      }
      final sending = controller.sendingPaymentLink.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
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
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: sending ? null : controller.sendPaymentLinkViaWhatsApp,
              icon: Icon(
                Icons.link,
                color: AppColors.colorPrimary,
              ),
              label: Text(
                _t(
                  context,
                  en: 'Send payment link (WhatsApp)',
                  sw: 'Tuma kiungo cha malipo (WhatsApp)',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.colorPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.colorPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.scheduleGuestWhatsApp,
              icon: Icon(
                Icons.schedule_send_outlined,
                color: AppColors.colorPrimary,
              ),
              label: Text(
                _t(
                  context,
                  en: 'Schedule WhatsApp',
                  sw: 'Ratiba ya WhatsApp',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.colorPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.colorPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCancelledBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cancel_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 10),
          Text(
            appLocalization.bookingCancelledLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedOutBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.textColorSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.logout_rounded,
            color: context.tokens.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            appLocalization.bookingCheckedOut,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStayActions(BuildContext context) {
    return Obx(() {
      final busy = controller.processing.value;
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : controller.showExtendStayDialog,
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
              label: Text(appLocalization.extendStayTitle),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.colorPrimary),
                foregroundColor: AppColors.colorPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : controller.confirmCheckOut,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(appLocalization.checkOutGuest),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: busy ? null : controller.confirmCancelBooking,
              icon: Icon(
                Icons.cancel_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                appLocalization.cancelBooking,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      );
    });
  }
}

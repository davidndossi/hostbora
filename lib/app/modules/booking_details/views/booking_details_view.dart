import 'package:flutter/material.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/booking_details_controller.dart';

class BookingDetailsView extends BaseView<BookingDetailsController> {
  BookingDetailsView({super.key});

  static const _cardDark = Color(0xFF2A2A2A);

  @override
  Color pageBackgroundColor(BuildContext context) => AppColors.designBackgroundDark;

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
    return Column(
      children: [
        _buildHeader(context, topPadding),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGuestCard(context),
                const SizedBox(height: 16),
                _buildCheckInOutRow(context),
                const SizedBox(height: 20),
                _buildPaymentRow(context),
                const SizedBox(height: 24),
                _buildSectionLabel('RESERVATION DETAILS'),
                const SizedBox(height: 16),
                _buildMessageGuestButton(context),
                const SizedBox(height: 12),
                _buildModifyBookingLink(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double topPadding) {
    final height = MediaQuery.sizeOf(context).height * 0.38;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            controller.propertyImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: _cardDark,
              child: const Icon(Icons.home_work_outlined, size: 64, color: Colors.white54),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.75),
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
                  controller.propertyTitle,
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
                      controller.propertyLocation,
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
    );
  }

  Widget _headerIconButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.25),
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
        color: _cardDark,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.designAccent.withOpacity(0.3),
            backgroundImage: controller.guestAvatarUrl.isNotEmpty
                ? NetworkImage(controller.guestAvatarUrl)
                : null,
            child: controller.guestAvatarUrl.isEmpty
                ? Text(
                    controller.guestName.isNotEmpty
                        ? controller.guestName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
                      '${controller.guestRating} (${controller.guestReviewCount} reviews)',
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
                  border: Border.all(color: AppColors.designAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 22,
                  color: AppColors.designAccent,
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
            label: 'CHECK-IN',
            date: controller.checkInDate,
            time: controller.checkInTime,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateCard(
            label: 'CHECK-OUT',
            date: controller.checkOutDate,
            time: controller.checkOutTime,
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard({
    required String label,
    required String date,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
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
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
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
                'Payment Status',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.designAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'PAID',
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
                'Total Payout',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.totalPayout,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.designAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.white.withOpacity(0.6),
      ),
    );
  }

  Widget _buildMessageGuestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.messageGuest,
        icon: const Icon(Icons.mail_outline, size: 22, color: Colors.white),
        label: const Text('Message Guest'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.designAccent,
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
          'Modify Booking',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

}
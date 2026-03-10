import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/widget/custom_app_bar.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/add_new_booking_controller.dart';

const _bookingNavTeal = Color(0xFF1E8877);

class AddNewBookingView extends BaseView<AddNewBookingController> {
  AddNewBookingView({super.key});

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textColorPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.designPlaceholder),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Obx(() {
      final isSaving = controller.saving.value;
      return SizedBox(
        width: double.infinity,
        height: AppValues.formButtonHeight + 4,
        child: ElevatedButton.icon(
          onPressed: isSaving ? null : controller.saveBooking,
          icon: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.calendar_today, size: 20, color: Colors.white),
          label: Text(
            isSaving ? 'Saving…' : 'Save Booking',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _bookingNavTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppValues.radius_6),
            ),
            elevation: 0,
          ),
        ),
      );
    });
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.addBooking,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final pending = controller.pendingCount.value;
              final syncing = controller.syncing.value;
              if (pending > 0) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.colorPrimaryLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                    border: Border.all(color: AppColors.colorPrimary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        syncing ? Icons.sync : Icons.cloud_off_outlined,
                        size: 22,
                        color: AppColors.colorPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          syncing
                              ? 'Syncing offline bookings…'
                              : '$pending booking${pending == 1 ? '' : 's'} saved offline. Will sync when online.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            _buildLabel('Guest Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.guestNameController,
              decoration: _inputDecoration(hint: "Enter guest's full name"),
              validator: (v) =>
              (v == null || v.trim().isEmpty)
                  ? 'Guest name is required'
                  : null,
            ),
            const SizedBox(height: 20),
            _buildLabel('Phone Number'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.guestPhoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(hint: 'e.g. 255 712 345 678').copyWith(
                suffixIcon: Icon(
                  Icons.phone_outlined,
                  size: 22,
                  color: AppColors.designPlaceholder,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (!controller.isAzamPayEnabled) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: controller.sendPushToPay.value,
                          onChanged: (v) =>
                              controller.setSendPushToPay(v ?? false),
                          activeColor: _bookingNavTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setSendPushToPay(
                            !controller.sendPushToPay.value,
                          ),
                          child: _buildLabel(
                            'Send Push to Pay to guest (AzamPay)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (controller.sendPushToPay.value) ...[
                    const SizedBox(height: 12),
                    _buildLabel('Amount (TZS)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.pushToPayAmountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(hint: 'e.g. 50000'),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Mobile provider'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: controller.selectedProvider.value,
                      decoration: _inputDecoration(hint: 'Provider').copyWith(
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.designPlaceholder,
                        ),
                      ),
                      isExpanded: true,
                      items: azamPayProviders
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: controller.selectProvider,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A payment request will be sent to the guest\'s phone.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.designPlaceholder,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 20),
                ],
              );
            }),
            _buildLabel('Select Property'),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.listingsLoading.value) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.colorWhite,
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                    border: Border.all(color: AppColors.designInputBorder),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Loading properties…',
                        style: TextStyle(
                          color: AppColors.designPlaceholder,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                );
              }
              return DropdownButtonFormField<String>(
                value: controller.selectedListingId.value,
                decoration: _inputDecoration(hint: 'Choose a listing').copyWith(
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.designPlaceholder,
                  ),
                ),
                hint: const Text(
                  'Choose a listing',
                  style: TextStyle(
                    color: AppColors.designPlaceholder,
                    fontSize: 16,
                  ),
                ),
                icon: const SizedBox.shrink(),
                isExpanded: true,
                items: controller.listings
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.id,
                        child: Text(e.propertyName),
                      ),
                    )
                    .toList(),
                onChanged: controller.selectProperty,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please select a property' : null,
              );
            }),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Check-in Date'),
                      const SizedBox(height: 8),
                      _DateField(
                        label: controller.checkInLabel,
                        onTap: controller.pickCheckIn,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Check-out Date'),
                      const SizedBox(height: 8),
                      _DateField(
                        label: controller.checkOutLabel,
                        onTap: controller.pickCheckOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel('Number of Guests'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.numberOfGuestsController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hint: 'e.g. 2').copyWith(
                suffixIcon: Icon(
                  Icons.people_outline,
                  size: 22,
                  color: AppColors.designPlaceholder,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Number of guests is required';
                }
                final n = int.tryParse(v.trim());
                if (n == null || n < 1) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Notes'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.notesController,
              maxLines: 3,
              decoration: _inputDecoration(
                hint: 'Any special requests or details...',
              ),
            ),
            const SizedBox(height: 28),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.colorWhite,
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: Border.all(color: AppColors.designInputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: label == 'Select date'
                        ? AppColors.designPlaceholder
                        : AppColors.textColorPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.designPlaceholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
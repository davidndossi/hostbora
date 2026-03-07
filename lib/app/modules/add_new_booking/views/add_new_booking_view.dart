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
    return SizedBox(
      width: double.infinity,
      height: AppValues.formButtonHeight + 4,
      child: ElevatedButton.icon(
        onPressed: controller.saveBooking,
        icon: const Icon(Icons.calendar_today, size: 20, color: Colors.white),
        label: const Text(
          'Save Booking',
          style: TextStyle(
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
            _buildLabel('Select Property'),
            const SizedBox(height: 8),
            Obx(
                  () => DropdownButtonFormField<String>(
                value: controller.selectedProperty.value,
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
                items: controller.propertyOptions
                    .map(
                      (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                    .toList(),
                onChanged: controller.selectProperty,
                validator: (v) =>
                v == null || v.isEmpty ? 'Please select a property' : null,
              ),
            ),
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
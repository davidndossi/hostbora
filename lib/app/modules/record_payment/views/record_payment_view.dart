import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/record_payment_controller.dart';

const _transactionTeal = Color(0xFF1E8877);

class RecordPaymentView extends BaseView<RecordPaymentController> {
  RecordPaymentView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.transaction,
      isCentered: true,
      actions: [
        IconButton(
          onPressed: () => Get.toNamed(Routes.SETTINGS),
          icon: const Icon(Icons.more_vert_outlined)
        )
      ],
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
            const Text(
              'Record New Payment',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log a payment received from a guest for your property.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textColorSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration(hint: '0.00').copyWith(
                prefixText: 'TZS ',
                prefixStyle: const TextStyle(
                  color: AppColors.designPlaceholder,
                  fontSize: 16,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                final cleaned = v.replaceFirst(RegExp(r'^(TZS|\$)\s*'), '').trim();
                final n = double.tryParse(cleaned);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Payment Method'),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedPaymentMethod.value,
                decoration: _inputDecoration(hint: 'Select method').copyWith(
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.designPlaceholder,
                  ),
                ),
                icon: const SizedBox.shrink(),
                isExpanded: true,
                items: controller.paymentMethods
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: controller.selectPaymentMethod,
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Linked Booking'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.linkedBookingController,
              decoration: _inputDecoration(
                hint: 'Search guest name or booking ID...',
              ).copyWith(
                prefixIcon: Icon(
                  Icons.search,
                  size: 22,
                  color: AppColors.designPlaceholder,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Payment Date'),
            const SizedBox(height: 8),
            _DateField(
              label: controller.paymentDateLabel,
              onTap: controller.pickPaymentDate,
            ),
            const SizedBox(height: 20),
            _buildLabel('Status'),
            const SizedBox(height: 8),
            Obx(() => _buildStatusToggle(context)),
            const SizedBox(height: 28),
            _buildRecordButton(context),
          ],
        ),
      ),
    );
  }

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

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.designPlaceholder),
      prefixIcon: prefixIcon,
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

  Widget _buildStatusToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusChip(
            label: 'Paid',
            isSelected: controller.status.value == PaymentStatus.paid,
            icon: Icons.check,
            onTap: () => controller.setStatus(PaymentStatus.paid),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusChip(
            label: 'Pending',
            isSelected: controller.status.value == PaymentStatus.pending,
            onTap: () => controller.setStatus(PaymentStatus.pending),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton(BuildContext context) {
    return Obx(() {
      final isSaving = controller.saving.value;
      return SizedBox(
        width: double.infinity,
        height: AppValues.formButtonHeight + 4,
        child: ElevatedButton.icon(
          onPressed: isSaving ? null : controller.recordPayment,
          icon: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
          label: Text(
            isSaving ? 'Recording…' : 'Record Payment',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _transactionTeal,
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textColorPrimary,
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

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? _transactionTeal : AppColors.lightGreyColor.withOpacity(0.4),
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && isSelected) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textColorSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

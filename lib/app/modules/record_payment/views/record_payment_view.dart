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

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.transaction,
      isCentered: true,
      actions: [
        IconButton(
          onPressed: () => Get.toNamed(Routes.SETTINGS),
          icon: const Icon(Icons.more_vert_outlined),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    final isDark = _isDark(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(context, en: 'Record New Payment', sw: 'Rekodi Malipo Mapya'),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                context,
                en: 'Log a payment received from a guest for your property.',
                sw: 'Andika malipo yaliyopokelewa kutoka kwa mgeni wa mali yako.',
              ),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : AppColors.textColorSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel(context, _t(context, en: 'Amount', sw: 'Kiasi')),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(context, hint: '0.00').copyWith(
                prefixText: 'TZS ',
                prefixStyle: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.designPlaceholder,
                  fontSize: 16,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return _t(
                    context,
                    en: 'Amount is required',
                    sw: 'Kiasi kinahitajika',
                  );
                }
                final cleaned = v
                    .replaceFirst(RegExp(r'^(TZS|\$)\s*'), '')
                    .trim();
                final n = double.tryParse(cleaned);
                if (n == null || n <= 0) {
                  return _t(
                    context,
                    en: 'Enter a valid amount',
                    sw: 'Weka kiasi sahihi',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel(
              context,
              _t(context, en: 'Payment Method', sw: 'Njia ya Malipo'),
            ),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.selectedPaymentMethod.value,
                decoration:
                    _inputDecoration(
                      context,
                      hint: _t(context, en: 'Select method', sw: 'Chagua njia'),
                    ).copyWith(
                      suffixIcon: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark
                            ? Colors.white70
                            : AppColors.designPlaceholder,
                      ),
                    ),
                icon: const SizedBox.shrink(),
                isExpanded: true,
                items: controller.paymentMethods
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: controller.selectPaymentMethod,
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel(
              context,
              _t(context, en: 'Linked Booking', sw: 'Uhifadhi Uliounganishwa'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.linkedBookingController,
              decoration:
                  _inputDecoration(
                    context,
                    hint: _t(
                      context,
                      en: 'Search guest name or booking ID...',
                      sw: 'Tafuta jina la mgeni au ID ya uhifadhi...',
                    ),
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.search,
                      size: 22,
                      color: isDark
                          ? Colors.white70
                          : AppColors.designPlaceholder,
                    ),
                  ),
            ),
            const SizedBox(height: 20),
            _buildLabel(
              context,
              _t(context, en: 'Payment Date', sw: 'Tarehe ya Malipo'),
            ),
            const SizedBox(height: 8),
            _DateField(
              label: controller.paymentDateLabel,
              onTap: controller.pickPaymentDate,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _buildLabel(context, _t(context, en: 'Status', sw: 'Hali')),
            const SizedBox(height: 8),
            Obx(() => _buildStatusToggle(context)),
            const SizedBox(height: 28),
            _buildRecordButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    Widget? prefixIcon,
  }) {
    final isDark = _isDark(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white70 : AppColors.designPlaceholder,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.designInputBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.designInputBorder,
        ),
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
            label: _t(context, en: 'Paid', sw: 'Imelipwa'),
            isSelected: controller.status.value == PaymentStatus.paid,
            icon: Icons.check,
            onTap: () => controller.setStatus(PaymentStatus.paid),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusChip(
            label: _t(context, en: 'Pending', sw: 'Inasubiri'),
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
              : const Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: Colors.white,
                ),
          label: Text(
            isSaving
                ? _t(context, en: 'Recording...', sw: 'Inarekodiwa...')
                : _t(context, en: 'Record Payment', sw: 'Rekodi Malipo'),
            style: TextStyle(
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
  final bool isDark;

  const _DateField({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.designInputBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: isDark ? Colors.white70 : AppColors.designPlaceholder,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isSelected
          ? _transactionTeal
          : (isDark
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.lightGreyColor.withValues(alpha: 0.4)),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? Colors.white70
                            : AppColors.textColorSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

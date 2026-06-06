import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../../routes/app_pages.dart';
import '../../rent/staff_management/controllers/rent_staff_management_controller.dart';
import '../../rent/staff_management/utils/rent_staff_pay_format.dart';

/// Staff registry + payroll block (from rent staff management) for listing tabs.
class ListingDetailsStaffPanel extends StatelessWidget {
  const ListingDetailsStaffPanel({
    super.key,
    required this.isSw,
    required this.compactListOnly,
    this.showPayrollSummary = true,
    this.onStaffChanged,
  });

  final bool isSw;
  final bool compactListOnly;
  final bool showPayrollSummary;
  final VoidCallback? onStaffChanged;

  String _t(String en, String sw) => isSw ? sw : en;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RentStaffManagementController>();
    final textColor = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).hintColor;

    if (compactListOnly) {
      return Obx(() {
        final staff = c.staff;
        if (staff.isEmpty) {
          return Text(
            _t('No staff assigned yet.', 'Hakuna wafanyakazi bado.'),
            style: TextStyle(fontSize: 14, color: muted),
          );
        }
        return Column(
          children: staff
              .map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.colorPrimary.withValues(alpha: 0.12),
                    child: Text(
                      s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                  ),
                  title: Text(s.name, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                  subtitle: Text(
                    s.jobTitle.isEmpty ? s.payAmountLabel : '${s.jobTitle} · ${s.payAmountLabel}',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () {
                      c.editStaff(s);
                      onStaffChanged?.call();
                    },
                  ),
                ),
              )
              .toList(),
        );
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Inputs need a fill that contrasts with white cards in light mode.
    final inputFill = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFF2F2F2);
    final inputBorder = isDark
        ? const Color(0xFF4A4A4C)
        : const Color(0xFFD9D9D9);
    final cardBg = isDark
        ? const Color(0xFF2C2C2E)
        : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFFE6E1D7);

    InputDecoration inputDeco(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.colorPrimary,
              width: 1.5,
            ),
          ),
          labelStyle: TextStyle(color: muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        );

    return Obx(() {
      if (c.initialLoad.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPayrollSummary) ...[
            _payrollSummary(c),
            const SizedBox(height: 16),
          ],

          // ── Add staff form card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Form(
              key: c.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.colorPrimary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 18,
                          color: AppColors.colorPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _t('New staff member', 'Mfanyakazi mpya'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: c.fullNameController,
                    decoration: inputDeco(_t('Full name', 'Jina kamili')),
                    validator: c.validateFullName,
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue:
                          RentStaffPayFormat.paymentTypeLabels.containsKey(
                                c.paymentType.value,
                              )
                              ? c.paymentType.value
                              : RentStaffPayFormat.monthly,
                      decoration: inputDeco(
                        _t('Pay type', 'Aina ya malipo'),
                      ),
                      items: RentStaffPayFormat.paymentTypeLabels.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: c.updatePaymentType,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Obx(
                          () => TextFormField(
                            controller: c.amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: inputDeco(c.amountFieldLabel),
                            validator: c.validateAmount,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: c.payDateController,
                          keyboardType: TextInputType.number,
                          decoration: inputDeco(
                            _t('Pay day', 'Siku ya malipo'),
                          ),
                          validator: c.validatePayDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: c.selectedPrimaryRole.value.isEmpty
                          ? null
                          : (RentStaffManagementController.primaryRoleOptions
                                  .contains(c.selectedPrimaryRole.value)
                              ? c.selectedPrimaryRole.value
                              : null),
                      decoration: inputDeco(
                        _t('Primary role', 'Jukumu la msingi'),
                      ),
                      items: RentStaffManagementController.primaryRoleOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: c.updatePrimaryRole,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await c.registerStaff();
                        onStaffChanged?.call();
                      },
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        backgroundColor: AppColors.colorPrimary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _t('Register staff member', 'Sajili mfanyakazi'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Active team list ──────────────────────────────────────────
          Text(
            _t('Active team', 'Timu hai'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          ListingDetailsStaffPanel(
            isSw: isSw,
            compactListOnly: true,
            onStaffChanged: onStaffChanged,
          ),
        ],
      );
    });
  }

  Widget _payrollSummary(RentStaffManagementController c) {
    final total = c.totalMonthlySalaryPool;
    return Material(
      color: AppColors.colorPrimary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Get.toNamed(Routes.RENT_STAFF_PAYROLL_DETAILS)?.then((_) => c.loadStaff()),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Total staff payroll', 'Jumla ya mishahara'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                RentStaffPayFormat.formatPayrollTotal(total),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

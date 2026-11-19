import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../../routes/app_pages.dart';
import '../../rent/staff_management/controllers/rent_staff_management_controller.dart';
import '../../rent/staff_management/utils/rent_staff_pay_format.dart';
import '../../rent/staff_management/widgets/staff_access_editor.dart';
import '../../rent/staff_management/widgets/staff_option_sheet_field.dart';

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

    InputDecoration inputDeco(String label, {int errorMaxLines = 3}) =>
        InputDecoration(
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
          errorMaxLines: errorMaxLines,
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

          // ── Add / edit staff form card ────────────────────────────────
          Container(
            key: c.formSectionKey,
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
                  Obx(() {
                    final editing = c.isEditMode;
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.colorPrimary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            editing
                                ? Icons.edit_outlined
                                : Icons.person_add_alt_1_outlined,
                            size: 18,
                            color: AppColors.colorPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            editing
                                ? _t('Edit staff member', 'Hariri mfanyakazi')
                                : _t('New staff member', 'Mfanyakazi mpya'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (editing)
                          TextButton(
                            onPressed: c.cancelEdit,
                            child: Text(_t('Cancel', 'Ghairi')),
                          ),
                      ],
                    );
                  }                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => StaffAccessEditor(
                      role: c.permissionRole.value,
                      permissions: c.grantedPermissions.toSet(),
                      allProperties: c.allPropertiesAccess.value,
                      propertyRefs: c.selectedPropertyRefs.toSet(),
                      properties: c.accessProperties.toList(),
                      legacy: c.legacyStaffAccess.value,
                      accent: AppColors.colorPrimary,
                      onRoleChanged: c.applyPermissionRole,
                      onPermissionToggled: c.togglePermission,
                      onAllPropertiesChanged: c.setAllPropertiesAccess,
                      onPropertyToggled: c.togglePropertyRef,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: c.fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: inputDeco(_t('Full name', 'Jina kamili')),
                    validator: c.validateFullName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: c.phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: inputDeco(_t('Phone', 'Simu')),
                    validator: c.validatePhone,
                    autovalidateMode: AutovalidateMode.onUnfocus,
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => StaffOptionSheetField(
                      key: ValueKey('pay-${c.editingStaffId.value}'),
                      value: RentStaffPayFormat.paymentTypeLabels.containsKey(
                            c.paymentType.value,
                          )
                          ? c.paymentType.value
                          : RentStaffPayFormat.monthly,
                      decoration: inputDeco(
                        _t('Pay type', 'Aina ya malipo'),
                      ),
                      sheetTitle: _t('Pay type', 'Aina ya malipo'),
                      options: [
                        for (final entry
                            in RentStaffPayFormat.paymentTypeLabels.entries)
                          StaffSheetOption(value: entry.key, label: entry.value),
                      ],
                      onChanged: (value) => c.updatePaymentType(value),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Full-width fields so Pay day validation errors are not
                  // clipped in a narrow side-by-side column.
                  Obx(
                    () => TextFormField(
                      controller: c.amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: inputDeco(c.amountFieldLabel),
                      validator: c.validateAmount,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: c.payDateController,
                    keyboardType: TextInputType.number,
                    decoration: inputDeco(
                      _t('Pay day (1–31)', 'Siku ya malipo (1–31)'),
                    ),
                    validator: c.validatePayDate,
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () {
                      final role = c.selectedPrimaryRole.value;
                      final opts =
                          RentStaffManagementController.primaryRoleOptions;
                      return StaffOptionSheetField(
                        key: ValueKey('role-${c.editingStaffId.value}'),
                        value: role.isEmpty || !opts.contains(role) ? null : role,
                        decoration: inputDeco(
                          _t('Primary role', 'Jukumu la msingi'),
                        ),
                        hint: _t('Select a role...', 'Chagua jukumu...'),
                        sheetTitle: _t('Select a role', 'Chagua jukumu'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? _t(
                                'Select a primary role',
                                'Chagua jukumu la msingi',
                              )
                            : null,
                        options: [
                          for (final option in opts)
                            StaffSheetOption(value: option, label: option),
                        ],
                        onChanged: (value) => c.updatePrimaryRole(value),
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  Obx(
                    () => SizedBox(
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
                        icon: Icon(
                          c.isEditMode
                              ? Icons.save_outlined
                              : Icons.check_outlined,
                          size: 18,
                        ),
                        label: Text(
                          c.isEditMode
                              ? _t('Update staff member', 'Sasisha mfanyakazi')
                              : _t(
                                  'Register staff member',
                                  'Sajili mfanyakazi',
                                ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
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
              fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w600,
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

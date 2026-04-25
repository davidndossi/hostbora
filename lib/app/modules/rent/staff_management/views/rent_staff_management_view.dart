import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_staff_management_controller.dart';
import '../utils/rent_staff_pay_format.dart';

class _StaffUi {
  _StaffUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);

  bool get dark => _t.brightness == Brightness.dark;

  static const Color teal = RentTheme.conciergeTeal;

  Color get brandTeal => dark ? const Color(0xFF4DB6AC) : teal;

  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);

  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);

  Color get labelCaps => dark ? const Color(0xFF98989D) : const Color(0xFF616161);

  Color get fieldFill => dark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1);

  Color get card => _t.cardColor;

  Color get border => dark ? const Color(0xFF48484A) : const Color(0xFFE5E7EB);

  Color get payAmount => dark ? const Color(0xFFF2F2F7) : const Color(0xFF1F2937);

  Color get complianceBg => dark ? const Color(0xFF2C2820) : const Color(0xFFF5F0E8);

  Color get complianceTitle => dark ? const Color(0xFFFFCC80) : const Color(0xFF4E342E);

  Color get complianceBody => dark ? const Color(0xFFD7CCC8) : const Color(0xFF5D4037);

  Color get complianceIcon => dark ? const Color(0xFFFFAB91) : const Color(0xFF6D4C41);

  Color get upcomingBg => dark ? const Color(0xFF1B2E2D) : const Color(0xFFE8F6F5);

  Color get upcomingBody => dark ? const Color(0xFFB0BEC5) : const Color(0xFF1F2937);

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Concierge **Staff Registry** — form, payroll summary, active team list.
class RentStaffManagementView extends BaseView<RentStaffManagementController> {
  RentStaffManagementView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return rentAppBar(
      _isSw ? 'Wafanyakazi' : 'Staff',
    );
  }

  @override
  Widget body(BuildContext context) {
    final u = _StaffUi(context);
    return Obx(() {
      if (controller.initialLoad.value) {
        return Center(child: CircularProgressIndicator(color: u.brandTeal));
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSw ? 'Usajili wa Wafanyakazi' : 'Staff Registry',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: u.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSw ? 'Dumisha ubora wa mali yako kwa kuajiri na kudhibiti washiriki wa timu yako ya huduma waliojitolea hapa.' : 'Maintain the excellence of your estate by onboarding and managing your dedicated service team members here.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: u.muted,
              ),
            ),
            const SizedBox(height: 22),
            _newStaffMemberCard(u),
            const SizedBox(height: 18),
            _payrollSummaryCard(u),
            const SizedBox(height: 20),
            _activeTeamHeader(u),
            const SizedBox(height: 12),
            if (controller.staff.isEmpty) _emptyTeamHint(u) else _staffList(u),
            const SizedBox(height: 22),
            _complianceCard(u),
            const SizedBox(height: 12),
            _upcomingPayrollCard(u),
          ],
        ),
      );
    });
  }

  Widget _newStaffMemberCard(_StaffUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.cardShadow,
        border: u.dark ? Border.all(color: u.border.withValues(alpha: 0.55)) : null,
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: u.brandTeal.withValues(alpha: 0.95), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isSw ? 'Mfanyakazi Mpya' : 'New Staff Member',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: u.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _capsLabel(u, 'FULL NAME'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.fullNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: controller.validateFullName,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: TextStyle(color: u.onSurface, fontWeight: FontWeight.w500),
              cursorColor: u.brandTeal,
              decoration: _fieldDeco(u, hint: 'e.g. Zainab Hussein'),
            ),
            const SizedBox(height: 14),
            _capsLabel(u, 'PAY TYPE'),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: RentStaffPayFormat.paymentTypeLabels.containsKey(controller.paymentType.value)
                    ? controller.paymentType.value
                    : RentStaffPayFormat.monthly,
                decoration: _dropdownDeco(u),
                dropdownColor: u.card,
                style: TextStyle(color: u.onSurface, fontWeight: FontWeight.w500, fontSize: 15),
                icon: Icon(Icons.expand_more_rounded, color: u.onSurface),
                items: RentStaffPayFormat.paymentTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: controller.updatePaymentType,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _capsLabel(u, controller.amountFieldLabel),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller.amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          validator: controller.validateAmount,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          style: TextStyle(color: u.onSurface, fontWeight: FontWeight.w500),
                          cursorColor: u.brandTeal,
                          decoration: _fieldDeco(
                            u,
                            hint: controller.amountHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _capsLabel(u, 'PAYMENT DATE'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.payDateController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: controller.validatePayDate,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        style: TextStyle(color: u.onSurface, fontWeight: FontWeight.w500),
                        cursorColor: u.brandTeal,
                        decoration: _fieldDeco(u, hint: '28'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _capsLabel(u, 'PRIMARY ROLE'),
            const SizedBox(height: 8),
            Obx(
              () {
                final role = controller.selectedPrimaryRole.value;
                final opts = RentStaffManagementController.primaryRoleOptions;
                return DropdownButtonFormField<String>(
                  initialValue: role.isEmpty ? null : (opts.contains(role) ? role : null),
                  decoration: _dropdownDeco(u),
                  dropdownColor: u.card,
                  style: TextStyle(color: u.onSurface, fontWeight: FontWeight.w500, fontSize: 15),
                  icon: Icon(Icons.expand_more_rounded, color: u.onSurface),
                  hint: Text(
                    _isSw ? 'Chagua jukumu...' : 'Select a role...',
                    style: TextStyle(color: u.muted),
                  ),
                  isExpanded: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => (value == null || value.isEmpty)
                      ? (_isSw ? 'Chagua jukumu la msingi' : 'Select a primary role')
                      : null,
                  items: opts
                      .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  onChanged: controller.updatePrimaryRole,
                );
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.registerStaff,
                style: FilledButton.styleFrom(
                  backgroundColor: _StaffUi.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isSw ? 'SAJILI MTAFANYAKAZI' : 'REGISTER STAFF MEMBER',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payrollSummaryCard(_StaffUi u) {
    return Obx(() {
      final total = controller.totalMonthlySalaryPool;
      final nMonthly = controller.monthlyContractCount;
      final nAll = controller.staff.length;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _StaffUi.teal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: u.dark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOTAL STAFF PAYROLL',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              RentStaffPayFormat.formatPayrollTotal(total),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nMonthly > 0
                  ? (_isSw
                      ? 'Mikataba ya mishahara ya mwezi: $nMonthly · $nAll mwanatimu hai${nAll == 1 ? '' : ''}'
                      : 'Monthly salary contracts: $nMonthly · $nAll active team member${nAll == 1 ? '' : 's'}')
                  : (nAll == 0
                      ? (_isSw ? 'Sajili wafanyakazi kufuatilia mishahara' : 'Register staff to track payroll')
                      : (_isSw
                          ? 'Bado hakuna mikataba ya mwezi — viwango vya saa/kazi kwa kila mtu vimeorodheshwa.'
                          : 'No monthly contracts yet — hourly / per-job rates listed per person')),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _activeTeamHeader(_StaffUi u) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: Text(
              _isSw ? 'Timu Hai ya Huduma' : 'Active Service Team',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: u.onSurface),
            ),
          ),
          Text(
            '${controller.staff.length} PERSONNEL',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: u.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTeamHint(_StaffUi u) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          _isSw ? 'Bado hakuna wafanyakazi waliosajiliwa — tumia fomu hapo juu.' : 'No staff registered yet — use the form above.',
          style: TextStyle(color: u.muted, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _staffList(_StaffUi u) {
    return Obx(
      () => Column(
        children: controller.staff.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _staffTile(u, m),
            )).toList(),
      ),
    );
  }

  Widget _staffTile(_StaffUi u, RentStaffListItem m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.cardShadow,
        border: u.dark ? Border.all(color: u.border.withValues(alpha: 0.5)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: u.brandTeal.withValues(alpha: u.dark ? 0.22 : 0.12),
          backgroundImage: null,
          child: Text(
            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: u.brandTeal.withValues(alpha: 0.95),
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          m.name,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: u.onSurface),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            m.jobTitle,
            style: TextStyle(color: u.muted, fontSize: 13),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  m.payAmountLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: u.payAmount,
                  ),
                ),
                if (m.payDayDisplay.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    m.payDayDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: u.muted,
                    ),
                  ),
                ],
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: u.muted),
              padding: EdgeInsets.zero,
              color: u.card,
              onSelected: (value) {
                if (value == 'edit') {
                  controller.editStaff(m);
                } else if (value == 'remove') {
                  controller.removeStaff(m.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(_isSw ? 'Hariri' : 'Edit')),
                PopupMenuItem(value: 'remove', child: Text(_isSw ? 'Ondoa' : 'Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _complianceCard(_StaffUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.complianceBg,
        borderRadius: BorderRadius.circular(14),
        border: u.dark ? Border.all(color: u.complianceIcon.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: u.complianceIcon, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw ? 'Kumbukumbu ya Uzingatiaji' : 'Compliance Note',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: u.complianceTitle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSw
                      ? 'Hifadhi rekodi za ajira na makubaliano ya usiri kwenye faili kwa kila mwanatimu.'
                      : 'Keep employment records and confidentiality agreements on file for each team member.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: u.complianceBody),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingPayrollCard(_StaffUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.upcomingBg,
        borderRadius: BorderRadius.circular(14),
        border: u.dark ? Border.all(color: u.brandTeal.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_month_outlined, color: u.brandTeal.withValues(alpha: 0.9), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw ? 'Mishahara Inayokuja' : 'Upcoming Payroll',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: u.brandTeal.withValues(alpha: 0.98),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSw
                      ? 'Malipo hufuata tarehe za malipo ulizoweka kwa kila mfanyakazi.'
                      : 'Disbursements follow the payment dates you set for each staff member.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: u.upcomingBody),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capsLabel(_StaffUi u, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
        color: u.labelCaps,
      ),
    );
  }

  InputDecoration _fieldDeco(_StaffUi u, {required String hint}) {
    return InputDecoration(
      filled: true,
      fillColor: u.fieldFill,
      hintText: hint,
      hintStyle: TextStyle(color: u.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: u.border.withValues(alpha: u.dark ? 0.45 : 0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: u.brandTeal, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  InputDecoration _dropdownDeco(_StaffUi u) {
    return InputDecoration(
      filled: true,
      fillColor: u.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: u.border.withValues(alpha: u.dark ? 0.45 : 0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: u.brandTeal, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

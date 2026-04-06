import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_staff_management_controller.dart';
import '../utils/rent_staff_pay_format.dart';

/// Concierge **Staff Registry** — form, payroll summary, active team list.
class RentStaffManagementView extends BaseView<RentStaffManagementController> {
  RentStaffManagementView({super.key});

  static const _teal = RentTheme.conciergeTeal;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return rentAppBar(
      'Staff Registry',
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.person_add_alt_1, color: _teal),
      //     onPressed: () {},
      //   ),
      // ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.initialLoad.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            _newStaffMemberCard(),
            const SizedBox(height: 18),
            _payrollSummaryCard(),
            const SizedBox(height: 20),
            _activeTeamHeader(),
            const SizedBox(height: 12),
            if (controller.staff.isEmpty) _emptyTeamHint() else _staffList(),
            const SizedBox(height: 22),
            _complianceCard(),
            const SizedBox(height: 12),
            _upcomingPayrollCard(),
          ],
        ),
      );
    });
  }

  Widget _newStaffMemberCard() {
    const fill = Color(0xFFF1F1F1);
    return rentCard(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: _teal.withValues(alpha: 0.9), size: 22),
              const SizedBox(width: 8),
              const Text(
                'New Staff Member',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _capsLabel('FULL NAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.fullNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: controller.validateFullName,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _fieldDeco(fill, hint: 'e.g. Zainab Hussein'),
          ),
          const SizedBox(height: 14),
          _capsLabel('PAY TYPE'),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: RentStaffPayFormat.paymentTypeLabels.containsKey(controller.paymentType.value)
                  ? controller.paymentType.value
                  : RentStaffPayFormat.monthly,
              decoration: _dropdownDeco(fill),
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
                      _capsLabel(controller.amountFieldLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        validator: controller.validateAmount,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _fieldDeco(
                          fill,
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
                    _capsLabel('PAYMENT DATE'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.payDateController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: controller.validatePayDate,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _fieldDeco(fill, hint: '28'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _capsLabel('PRIMARY ROLE'),
          const SizedBox(height: 8),
          Obx(
            () {
              final role = controller.selectedPrimaryRole.value;
              final opts = RentStaffManagementController.primaryRoleOptions;
              return DropdownButtonFormField<String>(
                initialValue: role.isEmpty ? null : (opts.contains(role) ? role : null),
                decoration: _dropdownDeco(fill),
                hint: const Text('Select a role...', style: TextStyle(color: Color(0xFF9CA3AF))),
                isExpanded: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => (value == null || value.isEmpty) ? 'Select a primary role' : null,
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
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'REGISTER STAFF MEMBER',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.6),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _payrollSummaryCard() {
    return Obx(() {
      final total = controller.totalMonthlySalaryPool;
      final nMonthly = controller.monthlyContractCount;
      final nAll = controller.staff.length;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(16),
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
                  ? 'Monthly salary contracts: $nMonthly · $nAll active team member${nAll == 1 ? '' : 's'}'
                  : (nAll == 0
                      ? 'Register staff to track payroll'
                      : 'No monthly contracts yet — hourly / per-job rates listed per person'),
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

  Widget _activeTeamHeader() {
    return Obx(
      () => Row(
        children: [
          const Expanded(
            child: Text(
              'Active Service Team',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          Text(
            '${controller.staff.length} PERSONNEL',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTeamHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'No staff registered yet — use the form above.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _staffList() {
    return Obx(
      () => Column(
        children: controller.staff.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _staffTile(m),
            )).toList(),
      ),
    );
  }

  Widget _staffTile(RentStaffListItem m) {
    return rentCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: _teal.withValues(alpha: 0.12),
          backgroundImage: null,
          child: Text(
            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _teal.withValues(alpha: 0.95),
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          m.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            m.jobTitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1F2937),
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') {
                  controller.editStaff(m);
                } else if (value == 'remove') {
                  controller.removeStaff(m.id);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _complianceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Colors.brown.shade600, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance Note',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.brown.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep employment records and confidentiality agreements on file for each team member.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Colors.brown.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingPayrollCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_month_outlined, color: _teal.withValues(alpha: 0.85), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Payroll',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _teal.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Disbursements follow the payment dates you set for each staff member.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capsLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _fieldDeco(Color fill, {required String hint}) {
    return InputDecoration(
      filled: true,
      fillColor: fill,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  InputDecoration _dropdownDeco(Color fill) {
    return InputDecoration(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

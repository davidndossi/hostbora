import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../controllers/rent_add_new_expense_controller.dart';

class RentAddNewExpenseView extends BaseView<RentAddNewExpenseController> {
  RentAddNewExpenseView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: 'Add Expense'
  );

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SizedBox(height: 14),
          _expenseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Select Property',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Obx(
                  () {
                    final hasProperties = controller.hasProperties;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: controller.propertyOptions.contains(controller.selectedProperty.value)
                              ? controller.selectedProperty.value
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Choose property',
                            border: InputBorder.none,
                          ),
                          validator: controller.validateSelectedProperty,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          items: controller.propertyOptions
                              .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                              .toList(),
                          onChanged: hasProperties ? controller.updateSelectedProperty : null,
                        ),
                        if (!hasProperties)
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 2),
                            child: Text(
                              'No properties yet - add property first.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _expenseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                Text('Select Category',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 10),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      controller.expenses.length,
                      (i) => _ExpenseChip(
                        label: controller.expenses[i],
                        selected: controller.selectedExpenseIndex.value == i,
                        onTap: () => controller.selectExpense(i),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _expenseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Amount (Tsh)',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 7),
                _field(
                  controller.amountController,
                  hint: 'Tsh 0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: controller.validateAmount,
                ),
                const SizedBox(height: 12),
                const Text('Transaction Date',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 7),
                _field(
                  controller.datePaidController,
                  hint: 'dd/MM/yyyy',
                  keyboardType: TextInputType.datetime,
                  suffix: Icons.calendar_month_rounded,
                  validator: controller.validateDatePaid,
                ),
                const SizedBox(height: 12),
                const Text('Select Tenant (Optional)',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 7),
                _field(
                  controller.tenantController,
                  hint: 'Global Expense (No Tenant)',
                  suffix: Icons.people_alt_outlined
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.saveExpenseOffline,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              label: const Text('Record Transaction',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          // const Text(
          //   'By recording this expense, you update the monthly operational report for The Concierge',
          //   style: TextStyle(fontSize: 9, height: 1.3, color: Color(0xFF8A8A8A)),
          // ),
          const SizedBox(height: 14),
          _expenseCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Context',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _StatBlock(label: 'BUDGET USED', value: '64%')),
                    Expanded(
                        child: _StatBlock(
                            label: 'STATUS',
                            value: 'Healthy',
                            alignEnd: true)),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(12),
          //   child: SizedBox(
          //     width: double.infinity,
          //     height: 210,
          //     child: Stack(
          //       fit: StackFit.expand,
          //       children: [
          //         Image.asset('images/luxury_room_view.png',
          //             fit: BoxFit.cover,
          //             errorBuilder: (context, error, stackTrace) =>
          //                 Container(color: const Color(0xFF334444))),
          //         Container(
          //           decoration: BoxDecoration(
          //             gradient: LinearGradient(
          //               begin: Alignment.topCenter,
          //               end: Alignment.bottomCenter,
          //               colors: [
          //                 Colors.black.withValues(alpha: 0.05),
          //                 Colors.black.withValues(alpha: 0.6),
          //               ],
          //             ),
          //           ),
          //         ),
          //         const Positioned(
          //           left: 12,
          //           right: 12,
          //           bottom: 12,
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Text('OPERATIONAL EXCELLENCE',
          //                   style: TextStyle(
          //                       color: Colors.white,
          //                       fontSize: 8,
          //                       letterSpacing: 1.8,
          //                       fontWeight: FontWeight.w700)),
          //               SizedBox(height: 4),
          //               Text(
          //                 'Invest in quality maintenance to preserve\nasset value.',
          //                 style: TextStyle(
          //                     color: Colors.white,
          //                     fontSize: 13,
          //                     height: 1.3,
          //                     fontWeight: FontWeight.w500),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 86),
        ],
        ),
      ),
    );
  }

  Widget _expenseCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _field(
      TextEditingController fieldController, {
        required String hint,
        IconData? suffix,
        bool isMultiline = false,
        double minHeight = 48,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    const textColor = Color(0xFF5B5B5B);
    final hintStyle = TextStyle(
      fontSize: 14,
      color: textColor.withValues(alpha: 0.72),
      height: isMultiline ? 1.35 : 1.2,
    );
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: fieldController,
        keyboardType: keyboardType ?? TextInputType.text,
        maxLines: isMultiline ? null : 1,
        minLines: isMultiline ? 3 : 1,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          height: isMultiline ? 1.35 : 1.25,
        ),
        decoration: InputDecoration(
          isDense: false,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: hintStyle,
          suffixIcon: suffix == null
              ? null
              : Padding(
            padding: EdgeInsets.only(left: 8, top: isMultiline ? 12 : 0),
            child: Icon(
              suffix,
              size: 20,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          suffixIconConstraints: BoxConstraints(
            minWidth: suffix != null ? 40 : 0,
            minHeight: suffix != null ? (isMultiline ? 52 : 40) : 0,
          ),
        ),
      ),
    );
  }
}

class _ExpenseChip extends StatelessWidget {
  const _ExpenseChip({
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    //   decoration: BoxDecoration(
    //     color: selected ? const Color(0xFF005D5D) : const Color(0xFFF1F1EE),
    //     borderRadius: BorderRadius.circular(8),
    //   ),
    //   child: Text(label,
    //       style: TextStyle(
    //           fontSize: 14,
    //           fontWeight: FontWeight.w600,
    //           color: selected ? Colors.white : const Color(0xFF353535))),
    // );
    final bg = selected ? const Color(0xFF006D73) : const Color(0xFFF1F1EE);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        splashColor: selected ? Colors.white24 : Colors.black12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1E1E1E),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock(
      {required this.label, required this.value, this.alignEnd = false});
  final String label;
  final String value;
  final bool alignEnd;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8B8B8B),
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: value == 'Healthy'
                ? const Color(0xFF006D73)
                : const Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}

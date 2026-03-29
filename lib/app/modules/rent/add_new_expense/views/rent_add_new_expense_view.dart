import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../controllers/rent_add_new_expense_controller.dart';

class RentAddNewExpenseView extends BaseView<RentAddNewExpenseController> {
  RentAddNewExpenseView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => const Color(0xFFF9F8F6);

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFFF9F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF232323), size: 20),
        ),
        titleSpacing: 2,
        title: const Text(
          'The Concierge',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: Colors.black,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.notifications, size: 16, color: Color(0xFF00757A)),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFF0A5A64),
              child: Icon(Icons.person, size: 14, color: Colors.white),
            ),
          ),
        ],
      );

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FINANCIAL LEDGER',
                    style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2.0,
                        color: Color(0xFF7A7A7A),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const Text('Log New\nExpense',
                    style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22.5,
                        height: 1.07,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111))),
                const SizedBox(height: 10),
                const Text(
                  'Maintain the editorial standard of your estate’s finances. Every entry ensures the precision and health of your hospitality business.',
                  style: TextStyle(fontSize: 13, height: 1.38, color: Color(0xFF5A5A5A)),
                ),
                const SizedBox(height: 14),
                _expenseCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExpenseLabel('1. CLASSIFICATION'),
                      SizedBox(height: 6),
                      Text('Select Category',
                          style: TextStyle(
                              fontSize: 17,
                              color: Color(0xFF222222),
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ExpenseChip(label: 'Rent', selected: true),
                          _ExpenseChip(label: 'Maintenance'),
                          _ExpenseChip(label: 'Utilities'),
                          _ExpenseChip(label: 'Salary'),
                          _ExpenseChip(label: 'Other'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _expenseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ExpenseLabel('2. FINANCIAL DETAILS'),
                      const SizedBox(height: 10),
                      const Text('Amount (Tsh)',
                          style: TextStyle(fontSize: 13, color: Color(0xFF111111))),
                      const SizedBox(height: 7),
                      _inputHint('Tsh 0.00'),
                      const SizedBox(height: 12),
                      const Text('Transaction Date',
                          style: TextStyle(fontSize: 13, color: Color(0xFF111111))),
                      const SizedBox(height: 7),
                      _inputHint('10/27/2023', suffix: Icons.calendar_month_rounded),
                      const SizedBox(height: 12),
                      const Text('Select Tenant (Optional)',
                          style: TextStyle(fontSize: 13, color: Color(0xFF111111))),
                      const SizedBox(height: 7),
                      _inputHint('Global Expense (No Tenant)',
                          suffix: Icons.people_alt_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF01535E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 15),
                    label: const Text('RECORD TRANSACTION',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By recording this expense, you update the monthly operational report for The Concierge',
                  style: TextStyle(fontSize: 9, height: 1.3, color: Color(0xFF8A8A8A)),
                ),
                const SizedBox(height: 14),
                _expenseCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Context',
                          style: TextStyle(
                              fontFamily: 'Georgia',
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
                      Text(
                        'Efficiency is the foundation of luxury hospitality. Every entry can spend extra value to the guest experience.',
                        style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: Color(0xFF4E4E4E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 210,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset('images/luxury_room_view.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: const Color(0xFF334444))),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('OPERATIONAL EXCELLENCE',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      letterSpacing: 1.8,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text(
                                'Invest in quality maintenance to preserve\nasset value.',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 86),
              ],
            ),
          ),
        ),
        _expenseBottomNav(),
      ],
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

  Widget _inputHint(String text, {IconData? suffix}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 15, color: Color(0xFF4D4D4D))),
          ),
          if (suffix != null) Icon(suffix, size: 16, color: const Color(0xFF3B3B3B)),
        ],
      ),
    );
  }

  Widget _expenseBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7E6E1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _ExpenseNav(icon: Icons.home_outlined, label: 'LISTINGS'),
            _ExpenseNav(icon: Icons.calendar_today_outlined, label: 'CALENDAR'),
            _ExpenseNav(
                icon: Icons.receipt_long_rounded, label: 'LEDGER', selected: true),
            _ExpenseNav(icon: Icons.bar_chart_outlined, label: 'STATS'),
          ],
        ),
      ),
    );
  }
}

class _ExpenseLabel extends StatelessWidget {
  const _ExpenseLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 8,
            letterSpacing: 1.6,
            color: Color(0xFF717171),
            fontWeight: FontWeight.w700));
  }
}

class _ExpenseChip extends StatelessWidget {
  const _ExpenseChip({required this.label, this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF005D5D) : const Color(0xFFF1F1EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF353535))),
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

class _ExpenseNav extends StatelessWidget {
  const _ExpenseNav({required this.icon, required this.label, this.selected = false});
  final IconData icon;
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF005D5D) : const Color(0xFF757575);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

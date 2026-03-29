import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../controllers/rent_add_income_form_controller.dart';

class RentAddIncomeFormView extends BaseView<RentAddIncomeFormController> {
  RentAddIncomeFormView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => const Color(0xFFF9F8F6);

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFFF9F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close, color: Color(0xFF202020), size: 24),
        ),
        titleSpacing: 2,
        title: const Text(
          'The Concierge',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF005A5A),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE5E3DD),
              child: Icon(Icons.person, color: Color(0xFF2F2F2F), size: 18),
            ),
          ),
        ],
      );

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Income',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 25,
              color: Color(0xFF121212),
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Record a payment for this property',
            style: TextStyle(fontSize: 18, color: Color(0xFF2E2E2E)),
          ),
          const SizedBox(height: 22),
          _label('SELECT TENANT'),
          _field('Choose a guest or long-term resident', suffix: Icons.expand_more),
          const SizedBox(height: 16),
          _label('AMOUNT PAID'),
          _field('\$ 0.00'),
          const SizedBox(height: 16),
          _label('DATE PAID'),
          _field('mm/dd/yyyy', suffix: Icons.calendar_today_outlined),
          const SizedBox(height: 16),
          _label('CATEGORY'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip(label: 'Rent', selected: true),
              _CategoryChip(label: 'Service Charge'),
              _CategoryChip(label: 'Maintenance'),
              _CategoryChip(label: 'Other'),
            ],
          ),
          const SizedBox(height: 18),
          _label('NOTES (OPTIONAL)'),
          _field(
            'Add any specific details regarding this\ntransaction...',
            height: 74,
            isMultiline: true,
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImpactIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Impact on Performance',
                          style: TextStyle(
                              color: Color(0xFF0E0E0E),
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text(
                        'Recording this income will\nimmediately update your monthly\nrevenue stats and occupancy value\nreports.',
                        style: TextStyle(
                            color: Color(0xFF2B2B2B), fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF006D73),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              icon: const Icon(Icons.check, size: 17),
              label: const Text('Save Income',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.center,
            child: Text('Cancel',
                style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1B1B),
            )),
      );

  Widget _field(String text,
      {IconData? suffix, bool isMultiline = false, double height = 44}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Text(text,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: const Color(0xFF5B5B5B),
                    height: isMultiline ? 1.35 : 1.1,
                  ))),
          if (suffix != null) Icon(suffix, size: 18, color: const Color(0xFF2D2D2D)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF006D73) : const Color(0xFFF1F1EE),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1E1E1E),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ImpactIcon extends StatelessWidget {
  const _ImpactIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFA34E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.account_balance_wallet_outlined,
          color: Colors.white, size: 19),
    );
  }
}

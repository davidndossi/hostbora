import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_loyalty_thresholds_controller.dart';

class RentLoyaltyThresholdsView extends BaseView<RentLoyaltyThresholdsController> {
  RentLoyaltyThresholdsView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
        backgroundColor: RentTheme.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: CircleAvatar(
            radius: 13,
            backgroundColor: RentTheme.navy.withValues(alpha: 0.15),
            child: const Icon(Icons.person, size: 15, color: RentTheme.navy),
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'The Concierge',
          style: TextStyle(
            color: RentTheme.teal,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      );

  @override
  Widget body(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const Text(
          'RESIDENT RETENTION',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: RentTheme.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Loyalty\nThresholds',
          style: TextStyle(
            height: 1,
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: RentTheme.navy,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Define the moments of excellence. Create automated triggers that reward your long-term residents based on their commitment and investment in the community.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: RentTheme.muted,
          ),
        ),
        const SizedBox(height: 16),
        rentCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Curation Logic',
                      style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: RentTheme.navy),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Automated rewards reduce churn by 24% on average across premium properties.',
                      style: TextStyle(fontSize: 12, color: RentTheme.muted),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'View Strategy Guide  ->',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RentTheme.navy),
                    ),
                  ],
                ),
              ),
              Icon(Icons.auto_awesome, color: RentTheme.navy.withValues(alpha: 0.14), size: 28),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Offer Thresholds',
          icon: Icons.tune,
          child: Column(
            children: const [
              _FieldLabel('MINIMUM STAY DURATION (MONTHS)'),
              _InputPill(left: '12', right: 'Months'),
              SizedBox(height: 10),
              _FieldLabel('TOTAL REVENUE THRESHOLD (TSH)'),
              _InputPill(left: '5,000,000', right: 'Tsh'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Offer Type',
          icon: Icons.redeem_outlined,
          child: const Column(
            children: [
              _ChoiceTile(label: 'Reduced Rent'),
              SizedBox(height: 8),
              _ChoiceTile(label: 'Waived Service Charge'),
              SizedBox(height: 8),
              _ChoiceTile(label: 'One-time Free Maintenance'),
              SizedBox(height: 8),
              _ChoiceTile(label: 'Cashback/Payment'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Terms &\nDescription',
          icon: Icons.assignment_outlined,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel('DESCRIPTION OF THE OFFER TERMS'),
              _TextArea(
                hint: "Ex: Resident receives a 10% reduction on the 13th month's rent upon successful completion of a 12-month lease cycle without arrears.",
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget? bottomNavigationBar() {
    return Container(
      color: RentTheme.bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Discard\nDraft',
                    style: TextStyle(fontSize: 12, color: RentTheme.navy, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: RentTheme.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text(
                        'Deploy Loyalty\nProgram',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.05),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniTab(label: 'PROGRAMS', icon: Icons.widgets_outlined),
                  _MiniTab(label: 'THRESHOLDS', icon: Icons.tune, selected: true),
                  _MiniTab(label: 'REWARDS', icon: Icons.card_giftcard_outlined),
                  _MiniTab(label: 'PROFILE', icon: Icons.person_outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return rentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: RentTheme.navy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: RentTheme.navy,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: RentTheme.navy),
      ),
    );
  }
}

class _InputPill extends StatelessWidget {
  const _InputPill({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F1EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(left, style: const TextStyle(fontSize: 29, color: RentTheme.muted))),
          Text(right, style: const TextStyle(fontSize: 12, color: RentTheme.muted)),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(color: const Color(0xFFF2F1EC), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: RentTheme.muted.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: RentTheme.navy),
          ),
        ],
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  const _TextArea({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 118,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F1EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hint,
        style: const TextStyle(fontSize: 11, color: RentTheme.muted, height: 1.35),
      ),
    );
  }
}

class _MiniTab extends StatelessWidget {
  const _MiniTab({required this.label, required this.icon, this.selected = false});

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : RentTheme.muted;
    final bg = selected ? RentTheme.teal : Colors.transparent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 8.5, color: color, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

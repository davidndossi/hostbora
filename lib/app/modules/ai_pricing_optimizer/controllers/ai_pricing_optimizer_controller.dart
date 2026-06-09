import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class PricingRuleData {
  const PricingRuleData({
    required this.title,
    required this.badge,
    required this.positiveBadge,
    required this.description,
  });

  final String title;
  final String badge;
  final bool positiveBadge;
  final String description;
}

class SimulationLine {
  const SimulationLine({
    required this.label,
    required this.amount,
    this.isBase = false,
    this.isTotal = false,
  });

  final String label;
  final String amount;
  final bool isBase;
  final bool isTotal;
}

class AiPricingOptimizerController extends BaseController {
  static const PricingRuleData ruleWeekend = PricingRuleData(
    title: 'Weekend Adjustment',
    badge: '+20%',
    positiveBadge: true,
    description: 'Automatically increases your nightly rate for Friday and Saturday stays to capture peak leisure demand.',
  );
  static const PricingRuleData ruleHighSeason = PricingRuleData(
    title: 'High Season',
    badge: '+30%',
    positiveBadge: true,
    description: 'Boosts pricing during peak travel windows (Dec 15 – Jan 10) when demand historically outpaces supply.',
  );
  static const PricingRuleData ruleLowOccupancy = PricingRuleData(
    title: 'Low Occupancy',
    badge: '-10%',
    positiveBadge: false,
    description: 'Triggers a modest discount when occupancy drops below 20% to stimulate bookings.',
  );
  static const PricingRuleData ruleLocation = PricingRuleData(
    title: 'Location Premium',
    badge: '+25%',
    positiveBadge: true,
    description: 'Adds a premium for listings in the Masaki Zone based on comparable market rates.',
  );

  final rules = const [
    ruleWeekend,
    ruleHighSeason,
    ruleLowOccupancy,
    ruleLocation,
  ];

  /// Toggle per rule (aligned with [rules]).
  final List<RxBool> ruleEnabled = List.generate(4, (_) => true.obs);

  void setRuleEnabled(int index, bool value) {
    if (index >= 0 && index < ruleEnabled.length) {
      ruleEnabled[index].value = value;
    }
  }

  final simulationDate = DateTime(2024, 12, 21).obs;

  String get formattedSimulationDate =>
      DateFormat('EEEE, MMM d, y').format(simulationDate.value);

  Future<void> pickSimulationDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: simulationDate.value,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      locale: const Locale('en', 'GB'),
    );
    
    if (picked != null) {
      simulationDate.value = picked;
    }
  }

  static const double baseRate = 120;
  static const double weekendAdj = 24;
  static const double highSeasonAdj = 36;
  static const double masakiAdj = 30;

  double get estimatedTotal =>
      baseRate + weekendAdj + highSeasonAdj + masakiAdj;

  List<SimulationLine> get simulationLines => [
        const SimulationLine(label: 'Base Rate', amount: '\$120.00', isBase: true),
        const SimulationLine(label: 'Weekend Adj. (+20%)', amount: '+\$24.00'),
        const SimulationLine(label: 'High Season (+30%)', amount: '+\$36.00'),
        const SimulationLine(label: 'Masaki Premium (+25%)', amount: '+\$30.00'),
      ];

  void applySettings() {
    showSuccessMessage('Pricing rules applied.');
  }

  void addRule() {
    showSuccessMessage('Create a new rule (coming soon).');
  }

  void editRule(int index) {
    showSuccessMessage('Edit "${rules[index].title}" (coming soon).');
  }

  void goOverview() => Get.offNamed(Routes.MAIN);

  void goCalendar() => Get.toNamed(Routes.HOST_CALENDAR);

  void goInsights() => Get.toNamed(Routes.AI_INSIGHTS);

  void goProfile() => Get.toNamed(Routes.SETTINGS);
}

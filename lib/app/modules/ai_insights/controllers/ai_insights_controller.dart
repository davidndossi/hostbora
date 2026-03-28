import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

enum RecommendationImpact { highImpact, observation, newItem }

class RecommendationItem {
  final String title;
  final String description;
  final String cta;
  final RecommendationImpact impact;
  final String icon;

  const RecommendationItem({
    required this.title,
    required this.description,
    required this.cta,
    required this.impact,
    required this.icon,
  });
}

class AiInsightsController extends BaseController {
  final selectedRange = 0.obs; // 0=1W, 1=1M, 2=All

  final chartValues = <double>[22, 30, 28, 40, 57, 49, 64].obs;

  final recommendations = const <RecommendationItem>[
    RecommendationItem(
      title: 'Dynamic Pricing',
      description: 'High demand detected for next weekend in your neighborhood. We suggest raising price by 15%.',
      cta: 'Take Action',
      impact: RecommendationImpact.highImpact,
      icon: '💳',
    ),
    RecommendationItem(
      title: 'Review Sentiment',
      description: 'Frequent mentions of "slow Wi-Fi" in 3 recent reviews. Consider a provider upgrade.',
      cta: 'View Reviews',
      impact: RecommendationImpact.observation,
      icon: '📶',
    ),
    RecommendationItem(
      title: 'Efficiency Tip',
      description: 'Automate turnover notifications for your cleaning team based on guest checkout events.',
      cta: 'Enable Automation',
      impact: RecommendationImpact.newItem,
      icon: '🧹',
    ),
  ];

  void setRange(int i) => selectedRange.value = i;
}

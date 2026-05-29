import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/service/currency_service.dart';
import '../../data/local/service/portfolio_ai_context_service.dart';
import '../../data/local/service/portfolio_ai_hub_insight.dart';
import '../../routes/app_pages.dart';
import '../theme/app_theme_tokens.dart';
import 'app_skeleton.dart';

/// Tappable insight strip; loads portfolio metrics from local DB only.
class HubInsightBanner extends StatefulWidget {
  const HubInsightBanner({super.key});

  @override
  State<HubInsightBanner> createState() => _HubInsightBannerState();
}

class _HubInsightBannerState extends State<HubInsightBanner> {
  HubInsight? _insight;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ctx = await Get.find<PortfolioAiContextService>().build();
      final isSw = Get.locale?.languageCode == 'sw';
      final currency = Get.find<CurrencyService>();
      final insight = PortfolioAiHubInsight.forContext(
        ctx,
        isSw: isSw,
        formatMoney: (n) => currency.formatBase(n),
      );
      if (mounted) {
        setState(() {
          _insight = insight;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openAiManager() {
    final question = _insight?.suggestedQuestion;
    Get.toNamed(
      Routes.AI_MANAGER,
      arguments: <String, dynamic>{
        if (question != null && question.isNotEmpty) 'initialQuestion': question,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isSw = Get.locale?.languageCode == 'sw';

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: AppSkeleton(width: double.infinity, height: 52, borderRadius: 12),
      );
    }

    final line = _insight?.line;
    if (line == null || line.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: tokens.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openAiManager,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: tokens.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSw ? 'Kidokezo cha AI' : 'AI insight',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        line,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: tokens.accent, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

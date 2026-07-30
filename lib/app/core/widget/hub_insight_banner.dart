import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import '../../data/local/service/currency_service.dart';
import '../../data/local/service/portfolio_ai_context_service.dart';
import '../../data/local/service/portfolio_ai_hub_insight.dart';
import '../../routes/app_pages.dart';
import '../theme/app_theme_tokens.dart';
import 'app_skeleton.dart';

/// Tappable insight strip; loads portfolio metrics from local DB only.
///
/// [compact] keeps it quiet so it does not compete with Create / AI FAB.
class HubInsightBanner extends StatefulWidget {
  const HubInsightBanner({
    super.key,
    this.compact = false,
    this.dismissible = false,
  });

  final bool compact;
  final bool dismissible;

  @override
  State<HubInsightBanner> createState() => _HubInsightBannerState();
}

class _HubInsightBannerState extends State<HubInsightBanner> {
  HubInsight? _insight;
  bool _loading = true;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.dismissible) {
      try {
        final prefs = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        );
        final gone = await prefs.getBool(
          PreferenceManager.keyHasDismissedHomeAiInsight,
          defaultValue: false,
        );
        if (gone) {
          if (mounted) {
            setState(() {
              _dismissed = true;
              _loading = false;
            });
          }
          return;
        }
      } catch (_) {}
    }

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

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final prefs = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      await prefs.setBool(PreferenceManager.keyHasDismissedHomeAiInsight, true);
    } catch (_) {}
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

    if (_dismissed) return const SizedBox.shrink();

    if (_loading) {
      if (widget.compact) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: AppSkeleton(width: double.infinity, height: 52, borderRadius: 12),
      );
    }

    final line = _insight?.line;
    if (line == null || line.isEmpty) return const SizedBox.shrink();

    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: tokens.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openAiManager,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: tokens.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                  if (widget.dismissible)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: tokens.textMuted,
                      ),
                      onPressed: _dismiss,
                    )
                  else
                    Icon(Icons.chevron_right, color: tokens.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ),
      );
    }

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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_colors.dart';
import '../../../data/model/rewards_dashboard.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class ChallengesHomeBanner extends StatefulWidget {
  const ChallengesHomeBanner({super.key});

  @override
  State<ChallengesHomeBanner> createState() => _ChallengesHomeBannerState();
}

class _ChallengesHomeBannerState extends State<ChallengesHomeBanner> {
  RewardsDashboard? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!Get.isRegistered<AppRepository>(tag: (AppRepository).toString())) return;
      final repo = Get.find<AppRepository>(tag: (AppRepository).toString());
      final response = await repo.getRewards();
      final raw = response.data;
      if (!mounted || raw is! Map) return;
      setState(() {
        _data = RewardsDashboard.fromJson(Map<String, dynamic>.from(raw));
      });
    } catch (_) {
      // Home stays usable if rewards are unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    final challenge = _data?.challenges.isNotEmpty == true ? _data!.challenges.first : null;
    return InkWell(
      onTap: () => Get.toNamed(Routes.CHALLENGES_REWARDS),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSw ? 'Changamoto na zawadi' : 'Challenges & Rewards',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              challenge?.title ??
                  (isSw ? 'Pata HB Points kwa usimamizi mzuri.' : 'Earn HB Points for good hosting.'),
              style: theme.textTheme.bodyMedium,
            ),
            if (challenge != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (challenge.pct / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  color: AppColors.designAccent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${challenge.pct}% · ${_data?.balance ?? 0} HB',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

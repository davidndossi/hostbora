import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import '../locale/app_localizations_resolver.dart';
import '../theme/app_theme_tokens.dart';
import '../values/app_colors.dart';

/// Subtle banner shown when the logged-in user is managing another host's portfolio.
class ManagingForBanner extends StatelessWidget {
  const ManagingForBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BannerData>(
      future: _load(),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null || !data.isManager) return const SizedBox.shrink();
        final name =
            data.hostName.trim().isEmpty ? 'host' : data.hostName.trim();
        final text =
            resolveAppLocalizations().managingPortfolioBanner(name);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.colorPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.colorPrimary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.manage_accounts_outlined,
                size: 20,
                color: AppColors.colorPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<_BannerData> _load() async {
    try {
      final prefs = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      final isManager = await prefs.getBool(
        PreferenceManager.keyIsPortfolioManager,
        defaultValue: false,
      );
      final name = await prefs.getString(
        PreferenceManager.keyManagedHostName,
        defaultValue: '',
      );
      return _BannerData(isManager: isManager, hostName: name);
    } catch (_) {
      return const _BannerData(isManager: false, hostName: '');
    }
  }
}

class _BannerData {
  const _BannerData({required this.isManager, required this.hostName});
  final bool isManager;
  final String hostName;
}

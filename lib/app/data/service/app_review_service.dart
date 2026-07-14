import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../data/local/preference/preference_manager.dart';
import '../../routes/app_pages.dart';

/// Prompts satisfied hosts to rate Host Bora on the App Store / Play Store.
///
/// Rules:
/// - Eligible after 3 successful logins **or** 7 days since first tracked use.
/// - At most 2 prompts, at least 90 days apart.
/// - Two-step: Yes → native in-app review; Not really → in-app support.
class AppReviewService extends GetxService {
  AppReviewService({
    required PreferenceManager preferenceManager,
    InAppReview? inAppReview,
  })  : _preferenceManager = preferenceManager,
        _inAppReview = inAppReview ?? InAppReview.instance;

  static const _keyPromptCount = 'app_review_prompt_count';
  static const _keyLastPromptMs = 'app_review_last_prompt_ms';
  static const _keySuccessfulLoginCount = 'app_review_successful_login_count';
  static const _keyFirstUseMs = 'app_review_first_use_ms';

  static const int maxPrompts = 2;
  static const int minDaysBetweenPrompts = 90;
  static const int minSuccessfulLogins = 3;
  static const int minDaysOfUse = 7;

  final PreferenceManager _preferenceManager;
  final InAppReview _inAppReview;

  bool _promptVisible = false;

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  /// Call after each API login that returns `auth_success`.
  Future<void> onSuccessfulLogin() async {
    final count = await _preferenceManager.getInt(
      _keySuccessfulLoginCount,
      defaultValue: 0,
    );
    await _preferenceManager.setInt(_keySuccessfulLoginCount, count + 1);
    await _ensureFirstUseTracked();
  }

  /// Call when the main shell is shown (post-frame) to evaluate eligibility.
  Future<void> maybeShowPrompt() async {
    if (_promptVisible) return;
    if (Get.context == null) return;
    if (!await _isEligible()) return;

    _promptVisible = true;
    await _recordPromptShown();

    final context = Get.context!;
    if (!context.mounted) {
      _promptVisible = false;
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _t('Enjoying Host Bora?', 'Unafurahia Host Bora?'),
        ),
        content: Text(
          _t(
            'Your feedback helps us improve for hosts across Tanzania.',
            'Maoni yako hutusaidia kuboresha huduma kwa wamiliki wa nyumba.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Get.toNamed(Routes.SUPPORT);
            },
            child: Text(_t('Not really', 'Si sana')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _requestStoreReview();
            },
            child: Text(_t('Yes', 'Ndiyo')),
          ),
        ],
      ),
    );

    _promptVisible = false;
  }

  Future<void> _requestStoreReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {
      // Native sheet is best-effort; never block the user.
    }
  }

  Future<void> _ensureFirstUseTracked() async {
    final firstUse = await _preferenceManager.getInt(
      _keyFirstUseMs,
      defaultValue: 0,
    );
    if (firstUse == 0) {
      await _preferenceManager.setInt(
        _keyFirstUseMs,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<bool> _isEligible() async {
    await _ensureFirstUseTracked();

    final promptCount = await _preferenceManager.getInt(
      _keyPromptCount,
      defaultValue: 0,
    );
    if (promptCount >= maxPrompts) return false;

    final lastPromptMs = await _preferenceManager.getInt(
      _keyLastPromptMs,
      defaultValue: 0,
    );
    if (lastPromptMs > 0) {
      final daysSinceLast = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastPromptMs))
          .inDays;
      if (daysSinceLast < minDaysBetweenPrompts) return false;
    }

    final loginCount = await _preferenceManager.getInt(
      _keySuccessfulLoginCount,
      defaultValue: 0,
    );
    if (loginCount >= minSuccessfulLogins) return true;

    final firstUseMs = await _preferenceManager.getInt(
      _keyFirstUseMs,
      defaultValue: 0,
    );
    if (firstUseMs > 0) {
      final daysSinceFirst = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(firstUseMs))
          .inDays;
      if (daysSinceFirst >= minDaysOfUse) return true;
    }

    return false;
  }

  Future<void> _recordPromptShown() async {
    final promptCount = await _preferenceManager.getInt(
      _keyPromptCount,
      defaultValue: 0,
    );
    await _preferenceManager.setInt(_keyPromptCount, promptCount + 1);
    await _preferenceManager.setInt(
      _keyLastPromptMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}

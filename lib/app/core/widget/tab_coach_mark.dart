import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';

/// One-at-a-time "What's this?" tips for first visits to major tabs.
/// Never stacks with another coach mark in the same session.
class TabCoachMark {
  TabCoachMark._();

  static bool _sessionBusy = false;

  static Future<void> maybeShowProperties() => _maybeShow(
        preferenceKey: PreferenceManager.keyHasSeenPropertiesCoachMark,
        titleEn: "What's this?",
        titleSw: 'Hii ni nini?',
        bodyEn:
            'Properties is where you manage all your listings — BnB and rent. '
            'Tap a property to open bookings, tenants, and staff.',
        bodySw:
            'Mali ndipo unaposimamia orodha zako zote — BnB na kodi. '
            'Gusa mali kufungua uhifadhi, wapangaji, na wafanyakazi.',
      );

  static Future<void> maybeShowFinances() => _maybeShow(
        preferenceKey: PreferenceManager.keyHasSeenFinancesCoachMark,
        titleEn: "What's this?",
        titleSw: 'Hii ni nini?',
        bodyEn:
            'Finances shows income, expenses, and trends. '
            'Use Add Income / Add Expense in the toolbar to record money.',
        bodySw:
            'Fedha inaonyesha mapato, matumizi, na mwelekeo. '
            'Tumia Ongeza Mapato / Ongeza Matumizi kwenye juu kurekodi pesa.',
      );

  static Future<void> _maybeShow({
    required String preferenceKey,
    required String titleEn,
    required String titleSw,
    required String bodyEn,
    required String bodySw,
  }) async {
    if (_sessionBusy) return;
    if (Get.context == null) return;
    if ((Get.isDialogOpen ?? false) || (Get.isBottomSheetOpen ?? false)) {
      return;
    }

    PreferenceManager prefs;
    try {
      prefs = Get.find<PreferenceManager>(tag: (PreferenceManager).toString());
    } catch (_) {
      return;
    }

    final seen = await prefs.getBool(preferenceKey, defaultValue: false);
    if (seen) return;

    _sessionBusy = true;
    try {
      await prefs.setBool(preferenceKey, true);
      final isSw = Get.locale?.languageCode == 'sw';
      final context = Get.context;
      if (context == null || !context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: Text(isSw ? titleSw : titleEn),
          content: Text(isSw ? bodySw : bodyEn),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isSw ? 'Sawa' : 'Got it'),
            ),
          ],
        ),
      );
    } finally {
      _sessionBusy = false;
    }
  }
}

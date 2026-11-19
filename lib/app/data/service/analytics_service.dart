import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

import '../local/preference/preference_manager.dart';

/// Event names for the funnel HostBora measures.
///
/// `sign_up` is a GA4 reserved name so it reports in the stock Firebase
/// funnels; the rest are custom and need registering as custom dimensions in
/// the Firebase console before they show up in exploration reports.
class AnalyticsEvents {
  AnalyticsEvents._();

  static const signUp = 'sign_up';
  static const propertyAdded = 'property_added';
  static const paymentRecorded = 'payment_recorded';

  /// Fired once per install, alongside the first [paymentRecorded].
  /// This is the activation milestone — a landlord who records money has
  /// crossed from "looking" to "using".
  static const firstPaymentRecorded = 'first_payment_recorded';

  static const reminderSent = 'reminder_sent';
  static const reportExported = 'report_exported';
  static const planViewed = 'plan_viewed';
}

/// Firebase Analytics wrapper for the six events that matter.
///
/// Rules this service follows, because analytics must never be the reason a
/// user action fails:
///  * every method swallows its own errors and returns normally;
///  * nothing here awaits the network on the caller's critical path;
///  * no tenant, guest, or staff identifiers are ever sent — only categorical
///    values (workspace, channel, format) and counts. Payment amounts are
///    deliberately left out, so landlord revenue does not leave the device.
class AnalyticsService extends GetxService {
  AnalyticsService({FirebaseAnalytics? analytics, bool enabled = true})
      : _injected = analytics,
        _enabled = enabled;

  final FirebaseAnalytics? _injected;
  bool _enabled;

  FirebaseAnalytics? _resolved;

  /// Resolved lazily so a missing or un-initialized Firebase app disables
  /// analytics instead of throwing at construction time.
  FirebaseAnalytics? get _analytics {
    if (!_enabled) return null;
    if (_injected != null) return _injected;
    if (_resolved != null) return _resolved;
    try {
      _resolved = FirebaseAnalytics.instance;
    } catch (_) {
      _enabled = false;
    }
    return _resolved;
  }

  /// Turns collection off for the rest of the session and at the SDK level,
  /// for an opt-out control in settings.
  Future<void> setCollectionEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {}
  }

  // ───────────────────────────────────────────────────────── the six events ──

  /// 1. A host account was created on the server.
  Future<void> logSignUp({
    required String method,
    bool usedReferralCode = false,
  }) {
    return _log(AnalyticsEvents.signUp, {
      'method': method,
      'used_referral_code': usedReferralCode,
    });
  }

  /// 2. A property was saved. The app is offline-first, so this fires on the
  /// local save — the moment the user considers the property added.
  Future<void> logPropertyAdded({
    required String workspace,
    String? propertyType,
    int? units,
    String? source,
  }) {
    return _log(AnalyticsEvents.propertyAdded, {
      'workspace': workspace,
      'property_type': propertyType,
      'units': units,
      'source': source,
    });
  }

  /// 3. Money was recorded against a unit. Also emits
  /// [AnalyticsEvents.firstPaymentRecorded] the first time it ever happens on
  /// this install.
  Future<void> logPaymentRecorded({
    required String workspace,
    required String currency,
    String? paymentMethod,
    String? category,
  }) async {
    final params = <String, Object?>{
      'workspace': workspace,
      'currency': currency,
      'payment_method': paymentMethod,
      'category': category,
    };
    await _log(AnalyticsEvents.paymentRecorded, params);

    if (await _claimFirstPaymentFlag()) {
      await _log(AnalyticsEvents.firstPaymentRecorded, params);
    }
  }

  /// 4. A rent reminder actually left the device, manually or on a schedule.
  Future<void> logReminderSent({
    required String channel,
    required bool automated,
    int recipients = 1,
    String? reminderType,
  }) {
    return _log(AnalyticsEvents.reminderSent, {
      'channel': channel,
      'automated': automated,
      'recipients': recipients,
      'reminder_type': reminderType,
    });
  }

  /// 5. A report left the app as a file the user can hand to someone else.
  Future<void> logReportExported({
    required String format,
    required String reportType,
    String? module,
  }) {
    return _log(AnalyticsEvents.reportExported, {
      'format': format,
      'report_type': reportType,
      'module': module,
    });
  }

  /// 6. The plans screen was opened — the top of the paid funnel.
  Future<void> logPlanViewed({
    required String currentPlan,
    required bool isActive,
    String? source,
  }) {
    return _log(AnalyticsEvents.planViewed, {
      'current_plan': currentPlan,
      'is_active': isActive,
      'source': source,
    });
  }

  // ─────────────────────────────────────────────────────────────── internals ──

  /// Returns true exactly once per install, on the first recorded payment.
  Future<bool> _claimFirstPaymentFlag() async {
    try {
      final prefs = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      final already = await prefs.getBool(
        PreferenceManager.keyFirstPaymentLogged,
        defaultValue: false,
      );
      if (already) return false;
      await prefs.setBool(PreferenceManager.keyFirstPaymentLogged, true);
      return true;
    } catch (_) {
      // Without durable storage we cannot tell first from repeat, so stay
      // silent rather than emit the milestone on every payment.
      return false;
    }
  }

  Future<void> _log(String name, Map<String, Object?> params) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(
        name: _sanitizeName(name),
        parameters: _sanitizeParams(params),
      );
    } catch (_) {
      // Never surface an analytics failure to the caller.
    }
  }

  /// GA4 allows letters, digits and underscores, up to 40 characters.
  static String _sanitizeName(String raw) {
    final cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.length <= 40 ? cleaned : cleaned.substring(0, 40);
  }

  /// Drops nulls and empties, coerces bools to dimension-friendly strings, and
  /// clips string values to the 100-character GA4 limit.
  static Map<String, Object> _sanitizeParams(Map<String, Object?> params) {
    final out = <String, Object>{};
    params.forEach((key, value) {
      if (value == null) return;
      final name = _sanitizeName(key);
      if (name.isEmpty) return;

      if (value is bool) {
        out[name] = value ? 'true' : 'false';
      } else if (value is num) {
        out[name] = value;
      } else {
        final text = value.toString().trim();
        if (text.isEmpty) return;
        out[name] = text.length <= 100 ? text : text.substring(0, 100);
      }
    });
    return out;
  }
}

/// Resolves the service without forcing every caller to guard registration.
///
/// Returns null when analytics is not registered — for example in a unit test
/// or a background isolate that never ran [InitialBinding].
AnalyticsService? get analytics {
  try {
    return Get.isRegistered<AnalyticsService>()
        ? Get.find<AnalyticsService>()
        : null;
  } catch (_) {
    return null;
  }
}

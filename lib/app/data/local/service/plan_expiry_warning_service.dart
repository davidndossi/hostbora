import 'package:get/get.dart';

import '/app/core/access/plan_loss_snapshot.dart';
import '/app/data/local/db/rent_notification_log_local_data_source.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/service/currency_service.dart';
import '/app/data/local/service/local_notification_scheduler_service.dart';
import '/app/data/model/subscription_status.dart';
import '/app/data/service/subscription_service.dart';

/// Warns a host whose plan is about to end, naming what they are about to
/// lose rather than that a renewal is due.
///
/// Expiry drops the account to Free, which hides every property past the
/// first and every record before the current month. Both of those are
/// countable before they happen, so the warning quotes the host's own figures
/// instead of asking them to imagine the consequence.
///
/// Fires once per threshold per billing period. The dedupe key carries the
/// period end, so a renewal re-arms all three warnings for the next period
/// without any explicit reset.
class PlanExpiryWarningService extends GetxService {
  PlanExpiryWarningService({
    required PreferenceManager preferenceManager,
    required LocalNotificationSchedulerService notificationScheduler,
    required RentNotificationLogLocalDataSource notificationLogLocal,
  })  : _preferenceManager = preferenceManager,
        _notificationScheduler = notificationScheduler,
        _notificationLogLocal = notificationLogLocal;

  final PreferenceManager _preferenceManager;
  final LocalNotificationSchedulerService _notificationScheduler;
  final RentNotificationLogLocalDataSource _notificationLogLocal;

  /// Days-remaining marks at which the host is told. Descending so the first
  /// match is the tightest deadline that applies.
  static const thresholds = <int>[1, 3, 7];

  bool _running = false;

  static Future<void> refreshIfRegistered() async {
    if (!Get.isRegistered<PlanExpiryWarningService>()) return;
    await Get.find<PlanExpiryWarningService>().runNow();
  }

  Future<void> runNow() async {
    if (_running) return;
    _running = true;
    try {
      final sub = _status();
      // Nothing to warn about when there is no dated access to lose: an
      // already-expired plan has taken the loss, and 'loading' is not yet
      // known to be anything.
      if (sub == null || !sub.isActive) return;

      final end = sub.currentPeriodEnd ?? sub.trialEndAt;
      if (end == null) return;

      final days = sub.daysLeft;
      final threshold = thresholds.firstWhereOrNull((t) => days <= t);
      if (threshold == null) return;

      final key = 'plan_expiry_warned_${end.millisecondsSinceEpoch}_$threshold';
      if (await _preferenceManager.getBool(key, defaultValue: false)) return;

      final loss = await PlanLossSnapshot.load();
      final title = _title(sub, days);
      final body = _body(sub, loss);

      await _notificationScheduler.showNow(
        id: key.hashCode.abs() % 2147483647,
        title: title,
        body: body,
        payload: 'subscription',
      );
      await _notificationLogLocal.insert(
        type: 'urgent',
        title: title,
        subtitle: body,
        actionLabel: _isSw ? 'Ona mipango' : 'View plans',
        payload: 'subscription',
      );
      await _preferenceManager.setBool(key, true);
    } catch (_) {
      // Best effort: a warning that cannot be computed must not break the
      // notification pass it runs inside.
    } finally {
      _running = false;
    }
  }

  SubscriptionStatus? _status() {
    if (!Get.isRegistered<SubscriptionService>()) return null;
    try {
      return Get.find<SubscriptionService>().status.value;
    } catch (_) {
      return null;
    }
  }

  String _title(SubscriptionStatus sub, int days) {
    final plan = sub.isTrial
        ? (_isSw ? 'Jaribio' : 'Your free trial')
        : '${_planLabel(sub.plan)} ${_isSw ? '' : 'plan'}'.trim();
    if (days <= 0) {
      return _isSw ? '$plan inaisha leo' : '$plan ends today';
    }
    if (days == 1) {
      return _isSw ? '$plan inaisha kesho' : '$plan ends tomorrow';
    }
    return _isSw
        ? '$plan inaisha baada ya siku $days'
        : '$plan ends in $days days';
  }

  /// Names the consequences that actually apply, and nothing else. A host
  /// with one property is not told properties will be hidden.
  String _body(SubscriptionStatus sub, PlanLossSnapshot loss) {
    final parts = <String>[];

    if (loss.propertyCount > 1) {
      parts.add(
        _isSw
            ? 'mali ${loss.propertyCount} zitapungua kuwa 1'
            : '${loss.propertyCount} properties drop to 1',
      );
    }
    if (loss.hiddenRecordCount > 0) {
      final money = _money(loss.hiddenIncomeTotal + loss.hiddenExpenseTotal);
      parts.add(
        _isSw
            ? 'kumbukumbu ${loss.hiddenRecordCount} ($money) zitafichwa'
            : '${loss.hiddenRecordCount} records ($money) hide',
      );
    }

    final on = sub.periodEndDisplay;
    if (parts.isEmpty) {
      // No portfolio and no history yet, so the only truthful loss is the
      // feature set itself.
      return _isSw
          ? 'Baada ya $on utarudi kwenye Free: ripoti, nyaraka na ukumbusho wa SMS zitazimwa.'
          : 'After $on you return to Free: reports, documents and SMS reminders switch off.';
    }
    final list = _joinParts(parts);
    return _isSw
        ? 'Baada ya $on: $list. Ripoti pia zitazimwa.'
        : 'After $on: $list. Reports switch off too.';
  }

  String _joinParts(List<String> parts) {
    if (parts.length == 1) return parts.first;
    final and = _isSw ? ' na ' : ' and ';
    return '${parts.sublist(0, parts.length - 1).join(', ')}$and${parts.last}';
  }

  String _money(double amount) {
    if (Get.isRegistered<CurrencyService>()) {
      try {
        return Get.find<CurrencyService>().formatBase(amount);
      } catch (_) {}
    }
    return amount.toStringAsFixed(0);
  }

  static String _planLabel(String plan) {
    switch (plan.trim().toLowerCase()) {
      case 'ultra': return 'Ultra';
      case 'pro': return 'Pro';
      case 'starter': return 'Starter';
      default: return 'Your';
    }
  }

  bool get _isSw => Get.locale?.languageCode == 'sw';
}

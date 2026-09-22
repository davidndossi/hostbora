/// Mirrors the backend Subscription domain entity.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.id,
    required this.plan,
    required this.status,
    this.trialStartAt,
    this.trialEndAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
  });

  /// Sentinel used before the first server fetch completes.
  static const loading = SubscriptionStatus(id: '', plan: 'none', status: 'loading');

  final String id;

  /// "starter" | "pro" | "ultra" | "none"
  final String plan;

  /// "trial" | "active" | "expired" | "cancelled" | "past_due" | "loading"
  final String status;

  final DateTime? trialStartAt;
  final DateTime? trialEndAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;

  /// Trial or paid access that has not passed its end date.
  ///
  /// A stale payload with status trial/active is still inactive once
  /// [trialEndAt] or [currentPeriodEnd] is already in the past. A blank end
  /// date does not lock the user out.
  bool get isActive =>
      (status == 'trial' || status == 'active') && !_accessEnded;

  bool get isTrial => status == 'trial' && !_accessEnded;
  bool get isPaid  => status == 'active' && !_accessEnded;
  bool get isExpired =>
      status == 'expired' ||
      status == 'cancelled' ||
      status == 'past_due' ||
      _accessEnded;

  bool get _accessEnded {
    final now = DateTime.now();
    if (status == 'trial') {
      final end = trialEndAt;
      return end != null && !end.isAfter(now);
    }
    if (status == 'active') {
      final end = currentPeriodEnd;
      return end != null && !end.isAfter(now);
    }
    return false;
  }

  /// isPro or isUltra
  bool get isProOrAbove => plan == 'pro' || plan == 'ultra';
  bool get isUltra => plan == 'ultra';

  /// Days remaining until trial or billing period ends (0 if expired / no date).
  int get daysLeft {
    final end = currentPeriodEnd ?? trialEndAt;
    if (end == null) return 0;
    final d = end.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  /// Human-readable end date display, e.g. "30 Jun 2026".
  String get periodEndDisplay {
    final end = currentPeriodEnd ?? trialEndAt;
    if (end == null) return '';
    return '${end.day} ${_month(end.month)} ${end.year}';
  }

  static String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      id:                 (json['id'] as String?) ?? '',
      plan:               (json['plan'] as String?) ?? 'none',
      status:             (json['status'] as String?) ?? 'expired',
      trialStartAt:       _fromMs(json['trialStartAt']),
      trialEndAt:         _fromMs(json['trialEndAt']),
      currentPeriodStart: _fromMs(json['currentPeriodStart']),
      currentPeriodEnd:   _fromMs(json['currentPeriodEnd']),
    );
  }

  static DateTime? _fromMs(dynamic value) {
    if (value == null) return null;
    final ms = (value as num).toInt();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}

class SubscriptionCheckout {
  const SubscriptionCheckout({
    required this.paymentLinkUrl,
    required this.checkoutUrl,
    required this.reference,
    required this.plan,
    required this.amountTzs,
  });

  final String paymentLinkUrl;
  final String checkoutUrl;
  final String reference;
  final String plan;
  final int amountTzs;

  factory SubscriptionCheckout.fromJson(Map<String, dynamic> json) {
    return SubscriptionCheckout(
      paymentLinkUrl: (json['paymentLinkUrl'] as String?) ?? '',
      checkoutUrl:    (json['checkoutUrl']    as String?) ?? '',
      reference:      (json['reference']      as String?) ?? '',
      plan:           (json['plan']           as String?) ?? '',
      amountTzs:      int.tryParse((json['amountTzs'] as String?) ?? '0') ?? 0,
    );
  }
}

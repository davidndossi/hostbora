import 'package:intl/intl.dart';

/// Display helpers for staff compensation lines and payroll totals.
abstract class RentStaffPayFormat {
  static const monthly = 'monthly';
  static const hourly = 'hourly';
  static const perWork = 'per_work';

  static const paymentTypeLabels = {
    monthly: 'Monthly',
    hourly: 'Per hour',
    perWork: 'Per work done',
  };

  static String amountLine(double value, String paymentType) {
    if (value <= 0) return '—';
    final n = NumberFormat('#,###', 'en_US').format(value.round());
    switch (paymentType) {
      case hourly:
        return '$n Tsh/hr';
      case perWork:
        return '$n Tsh/job';
      default:
        return '$n Tsh/mo';
    }
  }

  static String payDayLine(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    return 'PAY DAY: ${t.toUpperCase()}';
  }

  static String formatPayrollTotal(double total) {
    if (total <= 0) return '0 Tsh';
    final n = NumberFormat('#,###', 'en_US').format(total.round());
    return '$n Tsh';
  }
}

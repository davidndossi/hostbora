import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/service/currency_service.dart';

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

  static CurrencyService? get _currency =>
      Get.isRegistered<CurrencyService>() ? Get.find<CurrencyService>() : null;

  static String _formatNumber(double value) =>
      _currency?.formatNumber(value) ??
      NumberFormat('#,###', 'en_US').format(value.round());

  static String _currencyLabel() =>
      _currency?.inputSuffix ??
      CurrencyService.defaultBaseCurrency;

  static String amountLine(double value, String paymentType) {
    if (value <= 0) return '—';
    final n = _formatNumber(value);
    final code = _currencyLabel();
    switch (paymentType) {
      case hourly:
        return '$n $code/hr';
      case perWork:
        return '$n $code/job';
      default:
        return '$n $code/mo';
    }
  }

  static String payDayLine(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    return 'PAY DAY: ${t.toUpperCase()}';
  }

  static String formatPayrollTotal(double total) {
    if (total <= 0) {
      return _currency?.formatBase(0) ?? '0';
    }
    return _currency?.formatBase(total.round()) ??
        '${_formatNumber(total)} ${_currencyLabel()}';
  }
}

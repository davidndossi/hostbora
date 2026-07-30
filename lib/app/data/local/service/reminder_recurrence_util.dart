import 'package:intl/intl.dart';

/// Preset options shown in the recurrence dropdown.
enum ReminderRecurrencePreset {
  weekly,
  monthlyFirst,
  quarterly,
  custom,
}

extension ReminderRecurrencePresetX on ReminderRecurrencePreset {
  String get apiValue {
    switch (this) {
      case ReminderRecurrencePreset.weekly:
        return 'weekly';
      case ReminderRecurrencePreset.monthlyFirst:
        return 'monthly_first';
      case ReminderRecurrencePreset.quarterly:
        return 'quarterly';
      case ReminderRecurrencePreset.custom:
        return 'custom';
    }
  }

  static ReminderRecurrencePreset fromApi(String raw) {
    switch (RecurrenceRuleCodec.normalize(raw)) {
      case 'weekly':
        return ReminderRecurrencePreset.weekly;
      case 'quarterly':
        return ReminderRecurrencePreset.quarterly;
      case 'monthly_first':
        return ReminderRecurrencePreset.monthlyFirst;
      default:
        if (RecurrenceRuleCodec.isCustom(raw)) {
          return ReminderRecurrencePreset.custom;
        }
        return ReminderRecurrencePreset.monthlyFirst;
    }
  }

  String label(bool isSw) {
    switch (this) {
      case ReminderRecurrencePreset.weekly:
        return isSw ? 'Kila wiki' : 'Every week';
      case ReminderRecurrencePreset.monthlyFirst:
        return isSw ? 'Kila tarehe 1 ya mwezi' : 'Every 1st of the month';
      case ReminderRecurrencePreset.quarterly:
        return isSw ? 'Kila miezi 3' : 'Every 3 months';
      case ReminderRecurrencePreset.custom:
        return isSw ? 'Maalum…' : 'Custom…';
    }
  }
}

/// How a custom recurrence is defined in the UI.
enum CustomRecurrenceMode {
  everyNDays,
  everyNMonths,
  monthlyDayOfMonth,
}

extension CustomRecurrenceModeX on CustomRecurrenceMode {
  String label(bool isSw) {
    switch (this) {
      case CustomRecurrenceMode.everyNDays:
        return isSw ? 'Kila siku N' : 'Every N days';
      case CustomRecurrenceMode.everyNMonths:
        return isSw ? 'Kila miezi N' : 'Every N months';
      case CustomRecurrenceMode.monthlyDayOfMonth:
        return isSw ? 'Kila tarehe N ya mwezi' : 'Every Nth of month';
    }
  }
}

/// Encodes/decodes recurrence rules stored in SQLite and sent to the API.
class RecurrenceRuleCodec {
  static String normalize(String raw) => raw.trim().toLowerCase();

  static bool isOnce(String raw) => normalize(raw) == 'once';

  static bool isRecurring(String raw) => !isOnce(raw);

  static bool isCustom(String raw) {
    final v = normalize(raw);
    return _everyDays.hasMatch(v) ||
        _everyMonths.hasMatch(v) ||
        _monthlyDay.hasMatch(v);
  }

  static int? parseEveryDays(String raw) {
    final m = _everyDays.firstMatch(normalize(raw));
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  static int? parseEveryMonths(String raw) {
    final m = _everyMonths.firstMatch(normalize(raw));
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  static int? parseMonthlyDay(String raw) {
    final m = _monthlyDay.firstMatch(normalize(raw));
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  static final _everyDays = RegExp(r'^every_(\d+)_days$');
  static final _everyMonths = RegExp(r'^every_(\d+)_months$');
  static final _monthlyDay = RegExp(r'^monthly_day_(\d+)$');

  static String encodeCustom({
    required CustomRecurrenceMode mode,
    required int value,
  }) {
    final n = value.clamp(1, 365);
    switch (mode) {
      case CustomRecurrenceMode.everyNDays:
        return 'every_${n}_days';
      case CustomRecurrenceMode.everyNMonths:
        return 'every_${n.clamp(1, 24)}_months';
      case CustomRecurrenceMode.monthlyDayOfMonth:
        return 'monthly_day_${n.clamp(1, 28)}';
    }
  }

  static CustomRecurrenceMode? decodeCustomMode(String raw) {
    final v = normalize(raw);
    if (_everyDays.hasMatch(v)) return CustomRecurrenceMode.everyNDays;
    if (_everyMonths.hasMatch(v)) return CustomRecurrenceMode.everyNMonths;
    if (_monthlyDay.hasMatch(v)) return CustomRecurrenceMode.monthlyDayOfMonth;
    return null;
  }

  static int decodeCustomValue(String raw) {
    final v = normalize(raw);
    final days = _everyDays.firstMatch(v);
    if (days != null) return int.tryParse(days.group(1)!) ?? 7;
    final months = _everyMonths.firstMatch(v);
    if (months != null) return int.tryParse(months.group(1)!) ?? 1;
    final dom = _monthlyDay.firstMatch(v);
    if (dom != null) return int.tryParse(dom.group(1)!) ?? 1;
    return 7;
  }

  static String label(String raw, bool isSw) {
    final v = normalize(raw);
    switch (v) {
      case 'weekly':
        return ReminderRecurrencePreset.weekly.label(isSw);
      case 'monthly_first':
        return ReminderRecurrencePreset.monthlyFirst.label(isSw);
      case 'quarterly':
        return ReminderRecurrencePreset.quarterly.label(isSw);
      case 'once':
        return isSw ? 'Mara moja' : 'Once';
    }
    final days = _everyDays.firstMatch(v);
    if (days != null) {
      final n = days.group(1)!;
      return isSw ? 'Kila siku $n' : 'Every $n days';
    }
    final months = _everyMonths.firstMatch(v);
    if (months != null) {
      final n = months.group(1)!;
      return isSw ? 'Kila miezi $n' : 'Every $n months';
    }
    final dom = _monthlyDay.firstMatch(v);
    if (dom != null) {
      final n = int.tryParse(dom.group(1)!) ?? 1;
      final suffix = _ordinalSuffix(n, isSw);
      return isSw ? 'Kila tarehe $n ya mwezi' : 'Every $suffix of the month';
    }
    return raw;
  }

  static String _ordinalSuffix(int n, bool isSw) {
    if (isSw) return '$n';
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}

class ReminderRecurrenceUtil {
  static DateTime computeNextRun({
    required String recurrence,
    required String timeOfDay,
    DateTime? from,
  }) {
    final base = from ?? DateTime.now();
    final hour = _parseHour(timeOfDay);
    final minute = _parseMinute(timeOfDay);
    final v = RecurrenceRuleCodec.normalize(recurrence);

    if (RecurrenceRuleCodec.isOnce(v)) {
      final candidate = DateTime(base.year, base.month, base.day, hour, minute);
      return candidate.isAfter(base)
          ? candidate
          : candidate.add(const Duration(days: 1));
    }

    if (v == 'weekly') {
      final candidate = DateTime(base.year, base.month, base.day, hour, minute);
      return candidate.isAfter(base)
          ? candidate
          : candidate.add(const Duration(days: 7));
    }
    if (v == 'quarterly') {
      return _advanceMonthlyDay(
        currentRun: base,
        dayOfMonth: 1,
        hour: hour,
        minute: minute,
        monthStep: 3,
      );
    }
    if (v == 'monthly_first') {
      return _nextMonthlyFirst(base, hour, minute);
    }

    final everyDays = RecurrenceRuleCodec.parseEveryDays(v);
    if (everyDays != null) {
      final candidate = DateTime(base.year, base.month, base.day, hour, minute);
      return candidate.isAfter(base)
          ? candidate
          : candidate.add(Duration(days: everyDays));
    }

    final everyMonths = RecurrenceRuleCodec.parseEveryMonths(v);
    if (everyMonths != null) {
      return _advanceMonthlyDay(
        currentRun: base,
        dayOfMonth: base.day.clamp(1, 28),
        hour: hour,
        minute: minute,
        monthStep: everyMonths,
      );
    }

    final monthlyDay = RecurrenceRuleCodec.parseMonthlyDay(v);
    if (monthlyDay != null) {
      return _nextDayOfMonth(base, monthlyDay.clamp(1, 28), hour, minute);
    }

    return _nextMonthlyFirst(base, hour, minute);
  }

  static DateTime advanceAfterSend({
    required String recurrence,
    required String timeOfDay,
    required DateTime currentRun,
  }) {
    final v = RecurrenceRuleCodec.normalize(recurrence);
    if (RecurrenceRuleCodec.isOnce(v)) return currentRun;

    final hour = _parseHour(timeOfDay);
    final minute = _parseMinute(timeOfDay);

    if (v == 'weekly') {
      return currentRun.add(const Duration(days: 7));
    }
    if (v == 'quarterly') {
      return _advanceMonthlyDay(
        currentRun: currentRun,
        dayOfMonth: 1,
        hour: hour,
        minute: minute,
        monthStep: 3,
      );
    }
    if (v == 'monthly_first') {
      return _advanceMonthlyDay(
        currentRun: currentRun,
        dayOfMonth: 1,
        hour: hour,
        minute: minute,
        monthStep: 1,
      );
    }

    final everyDays = RecurrenceRuleCodec.parseEveryDays(v);
    if (everyDays != null) {
      return currentRun.add(Duration(days: everyDays));
    }

    final everyMonths = RecurrenceRuleCodec.parseEveryMonths(v);
    if (everyMonths != null) {
      return _advanceMonthlyDay(
        currentRun: currentRun,
        dayOfMonth: currentRun.day.clamp(1, 28),
        hour: hour,
        minute: minute,
        monthStep: everyMonths,
      );
    }

    final monthlyDay = RecurrenceRuleCodec.parseMonthlyDay(v);
    if (monthlyDay != null) {
      return _advanceMonthlyDay(
        currentRun: currentRun,
        dayOfMonth: monthlyDay.clamp(1, 28),
        hour: hour,
        minute: minute,
        monthStep: 1,
      );
    }

    return _advanceMonthlyDay(
      currentRun: currentRun,
      dayOfMonth: 1,
      hour: hour,
      minute: minute,
      monthStep: 1,
    );
  }

  static String formatDueDate(String recurrence) {
    final fmt = DateFormat('dd/MM/yyyy');
    final next = computeNextRun(recurrence: recurrence, timeOfDay: '09:00');
    return fmt.format(next);
  }

  static DateTime _nextMonthlyFirst(DateTime from, int hour, int minute) {
    return _nextDayOfMonth(from, 1, hour, minute);
  }

  static DateTime _nextDayOfMonth(
    DateTime from,
    int dayOfMonth,
    int hour,
    int minute,
  ) {
    final dom = dayOfMonth.clamp(1, 28);
    final candidate = _safeDate(from.year, from.month, dom, hour, minute);
    if (candidate.isAfter(from)) return candidate;
    if (from.month == 12) {
      return _safeDate(from.year + 1, 1, dom, hour, minute);
    }
    return _safeDate(from.year, from.month + 1, dom, hour, minute);
  }

  static DateTime _advanceMonthlyDay({
    required DateTime currentRun,
    required int dayOfMonth,
    required int hour,
    required int minute,
    required int monthStep,
  }) {
    final dom = dayOfMonth.clamp(1, 28);
    var year = currentRun.year;
    var month = currentRun.month + monthStep;
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    return _safeDate(year, month, dom, hour, minute);
  }

  static DateTime _safeDate(
    int year,
    int month,
    int day,
    int hour,
    int minute,
  ) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final d = day > lastDay ? lastDay : day;
    return DateTime(year, month, d, hour, minute);
  }

  static int _parseHour(String timeOfDay) =>
      int.tryParse(timeOfDay.split(':').first) ?? 9;

  static int _parseMinute(String timeOfDay) {
    final parts = timeOfDay.split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }
}

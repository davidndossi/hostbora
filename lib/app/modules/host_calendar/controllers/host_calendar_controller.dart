import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';
import '../enum/day_type.dart';

class HostCalendarController extends BaseController {
  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  HostCalendarController() {
    selectedDate.value = _today;
    currentMonth.value = DateTime(_today.year, _today.month);
  }

  final selectedDate = Rx<DateTime>(DateTime.now());
  final currentMonth = Rx<DateTime>(DateTime.now());
  final dynamicPricingOn = true.obs;
  final selectedPropertyName = 'The Glass House, Oslo'.obs;

  final properties = ['The Glass House, Oslo', 'Downtown Loft', 'Seaside Villa'];

  /// Blocked dates (not available for booking), stored as 'yyyy-MM-dd'.
  final blockedDates = <String>[].obs;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isDateBlocked(DateTime day) {
    final key = _dateKey(DateTime(day.year, day.month, day.day));
    return blockedDates.contains(key);
  }

  void toggleBlockDate(DateTime day) {
    final key = _dateKey(DateTime(day.year, day.month, day.day));
    if (blockedDates.contains(key)) {
      blockedDates.remove(key);
    } else {
      blockedDates.add(key);
    }
    blockedDates.refresh();
  }

  /// True if [day] is today or in the future (date only).
  bool isDayEnabled(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(_today);
  }

  /// Price or label for a day (e.g. "125k"). Null if not in current month.
  String? priceForDay(DateTime day) {
    if (day.month != currentMonth.value.month) return null;
    final d = day.day;
    if (d >= 6 && d <= 8) return '${145 + (d == 7 ? 5 : 0)}k';
    if (d >= 14 && d <= 16) return '155k';
    if (d == 11) return '125k';
    if (d <= 5) return '${115 + d * 2}k';
    if (d <= 13) return '${120 + (d % 3)}k';
    return '120k';
  }

  DayType typeForDay(DateTime day) {
    if (day.month != currentMonth.value.month) return DayType.standard;
    final d = day.day;
    if (d >= 6 && d <= 8) return DayType.aiOptimized;
    if (d >= 14 && d <= 16) return DayType.manualRate;
    return DayType.standard;
  }

  void goToToday() {
    final now = DateTime.now();
    selectedDate.value = now;
    currentMonth.value = DateTime(now.year, now.month);
  }

  void selectDate(DateTime date) => selectedDate.value = date;

  void setMonth(DateTime month) => currentMonth.value = month;

  void toggleDynamicPricing() => dynamicPricingOn.value = !dynamicPricingOn.value;

  void selectProperty(String name) => selectedPropertyName.value = name;

  /// Events for the selected day (sample data)
  List<CalendarEvent> get eventsForSelectedDay {
    final d = selectedDate.value;
    if (d.day == 11 && d.month == 10) {
      return [
        CalendarEvent(
          type: CalendarEventType.checkOut,
          guestName: 'Marcus Aurelius',
          time: '11:00 AM',
          guests: 2,
          subtitle: 'Cleaning Required',
          subtitleHighlight: true,
        ),
        CalendarEvent(
          type: CalendarEventType.checkIn,
          guestName: 'Elena Gilbert',
          time: '03:00 PM',
          guests: 4,
          subtitle: 'Digital Key Enabled',
          subtitleHighlight: false,
        ),
      ];
    }
    return [];
  }

  String get selectedDayHeader {
    final d = selectedDate.value;
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final name = days[d.weekday - 1];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$name, ${months[d.month - 1]} ${d.day}';
  }
}

enum CalendarEventType { checkIn, checkOut }

class CalendarEvent {
  final CalendarEventType type;
  final String guestName;
  final String time;
  final int guests;
  final String subtitle;
  final bool subtitleHighlight;

  CalendarEvent({
    required this.type,
    required this.guestName,
    required this.time,
    required this.guests,
    required this.subtitle,
    required this.subtitleHighlight,
  });
}

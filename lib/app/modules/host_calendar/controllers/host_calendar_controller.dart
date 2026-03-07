import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';
import '../enum/day_type.dart';

class HostCalendarController extends BaseController {
  final selectedDate = DateTime(2023, 10, 11).obs;
  final currentMonth = DateTime(2023, 10).obs;
  final dynamicPricingOn = true.obs;
  final selectedPropertyName = 'The Glass House, Oslo'.obs;

  final properties = ['The Glass House, Oslo', 'Downtown Loft', 'Seaside Villa'];

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

  void onNavTap(int index) {
    switch (index) {
      case 0:
        Get.offAllNamed(Routes.MAIN);
        break;
      case 1:
        break; // Calendar - current
      case 2:
        break; // TODO: Inbox
      case 3:
        break; // TODO: Profile
    }
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

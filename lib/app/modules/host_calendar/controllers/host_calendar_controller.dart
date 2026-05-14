import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/repository/app_repository.dart';
import '../enum/day_type.dart';

class HostCalendarController extends BaseController {
  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  HostCalendarController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _preferenceManager =
            Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
        _workspaceContext = Get.find<WorkspaceContextService>(),
        _maintenanceLocal = Get.find<RentScheduledMaintenanceLocalDataSource>() {
    selectedDate.value = _today;
    currentMonth.value = DateTime(_today.year, _today.month);
  }

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final PreferenceManager _preferenceManager;
  final WorkspaceContextService _workspaceContext;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;

  final selectedDate = Rx<DateTime>(DateTime.now());
  final currentMonth = Rx<DateTime>(DateTime.now());
  final dynamicPricingOn = true.obs;
  final selectedPropertyName = ''.obs;

  /// Listing display names from local properties + remote listings (BnB workspace).
  final properties = <String>[].obs;
  final loading = false.obs;

  /// Bumped after events are indexed so [Obx] widgets rebuild.
  final calendarRevision = 0.obs;

  final _eventsByDate = <String, List<CalendarEvent>>{}.obs;

  /// Blocked dates (not available for booking), stored as 'yyyy-MM-dd'.
  final blockedDates = <String>[].obs;

  @override
  void onReady() {
    super.onReady();
    loadCalendarData();
  }

  /// Loads property names and indexes bookings plus scheduled maintenance by date.
  Future<void> loadCalendarData() async {
    loading.value = true;
    try {
      final localNames = await _loadLocalPropertyNames();
      final remoteNames = await _loadRemotePropertyNames();
      final merged = <String>{
        ...localNames.where((e) => e.isNotEmpty),
        ...remoteNames.where((e) => e.isNotEmpty),
      }.toList();
      merged.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      properties.assignAll(merged);
      if (selectedPropertyName.value.isEmpty && properties.isNotEmpty) {
        selectedPropertyName.value = properties.first;
      }

      final bookingEvents = await _loadRemoteBookingEvents();
      final maintenanceEvents = await _loadLocalMaintenanceEvents();
      _indexEvents([...bookingEvents, ...maintenanceEvents]);
    } finally {
      loading.value = false;
      calendarRevision.value++;
    }
  }

  Future<List<String>> _loadLocalPropertyNames() async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final workspace = await _workspaceContext.getWorkspaceType();
    final rows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: workspace,
    );
    return rows
        .map((p) => p.propertyName.trim().isNotEmpty
            ? p.propertyName.trim()
            : p.propertyLocation.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<List<String>> _loadRemotePropertyNames() async {
    try {
      final res = await _repository.getMyListings(status: null);
      if (res.responseCode != '0' || res.data == null) return const [];
      final list = _extractListFromResponse(res.data);
      return list
          .map((m) =>
              (m['propertyName'] ?? m['title'] ?? m['name'])?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<CalendarEvent>> _loadRemoteBookingEvents() async {
    try {
      final res = await _repository.getUpcomingBookings();
      if (res.responseCode != '0' || res.data == null) return const [];
      final raw = res.data!['bookings'];
      if (raw is! List) return const [];
      final out = <CalendarEvent>[];
      for (final item in raw.whereType<Map<String, dynamic>>()) {
        final guestName = (item['guestName'] ?? '').toString().trim();
        final propertyName = (item['propertyType'] ?? item['propertyName'] ?? '')
            .toString()
            .trim();
        final guests = (item['numberOfGuests'] as num?)?.toInt() ?? 1;
        final checkIn = _tryDate((item['checkIn'] ?? '').toString());
        final checkOut = _tryDate((item['checkOut'] ?? '').toString());
        if (checkIn != null) {
          out.add(CalendarEvent(
            type: CalendarEventType.checkIn,
            guestName: guestName.isEmpty ? 'Guest' : guestName,
            time: '03:00 PM',
            guests: guests,
            subtitle: 'Digital key enabled',
            subtitleHighlight: false,
            propertyName: propertyName,
            eventDate: checkIn,
          ));
        }
        if (checkOut != null) {
          out.add(CalendarEvent(
            type: CalendarEventType.checkOut,
            guestName: guestName.isEmpty ? 'Guest' : guestName,
            time: '11:00 AM',
            guests: guests,
            subtitle: 'Check-out',
            subtitleHighlight: false,
            propertyName: propertyName,
            eventDate: checkOut,
          ));
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<List<CalendarEvent>> _loadLocalMaintenanceEvents() async {
    final records = await _maintenanceLocal.getAllNewestFirst();
    final out = <CalendarEvent>[];
    for (final r in records) {
      final d = _tryDate(r.scheduledDateIso);
      if (d == null) continue;
      out.add(
        CalendarEvent(
          type: CalendarEventType.maintenance,
          guestName: r.category.isEmpty ? 'Maintenance' : r.category,
          time: '09:00 AM',
          guests: 0,
          subtitle: r.description.isEmpty ? r.priority : r.description,
          subtitleHighlight: false,
          propertyName: r.propertyLabel,
          eventDate: d,
        ),
      );
    }
    return out;
  }

  void _indexEvents(List<CalendarEvent> items) {
    final map = <String, List<CalendarEvent>>{};
    for (final e in items) {
      final key = _dateKey(e.eventDate);
      map.putIfAbsent(key, () => <CalendarEvent>[]).add(e);
    }
    _eventsByDate.value = map;
  }

  DateTime? _tryDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _extractListFromResponse(dynamic data) {
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List).whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map && data['listings'] is List) {
      return (data['listings'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

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

  /// No fabricated nightly rates — cells show day number only unless you add pricing later.
  String? priceForDay(DateTime day) => null;

  int eventsCountForDay(DateTime day) {
    final key = _dateKey(DateTime(day.year, day.month, day.day));
    return _eventsByDate[key]?.length ?? 0;
  }

  DayType typeForDay(DateTime day) {
    if (day.month != currentMonth.value.month) return DayType.standard;
    final count = eventsCountForDay(day);
    if (count >= 2 && dynamicPricingOn.value) return DayType.aiOptimized;
    if (count == 1) return DayType.manualRate;
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

  /// Events for the selected day (bookings + maintenance), filtered by property when possible.
  List<CalendarEvent> get eventsForSelectedDay {
    final key = _dateKey(selectedDate.value);
    final items = _eventsByDate[key] ?? const <CalendarEvent>[];
    final selected = selectedPropertyName.value.trim();
    if (selected.isEmpty) return items;
    final filtered = items
        .where((e) =>
            e.propertyName.trim().isEmpty ||
            e.propertyName.trim() == selected)
        .toList();
    if (filtered.isNotEmpty) return filtered;
    return items;
  }

  String get selectedDayHeader {
    final d = selectedDate.value;
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final name = days[d.weekday - 1];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$name, ${months[d.month - 1]} ${d.day}';
  }
}

enum CalendarEventType { checkIn, checkOut, maintenance }

class CalendarEvent {
  final CalendarEventType type;
  final String guestName;
  final String time;
  final int guests;
  final String subtitle;
  final bool subtitleHighlight;
  /// Listing/property label from the booking payload (filter key).
  final String propertyName;
  final DateTime eventDate;

  CalendarEvent({
    required this.type,
    required this.guestName,
    required this.time,
    required this.guests,
    required this.subtitle,
    required this.subtitleHighlight,
    required this.propertyName,
    required this.eventDate,
  });
}

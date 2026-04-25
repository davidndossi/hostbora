import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_payment_reminder_local_data_source.dart';
import '../../../../data/local/db/rent_property_local_data_source.dart';
import '../../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../../data/local/db/rent_tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/workspace_context_service.dart';
import '../../../../data/repository/app_repository.dart';
import '../enum/day_type.dart';

class RentHostCalendarController extends BaseController {
  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  RentHostCalendarController({
    AppRepository? repository,
    RentPropertyLocalDataSource? propertyLocal,
    RentTenantLocalDataSource? tenantLocal,
    RentScheduledMaintenanceLocalDataSource? maintenanceLocal,
    RentPaymentReminderLocalDataSource? paymentReminderLocal,
    PreferenceManager? preferenceManager,
    WorkspaceContextService? workspaceContext,
  })  : _repository = repository ?? Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = propertyLocal ?? Get.find<RentPropertyLocalDataSource>(),
        _tenantLocal = tenantLocal ?? Get.find<RentTenantLocalDataSource>(),
        _maintenanceLocal =
            maintenanceLocal ?? Get.find<RentScheduledMaintenanceLocalDataSource>(),
        _paymentReminderLocal =
            paymentReminderLocal ?? Get.find<RentPaymentReminderLocalDataSource>(),
        _preferenceManager = preferenceManager ??
            Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
        _workspaceContext = workspaceContext ?? Get.find<WorkspaceContextService>() {
    selectedDate.value = _today;
    currentMonth.value = DateTime(_today.year, _today.month);
  }

  final AppRepository _repository;
  final RentPropertyLocalDataSource _propertyLocal;
  final RentTenantLocalDataSource _tenantLocal;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;
  final RentPaymentReminderLocalDataSource _paymentReminderLocal;
  final PreferenceManager _preferenceManager;
  final WorkspaceContextService _workspaceContext;

  final selectedDate = Rx<DateTime>(DateTime.now());
  final currentMonth = Rx<DateTime>(DateTime.now());
  final dynamicPricingOn = false.obs;
  final selectedPropertyName = ''.obs;

  final properties = <String>[].obs;
  final loading = false.obs;
  final _eventsByDate = <String, List<CalendarEvent>>{}.obs;

  /// Blocked dates (not available for booking), stored as 'yyyy-MM-dd'.
  final blockedDates = <String>[].obs;
  @override
  void onReady() {
    super.onReady();
    loadCalendarData();
  }

  Future<void> loadCalendarData() async {
    loading.value = true;
    try {
      final localPropertyNames = await _loadLocalPropertyNames();
      final remotePropertyNames = await _loadRemotePropertyNames();
      final mergedNames = <String>{
        ...localPropertyNames.where((e) => e.isNotEmpty),
        ...remotePropertyNames.where((e) => e.isNotEmpty),
      }.toList();
      mergedNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      properties.assignAll(mergedNames);
      if (selectedPropertyName.value.isEmpty && properties.isNotEmpty) {
        selectedPropertyName.value = properties.first;
      }

      final localEvents = await _loadLocalTenantEvents();
      final remoteEvents = await _loadRemoteBookingEvents();
      final maintenanceEvents = await _loadLocalMaintenanceEvents();
      final paymentReminderEvents = await _loadLocalPaymentReminderEvents();
      final combined = <CalendarEvent>[
        ...localEvents,
        ...remoteEvents,
        ...maintenanceEvents,
        ...paymentReminderEvents,
      ];
      _indexEvents(combined);
    } finally {
      loading.value = false;
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
        .map((p) => p.apartmentSuite.trim().isNotEmpty
            ? p.apartmentSuite.trim()
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

  /// Same label as [_loadLocalPropertyNames] / property filter so tenant events stay visible.
  static String _hubPropertyName(RentPropertyRecord p) {
    final suite = p.apartmentSuite.trim();
    return suite.isNotEmpty ? suite : p.propertyLocation.trim();
  }

  static String _calendarPropertyNameForTenant(
    RentTenantRecord t,
    List<RentPropertyRecord> visibleProperties,
  ) {
    final ref = t.propertyRef.trim();
    if (ref.isNotEmpty) {
      for (final p in visibleProperties) {
        final legacy = 'legacy_${p.id}';
        final pRef = p.propertyRef.trim().isNotEmpty ? p.propertyRef.trim() : legacy;
        if (pRef == ref || legacy == ref) {
          return _hubPropertyName(p);
        }
      }
    }
    final label = t.propertyLabel.trim();
    const sep = ' · ';
    if (label.contains(sep)) {
      return label.split(sep).last.trim();
    }
    return label;
  }

  Future<List<CalendarEvent>> _loadLocalTenantEvents() async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final workspace = await _workspaceContext.getWorkspaceType();
    final props = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: workspace,
    );

    final tenants = await _tenantLocal.getAllNewestFirst();
    final out = <CalendarEvent>[];
    for (final t in tenants) {
      final propertyName = _calendarPropertyNameForTenant(t, props);
      final checkIn = _tryDate(t.leaseStartIso);
      final checkOut = _tryDate(t.leaseEndIso);
      if (checkIn != null) {
        out.add(CalendarEvent(
          type: CalendarEventType.leaseStart,
          guestName: t.tenantName.isEmpty ? 'Tenant' : t.tenantName,
          time: '03:00 PM',
          guests: 1,
          subtitle: 'Lease start',
          subtitleHighlight: false,
          propertyName: propertyName,
          eventDate: checkIn,
        ));
      }
      if (checkOut != null) {
        out.add(CalendarEvent(
          type: CalendarEventType.leaseEnd,
          guestName: t.tenantName.isEmpty ? 'Tenant' : t.tenantName,
          time: '11:00 AM',
          guests: 1,
          subtitle: 'Lease end',
          subtitleHighlight: false,
          propertyName: propertyName,
          eventDate: checkOut,
        ));
      }
    }
    return out;
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

  Future<List<CalendarEvent>> _loadLocalPaymentReminderEvents() async {
    final currency = NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0);
    final timeFmt = DateFormat('hh:mm a');
    final records = await _paymentReminderLocal.getAllNewestFirst();
    final out = <CalendarEvent>[];
    for (final r in records) {
      final raw = r.reminderAtIso.trim();
      if (raw.isEmpty) continue;
      DateTime? dt;
      try {
        dt = DateTime.parse(raw);
      } catch (_) {
        continue;
      }
      final day = DateTime(dt.year, dt.month, dt.day);
      out.add(
        CalendarEvent(
          type: CalendarEventType.paymentReminder,
          guestName: r.tenantName.isEmpty ? 'Tenant' : r.tenantName,
          time: timeFmt.format(dt),
          guests: 0,
          subtitle: currency.format(r.balanceTsh),
          subtitleHighlight: false,
          propertyName: r.propertyLabel,
          eventDate: day,
        ),
      );
    }
    return out;
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

  /// Price or label for a day (e.g. "125k"). Null if not in current month.
  // String? priceForDay(DateTime day) {
  //   if (day.month != currentMonth.value.month) return null;
  //   final d = day.day;
  //   if (d >= 6 && d <= 8) return '${145 + (d == 7 ? 5 : 0)}k';
  //   if (d >= 14 && d <= 16) return '155k';
  //   if (d == 11) return '125k';
  //   if (d <= 5) return '${115 + d * 2}k';
  //   if (d <= 13) return '${120 + (d % 3)}k';
  //   return '120k';
  // }

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

  void selectProperty(String name) {
    selectedPropertyName.value = name;
  }

  /// Events from online/offline sources, filtered by selected property when available.
  List<CalendarEvent> get eventsForSelectedDay {
    final key = _dateKey(selectedDate.value);
    final items = _eventsByDate[key] ?? const <CalendarEvent>[];
    final selected = selectedPropertyName.value.trim();
    if (selected.isEmpty) return items;
    final filtered = items.where((e) {
      final p = e.propertyName.trim();
      return p.isEmpty || p == selected;
    }).toList();
    if (filtered.isNotEmpty) {
      return filtered;
    }
    return items;
  }

  int eventsCountForDay(DateTime day) {
    final key = _dateKey(DateTime(day.year, day.month, day.day));
    return _eventsByDate[key]?.length ?? 0;
  }

  String get selectedDayHeader {
    final d = selectedDate.value;
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final name = days[d.weekday - 1];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$name, ${months[d.month - 1]} ${d.day}';
  }
}

enum CalendarEventType {
  checkIn,
  checkOut,
  leaseStart,
  leaseEnd,
  maintenance,
  paymentReminder,
}

class CalendarEvent {
  final CalendarEventType type;
  final String guestName;
  final String time;
  final int guests;
  final String subtitle;
  final bool subtitleHighlight;
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

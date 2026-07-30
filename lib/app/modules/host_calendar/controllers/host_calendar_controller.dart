import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/booking_api_response.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/db/rent_payment_reminder_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../add_listing/models/apartment_unit_draft.dart';
import '../enum/day_type.dart';

/// Calendar occupancy for one booking stay.
class _BookingSpan {
  const _BookingSpan({
    required this.bookingKey,
    required this.listingId,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.isCancelled,
    required this.propertyLabel,
  });

  final String bookingKey;
  final String listingId;
  final String unitId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final bool isCancelled;
  final String propertyLabel;
}

class HostCalendarPropertyOption {
  const HostCalendarPropertyOption({
    required this.selectionKey,
    required this.displayName,
    this.record,
  });

  factory HostCalendarPropertyOption.fromRecord(PropertyRecord record) {
    final ref = record.propertyRef.trim();
    final key = ref.isNotEmpty ? ref : 'legacy_${record.id}';
    final name = record.propertyName.trim().isNotEmpty
        ? record.propertyName.trim()
        : record.propertyLocation.trim();
    return HostCalendarPropertyOption(
      selectionKey: key,
      displayName: name,
      record: record,
    );
  }

  factory HostCalendarPropertyOption.remoteOnly(String name) {
    final trimmed = name.trim();
    return HostCalendarPropertyOption(
      selectionKey: 'remote:${trimmed.toLowerCase()}',
      displayName: trimmed,
    );
  }

  final String selectionKey;
  final String displayName;
  final PropertyRecord? record;

  bool get hasLocalRecord => record != null;

  String get hubRef {
    final r = record;
    if (r == null) return '';
    final ref = r.propertyRef.trim();
    return ref.isNotEmpty ? ref : 'legacy_${r.id}';
  }

  bool get isApartment =>
      record?.propertyType.trim().toLowerCase() == 'apartment';

  bool matchesListingId(String listingId) {
    final r = record;
    if (r == null) return false;
    final id = listingId.trim();
    if (id.isEmpty) return false;
    return id == hubRef ||
        id == 'local_${r.id}' ||
        id == 'legacy_${r.id}';
  }
}

class HostCalendarUnitOption {
  const HostCalendarUnitOption({required this.key, required this.label});

  final String key;
  final String label;
}

enum HostCalendarDayBookingStatus { none, bookedUnpaid, bookedPaid }

class HostCalendarController extends BaseController {
  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  HostCalendarController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>(),
        _paymentReminderLocal = Get.find<RentPaymentReminderLocalDataSource>(),
        _preferenceManager =
            Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
        _maintenanceLocal = Get.find<RentScheduledMaintenanceLocalDataSource>(),
        _pendingBookingsStore = PendingBookingsStore(),
        _pendingBookingLoader = BnbBookingPendingLoader(
          syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
        ) {
    selectedDate.value = _today;
    currentMonth.value = DateTime(_today.year, _today.month);
  }

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final PropertyUnitLocalDataSource _unitLocal;
  final IncomeLocalDataSource _incomeLocal;
  final TenantLocalDataSource _tenantLocal;
  final RentPaymentReminderLocalDataSource _paymentReminderLocal;
  final PreferenceManager _preferenceManager;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;
  final PendingBookingsStore _pendingBookingsStore;
  final BnbBookingPendingLoader _pendingBookingLoader;

  final selectedDate = Rx<DateTime>(DateTime.now());
  final currentMonth = Rx<DateTime>(DateTime.now());
  final dynamicPricingOn = false.obs;

  final calendarProperties = <HostCalendarPropertyOption>[].obs;
  final selectedPropertyKey = ''.obs;
  final apartmentUnits = <HostCalendarUnitOption>[].obs;
  final selectedUnitKey = ''.obs;

  final loading = false.obs;
  final calendarRevision = 0.obs;

  final _eventsByDate = <String, List<CalendarEvent>>{}.obs;
  final blockedDates = <String>[].obs;

  final _bookedUnpaidDayKeys = <String>{}.obs;
  final _bookedPaidDayKeys = <String>{}.obs;
  final _paidBookingKeys = <String>{};

  List<_BookingSpan> _bookingSpans = const [];
  List<PropertyRecord> _allLocalProperties = const [];

  @override
  void onReady() {
    super.onReady();
    loadCalendarData();
  }

  HostCalendarPropertyOption? get selectedProperty {
    final key = selectedPropertyKey.value.trim();
    if (key.isEmpty) return null;
    for (final p in calendarProperties) {
      if (p.selectionKey == key) return p;
    }
    return null;
  }

  String get selectedPropertyName => selectedProperty?.displayName ?? '';

  bool get showUnitSelector =>
      selectedProperty?.isApartment == true && apartmentUnits.isNotEmpty;

  Future<void> loadCalendarData() async {
    loading.value = true;
    try {
      await _loadCalendarProperties();
      await _loadBookingsAndIncome();
      final allEvents = <CalendarEvent>[
        ..._allBookingSpansToCalendarEvents(),
        ...await _loadLocalMaintenanceEvents(),
        ...await _loadLocalTenantEvents(),
        ...await _loadLocalPaymentReminderEvents(),
      ];
      _indexEvents(allEvents);
      _rebuildDayMarkers();
    } finally {
      loading.value = false;
      calendarRevision.value++;
    }
  }

  Future<void> _loadCalendarProperties() async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final rowsByKey = <String, PropertyRecord>{};
    for (final workspace in const ['bnb', 'rent']) {
      final rows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: workspace,
      );
      for (final row in rows) {
        final key = row.propertyRef.trim().isNotEmpty
            ? row.propertyRef.trim()
            : 'legacy_${row.id}';
        rowsByKey[key] = row;
      }
    }
    _allLocalProperties = rowsByKey.values.toList();

    final options = _allLocalProperties
        .map(HostCalendarPropertyOption.fromRecord)
        .toList();
    final seenNames = options
        .map((o) => o.displayName.toLowerCase())
        .toSet();

    final remoteNames = await _loadRemotePropertyNames();
    for (final name in remoteNames) {
      final lower = name.toLowerCase();
      if (lower.isEmpty || seenNames.contains(lower)) continue;
      seenNames.add(lower);
      options.add(HostCalendarPropertyOption.remoteOnly(name));
    }

    options.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    calendarProperties.assignAll(options);

    if (calendarProperties.isEmpty) {
      selectedPropertyKey.value = '';
      apartmentUnits.clear();
      selectedUnitKey.value = '';
      return;
    }

    final current = selectedPropertyKey.value.trim();
    if (current.isEmpty ||
        !calendarProperties.any((p) => p.selectionKey == current)) {
      await selectProperty(calendarProperties.first.selectionKey);
    } else {
      await _loadUnitsForSelectedProperty();
    }
  }

  Future<List<String>> _loadRemotePropertyNames() async {
    try {
      final res = await _repository.getMyListings(status: null);
      if (res.responseCode != '0' || res.data == null) return const [];
      final list = _extractListFromResponse(res.data);
      return list
          .map(
            (m) =>
                (m['propertyName'] ?? m['title'] ?? m['name'])
                    ?.toString()
                    .trim() ??
                '',
          )
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<Map<String, dynamic>> _extractListFromResponse(dynamic data) {
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    if (data is Map && data['listings'] is List) {
      return (data['listings'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return const [];
  }

  Future<void> selectProperty(String selectionKey) async {
    selectedPropertyKey.value = selectionKey.trim();
    await _loadUnitsForSelectedProperty();
    _rebuildDayMarkers();
    calendarRevision.value++;
  }

  Future<void> _loadUnitsForSelectedProperty() async {
    final prop = selectedProperty;
    apartmentUnits.clear();
    selectedUnitKey.value = '';
    if (prop == null || !prop.isApartment || prop.record == null) return;

    final seen = <String>{};
    final opts = <HostCalendarUnitOption>[];

    void addUnit(String key, String label) {
      final k = key.trim();
      final name = label.trim();
      if (k.isEmpty || name.isEmpty || seen.contains(k)) return;
      seen.add(k);
      opts.add(HostCalendarUnitOption(key: k, label: name));
    }

    final raw = prop.record!.unitsJson.trim();
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              final draft = ApartmentUnitDraft.fromJson(
                Map<String, dynamic>.from(e),
              );
              addUnit(draft.selectionKey, draft.unitName);
            }
          }
        }
      } catch (_) {}
    }

    if (opts.isEmpty) {
      try {
        final rows = await _unitLocal.getAllByPropertyRefNewestFirstChunked(
          propertyRef: prop.hubRef,
        );
        for (final u in rows) {
          addUnit(u.propertyUnitRef, u.unitName);
        }
      } catch (_) {}
    }

    opts.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    apartmentUnits.assignAll(opts);
    if (opts.isNotEmpty) {
      final prev = selectedUnitKey.value;
      if (prev.isNotEmpty && opts.any((u) => u.key == prev)) {
        selectedUnitKey.value = prev;
      } else {
        selectedUnitKey.value = opts.first.key;
      }
    }
  }

  void selectUnit(String key) {
    selectedUnitKey.value = key;
    _rebuildDayMarkers();
    calendarRevision.value++;
  }

  Future<void> _loadBookingsAndIncome() async {
    final merge = BnbBookingMerge(pending: _pendingBookingsStore);
    final mergedMaps = <String, Map<String, dynamic>>{};
    final paidKeys = <String>{};

    try {
      final incomeRows = await _incomeLocal.getAllNewestFirst(workspaceType: 'bnb');
      for (final row in incomeRows) {
        final key = row.bookingId.trim();
        if (key.isNotEmpty && row.amountValue > 0) {
          paidKeys.add(key);
        }
      }
    } catch (_) {}

    final properties = _allLocalProperties;

    try {
      final res = await _repository.getAllBookings();
      if (BookingApiResponse.isSuccess(res.responseCode)) {
        for (final m in BookingApiResponse.parseBookingsList(res.data)) {
          final normalized = Map<String, dynamic>.from(m);
          final listingId =
              (normalized['listingId'] ?? normalized['propertyId'] ?? '')
                  .toString()
                  .trim();
          final property = _findPropertyForListing(listingId, properties);
          if (property != null) {
            normalized['listingId'] = _hubRefForProperty(property);
          }
          final item = merge.fromApiMap(normalized);
          if (item.isCancelled) continue;
          mergedMaps[item.bookingKey] = normalized;
          if (_isApiPaid(normalized)) paidKeys.add(item.bookingKey);
        }
      }
    } catch (_) {}

    try {
      for (final m in await _pendingBookingLoader.loadAll()) {
        final rawListingId = (m['listingId'] ?? '').toString().trim();
        final checkIn = (m['checkIn'] ?? '').toString();
        final checkOut = (m['checkOut'] ?? '').toString();
        if (rawListingId.isEmpty || checkIn.isEmpty || checkOut.isEmpty) {
          continue;
        }
        final property = _findPropertyForListing(rawListingId, properties);
        final hubListingId = property != null
            ? _hubRefForProperty(property)
            : rawListingId;
        final propertyLabel = property?.propertyName.trim().isNotEmpty == true
            ? property!.propertyName.trim()
            : (property?.propertyLocation ?? 'Property');
        final localId =
            'local_${m['createdAt'] ?? '${rawListingId}_$checkIn'}';
        mergedMaps[localId] = {
          ...m,
          'listingId': hubListingId,
          'bookingId': localId,
          'propertyType': propertyLabel,
          if (m['unitId'] != null) 'unitId': m['unitId'],
        };
      }
    } catch (_) {}

    _paidBookingKeys
      ..clear()
      ..addAll(paidKeys);

    final spans = <_BookingSpan>[];
    for (final entry in mergedMaps.entries) {
      final m = entry.value;
      final item = merge.fromApiMap(m);
      if (item.isCancelled) continue;
      final ci = _tryDate(item.checkInIso);
      if (ci == null) continue;
      final co = _tryDate(item.checkOutIso);
      spans.add(
        _BookingSpan(
          bookingKey: item.bookingKey,
          listingId: (item.listingId ?? '').trim(),
          unitId: (m['unitId'] ?? m['unit_id'] ?? '').toString().trim(),
          checkIn: ci,
          checkOut: co,
          isCancelled: item.isCancelled,
          propertyLabel: item.propertyType.trim(),
        ),
      );
    }
    _bookingSpans = spans;
  }

  static bool _isApiPaid(Map<String, dynamic> m) {
    final status = (m['paymentStatus'] ?? m['payment_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (status == 'paid' || status == 'settled' || status == 'complete') {
      return true;
    }
    final paid = m['isPaid'] ?? m['paid'];
    if (paid is bool && paid) return true;
    return false;
  }

  void _rebuildDayMarkers() {
    final unpaid = <String>{};
    final paid = <String>{};
    final prop = selectedProperty;
    if (prop == null || !prop.hasLocalRecord) {
      _bookedUnpaidDayKeys
        ..clear()
        ..refresh();
      _bookedPaidDayKeys
        ..clear()
        ..refresh();
      return;
    }

    final unitKey = selectedUnitKey.value.trim();

    for (final span in _bookingSpans) {
      if (span.isCancelled) continue;
      if (!_matchesProperty(span, prop)) continue;
      if (prop.isApartment && apartmentUnits.isNotEmpty) {
        if (unitKey.isEmpty || !_matchesUnit(span, unitKey)) continue;
      }

      final isPaid = _paidBookingKeys.contains(span.bookingKey);
      var day = span.checkIn;
      final end = span.checkOut ?? span.checkIn.add(const Duration(days: 1));
      while (day.isBefore(end)) {
        final key = _dateKey(day);
        if (isPaid) {
          paid.add(key);
        } else {
          unpaid.add(key);
        }
        day = day.add(const Duration(days: 1));
      }
    }

    for (final k in paid) {
      unpaid.remove(k);
    }

    _bookedUnpaidDayKeys
      ..clear()
      ..addAll(unpaid);
    _bookedUnpaidDayKeys.refresh();
    _bookedPaidDayKeys
      ..clear()
      ..addAll(paid);
    _bookedPaidDayKeys.refresh();
  }

  static String _hubRefForProperty(PropertyRecord record) {
    final ref = record.propertyRef.trim();
    return ref.isNotEmpty ? ref : 'legacy_${record.id}';
  }

  static PropertyRecord? _findPropertyForListing(
    String listingId,
    List<PropertyRecord> properties,
  ) {
    final id = listingId.trim();
    if (id.isEmpty) return null;
    for (final p in properties) {
      if (p.propertyRef.trim() == id) return p;
      if ('local_${p.id}' == id || 'legacy_${p.id}' == id) return p;
    }
    return null;
  }

  static bool _matchesProperty(
    _BookingSpan span,
    HostCalendarPropertyOption prop,
  ) {
    if (prop.matchesListingId(span.listingId)) return true;
    final label = span.propertyLabel.trim();
    if (label.isNotEmpty && label == prop.displayName) return true;
    final r = prop.record;
    if (r != null) {
      final loc = r.propertyLocation.trim();
      if (label.isNotEmpty && loc.isNotEmpty && label == loc) return true;
    }
    return false;
  }

  static Future<void> refreshIfRegistered() async {
    if (Get.isRegistered<HostCalendarController>()) {
      await Get.find<HostCalendarController>().loadCalendarData();
    }
  }

  static bool _matchesUnit(_BookingSpan span, String unitKey) {
    final uid = span.unitId.trim();
    if (uid.isEmpty) return true;
    return uid == unitKey;
  }

  HostCalendarDayBookingStatus bookingStatusForDay(DateTime day) {
    final key = _dateKey(DateTime(day.year, day.month, day.day));
    if (_bookedPaidDayKeys.contains(key)) {
      return HostCalendarDayBookingStatus.bookedPaid;
    }
    if (_bookedUnpaidDayKeys.contains(key)) {
      return HostCalendarDayBookingStatus.bookedUnpaid;
    }
    return HostCalendarDayBookingStatus.none;
  }

  List<CalendarEvent> _allBookingSpansToCalendarEvents() {
    final out = <CalendarEvent>[];
    for (final span in _bookingSpans) {
      if (span.isCancelled) continue;
      final propertyName = span.propertyLabel.trim().isNotEmpty
          ? span.propertyLabel.trim()
          : 'Property';
      out.add(
        CalendarEvent(
          type: CalendarEventType.checkIn,
          guestName: 'Booking',
          time: '03:00 PM',
          guests: 1,
          subtitle: _paidBookingKeys.contains(span.bookingKey)
              ? 'Paid stay'
              : 'Booked',
          subtitleHighlight: !_paidBookingKeys.contains(span.bookingKey),
          propertyName: propertyName,
          eventDate: span.checkIn,
        ),
      );
      final co = span.checkOut;
      if (co != null) {
        out.add(
          CalendarEvent(
            type: CalendarEventType.checkOut,
            guestName: 'Booking',
            time: '11:00 AM',
            guests: 1,
            subtitle: 'Check-out',
            subtitleHighlight: false,
            propertyName: propertyName,
            eventDate: co,
          ),
        );
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

  Future<List<CalendarEvent>> _loadLocalTenantEvents() async {
    final tenants = await _tenantLocal.getAllNewestFirst();
    final out = <CalendarEvent>[];
    for (final t in tenants) {
      final propertyName =
          _calendarPropertyNameForTenant(t, _allLocalProperties);
      final checkIn = _tryDate(t.leaseStartIso);
      final checkOut = _tryDate(t.leaseEndIso);
      if (checkIn != null) {
        out.add(
          CalendarEvent(
            type: CalendarEventType.leaseStart,
            guestName: t.tenantName.isEmpty ? 'Tenant' : t.tenantName,
            time: '03:00 PM',
            guests: 1,
            subtitle: 'Lease start',
            subtitleHighlight: false,
            propertyName: propertyName,
            eventDate: checkIn,
          ),
        );
      }
      if (checkOut != null) {
        out.add(
          CalendarEvent(
            type: CalendarEventType.leaseEnd,
            guestName: t.tenantName.isEmpty ? 'Tenant' : t.tenantName,
            time: '11:00 AM',
            guests: 1,
            subtitle: 'Lease end',
            subtitleHighlight: false,
            propertyName: propertyName,
            eventDate: checkOut,
          ),
        );
      }
    }
    return out;
  }

  static String _calendarPropertyNameForTenant(
    TenantRecord t,
    List<PropertyRecord> visibleProperties,
  ) {
    final ref = t.propertyRef.trim();
    if (ref.isNotEmpty) {
      for (final p in visibleProperties) {
        final legacy = 'legacy_${p.id}';
        final pRef = p.propertyRef.trim().isNotEmpty
            ? p.propertyRef.trim()
            : legacy;
        if (pRef == ref || legacy == ref) {
          return p.propertyName.trim().isNotEmpty
              ? p.propertyName.trim()
              : p.propertyLocation.trim();
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

  Future<List<CalendarEvent>> _loadLocalPaymentReminderEvents() async {
    final currency = Get.find<CurrencyService>();
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
          subtitle: currency.formatBase(r.balanceTsh),
          subtitleHighlight: false,
          propertyName: r.propertyLabel,
          eventDate: day,
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

  bool isDayEnabled(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(_today);
  }

  String? priceForDay(DateTime day) => null;

  int eventsCountForDay(DateTime day) {
    final key = _dateKey(DateTime(day.year, day.month, day.day));
    return _eventsByDate[key]?.length ?? 0;
  }

  DayType typeForDay(DateTime day) {
    if (bookingStatusForDay(day) != HostCalendarDayBookingStatus.none) {
      return DayType.standard;
    }
    if (!dynamicPricingOn.value) return DayType.standard;
    if (day.month != currentMonth.value.month) return DayType.standard;
    final count = eventsCountForDay(day);
    if (count >= 2) return DayType.aiOptimized;
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

  List<CalendarEvent> get eventsForSelectedDay {
    final key = _dateKey(selectedDate.value);
    final items = _eventsByDate[key] ?? const <CalendarEvent>[];
    final selected = selectedPropertyName.trim();
    if (selected.isEmpty) return items;
    final filtered = items
        .where(
          (e) =>
              e.propertyName.trim().isEmpty ||
              e.propertyName.trim() == selected,
        )
        .toList();
    if (filtered.isNotEmpty) return filtered;
    return items;
  }

  String get selectedDayHeader {
    final d = selectedDate.value;
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final name = days[d.weekday - 1];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '$name, ${months[d.month - 1]} ${d.day}';
  }

  void onOpenCalendarSync() {
    final prop = selectedProperty;
    if (prop == null) {
      showErrorMessage('Select a property first');
      return;
    }
    if (!prop.hasLocalRecord) {
      showErrorMessage('Calendar sync requires a saved local property');
      return;
    }
    final listingId = prop.hubRef.trim();
    if (listingId.isEmpty) {
      showErrorMessage('This property has no listing id for calendar sync');
      return;
    }
    Get.toNamed(
      Routes.CALENDAR_SYNC,
      arguments: {
        'listing_id': listingId,
        'listing_name': prop.displayName,
      },
    );
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

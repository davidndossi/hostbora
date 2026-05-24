import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/bnb_stay_billing.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/repository/app_repository.dart';

/// Visual occupancy state for a unit card (legend + background).
enum UnitOccupancyPalette {
  available,
  occupied,
  reserved,
  maintenance,
  cleaning,
}

/// One unit tile on the occupancy grid.
class UnitOccupancyTileVm {
  UnitOccupancyTileVm({
    required this.unitRef,
    required this.unitNumberLabel,
    required this.typeLine,
    required this.priceLine,
    required this.floorIndex,
    required this.palette,
  });

  final String unitRef;
  final String unitNumberLabel;
  final String typeLine;
  final String priceLine;
  final int floorIndex;
  final UnitOccupancyPalette palette;
}

/// Units grouped for one floor band.
class UnitOccupancyFloorSectionVm {
  UnitOccupancyFloorSectionVm({
    required this.floorIndex,
    required this.tiles,
  });

  final int floorIndex;
  final List<UnitOccupancyTileVm> tiles;
}

/// Internal: merged booking row + optional unit ref from API/pending JSON.
class _ScopedBooking {
  _ScopedBooking({
    required this.item,
    this.unitRef,
    this.apiLooksPending = false,
  });

  final CheckInItem item;
  final String? unitRef;
  /// True when API `status` looks unconfirmed / hold (separate from [CheckInItem.isConfirmed]).
  final bool apiLooksPending;
}

/// Host listing **units occupancy** grid: units from local DB / `units_json`, colors from
/// bookings + optional unit `unitId`, [PropertyUnitRecord.status], and long-stay tenants.
///
/// **Status rules (BnB night model: check-in date ≤ asOf < check-out date):**
/// - **Maintenance / Cleaning**: `PropertyUnitRecord.status` text (maint/repair/out_of_order /
///   clean).
/// - **Reserved**: active overlapping booking and (offline pending OR `!isConfirmed` OR API
///   `status` contains pending/await/hold).
/// - **Occupied**: active overlapping booking and confirmed + not pending; **wins over Reserved**
///   when both apply the same day.
/// - **Available**: otherwise.
///
/// **Gaps:** [CheckInItem] has no unit field. Bookings without `unitId` / fallbacks in the JSON
/// are not mapped to a unit (ignored for per-unit colors). Long-stay [TenantRecord] rows still
/// mark matching units occupied when lease covers [asOf].
class UnitOccupancyController extends BaseController {
  UnitOccupancyController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final PropertyUnitLocalDataSource _unitLocal;
  final TenantLocalDataSource _tenantLocal;

  static final _money = NumberFormat('#,###', 'en_US');

  final loading = true.obs;
  final buildingTitle = ''.obs;
  final floorSections = <UnitOccupancyFloorSectionVm>[].obs;

  /// Defaults to “today” (local calendar).
  final asOf = DateTime.now().obs;

  String get _propertyId =>
      (Get.arguments is Map) ? ((Get.arguments as Map)['property_id'] ?? '').toString().trim() : '';
  String get _propertyName =>
      (Get.arguments is Map) ? ((Get.arguments as Map)['property_name'] ?? '').toString().trim() : '';
  String get _propertyLocation =>
      (Get.arguments is Map) ? ((Get.arguments as Map)['property_location'] ?? '').toString().trim() : '';

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    try {
      final property = await _findLocalPropertyRowForListing();
      final name = property?.propertyName.trim().isNotEmpty == true
          ? property!.propertyName.trim()
          : _propertyName;
      final loc = property?.propertyLocation.trim().isNotEmpty == true
          ? property!.propertyLocation.trim()
          : _propertyLocation;
      buildingTitle.value = name.isNotEmpty ? name : (loc.isNotEmpty ? loc : '—');

      final day = _dateOnly(asOf.value);
      final units = await _loadUnitSources(property);
      final tenants = await _tenantLocal.getAllNewestFirst();
      final listingTenants = tenants.where((t) => _tenantMatchesListing(t, property)).toList();
      final bookings = await _loadScopedBookings(property);

      final tiles = <UnitOccupancyTileVm>[];
      for (final u in units) {
        final palette = _paletteForUnit(
          unit: u,
          asOf: day,
          bookings: bookings,
          tenants: listingTenants,
        );
        tiles.add(
          UnitOccupancyTileVm(
            unitRef: u.unitRef,
            unitNumberLabel: u.unitName,
            typeLine: u.typeLine,
            priceLine: u.priceLine,
            floorIndex: u.floorIndex,
            palette: palette,
          ),
        );
      }

      final byFloor = <int, List<UnitOccupancyTileVm>>{};
      for (final t in tiles) {
        byFloor.putIfAbsent(t.floorIndex, () => []).add(t);
      }
      final floors = byFloor.keys.toList()..sort();
      floorSections.assignAll(
        floors.map((f) => UnitOccupancyFloorSectionVm(floorIndex: f, tiles: byFloor[f]!)),
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> reloadOccupancy() => loadAll();

  Future<PropertyRecord?> _findLocalPropertyRowForListing() async {
    try {
      final rows = await _propertyLocal.getAllNewestFirst();
      if (rows.isEmpty) return null;
      PropertyRecord? target;
      if (_propertyId.isNotEmpty) {
        for (final r in rows) {
          final localId = 'local_${r.id}';
          final legacyId = 'legacy_${r.id}';
          if (r.propertyRef.trim() == _propertyId ||
              localId == _propertyId ||
              legacyId == _propertyId) {
            target = r;
            break;
          }
        }
      }
      target ??= rows.firstWhereOrNull(
        (r) => _propertyName.isNotEmpty && r.apartmentSuite.trim() == _propertyName,
      );
      target ??= rows.firstWhereOrNull(
        (r) => _propertyName.isNotEmpty && r.propertyLocation.trim() == _propertyName,
      );
      return target;
    } catch (_) {
      return null;
    }
  }

  bool _tenantMatchesListing(TenantRecord t, PropertyRecord? row) {
    final listingRef = row?.propertyRef.trim().isNotEmpty == true
        ? row!.propertyRef.trim()
        : (_propertyId.isNotEmpty ? _propertyId : '');
    final ref = t.propertyRef.trim();
    if (listingRef.isNotEmpty && ref.isNotEmpty && ref == listingRef) return true;
    final labelLc = t.propertyLabel.trim().toLowerCase();
    if (_propertyName.isNotEmpty && labelLc.contains(_propertyName.toLowerCase())) return true;
    if (_propertyLocation.isNotEmpty && labelLc.contains(_propertyLocation.toLowerCase())) {
      return true;
    }
    final suite = row?.apartmentSuite.trim() ?? '';
    if (suite.isNotEmpty && labelLc.contains(suite.toLowerCase())) return true;
    return false;
  }

  Future<List<_UnitSource>> _loadUnitSources(PropertyRecord? row) async {
    final refs = <String>{};
    if (_propertyId.isNotEmpty) refs.add(_propertyId);
    if (row != null) {
      if (row.propertyRef.trim().isNotEmpty) refs.add(row.propertyRef.trim());
      refs.add('local_${row.id}');
      refs.add('legacy_${row.id}');
    }

    final fromDb = <PropertyUnitRecord>[];
    for (final r in refs) {
      fromDb.addAll(await _unitLocal.getAllByPropertyRefNewestFirstChunked(propertyRef: r));
    }
    final dedupDb = <String, PropertyUnitRecord>{};
    for (final u in fromDb) {
      final key = u.propertyUnitRef.trim().isNotEmpty ? u.propertyUnitRef.trim() : u.unitName;
      dedupDb[key] = u;
    }
    if (dedupDb.isNotEmpty) {
      return dedupDb.values
          .map(
            (u) => _UnitSource(
              unitRef: u.propertyUnitRef.trim().isNotEmpty ? u.propertyUnitRef.trim() : u.unitName,
              unitName: u.unitName.trim().isNotEmpty ? u.unitName.trim() : u.propertyUnitRef,
              floorIndex: u.floor,
              typeLine: _typeLineFromUnitStatus(u, row?.propertyType ?? ''),
              priceLine: u.rentAmount > 0 ? _money.format(u.rentAmount.round()) : '—',
              dbStatus: u.status,
            ),
          )
          .toList();
    }

    if (row != null && row.unitsJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(row.unitsJson);
        if (decoded is List) {
          final out = <_UnitSource>[];
          for (final e in decoded.whereType<Map>()) {
            final m = Map<String, dynamic>.from(e);
            final unitName = (m['unitName'] ?? m['name'] ?? '').toString().trim();
            if (unitName.isEmpty) continue;
            final unitRef = (m['unitId'] ?? m['id'] ?? unitName).toString().trim();
            final rentRaw = (m['unitRent'] ?? m['rent'] ?? m['price'] ?? '').toString().replaceAll(',', '');
            final rent = double.tryParse(rentRaw) ?? 0;
            final floor = PropertyUnitFloor.parse(m['unitFloor']);
            out.add(
              _UnitSource(
                unitRef: unitRef,
                unitName: unitName,
                floorIndex: floor,
                typeLine: () {
                  final raw =
                      (m['unitType'] ?? m['type'] ?? row.propertyType).toString().trim();
                  final up = raw.toUpperCase();
                  return up.isEmpty ? 'UNIT' : up;
                }(),
                priceLine: rent > 0 ? _money.format(rent.round()) : '—',
                dbStatus: '',
              ),
            );
          }
          if (out.isNotEmpty) return out;
        }
      } catch (_) {}
    }

    if (row != null) {
      final label = row.apartmentSuite.trim().isNotEmpty ? row.apartmentSuite.trim() : row.propertyLocation.trim();
      if (label.isNotEmpty) {
        final rent = double.tryParse(row.rentAmount.replaceAll(',', '')) ?? 0;
        return [
          _UnitSource(
            unitRef: 'main',
            unitName: label,
            floorIndex: PropertyUnitFloor.ground,
            typeLine: () {
              final t = row.propertyType.trim().toUpperCase();
              return t.isEmpty ? 'UNIT' : t;
            }(),
            priceLine: rent > 0 ? _money.format(rent.round()) : '—',
            dbStatus: '',
          ),
        ];
      }
    }
    return const [];
  }

  String _typeLineFromUnitStatus(PropertyUnitRecord u, String propertyType) {
    final n = u.notes.trim();
    if (n.isNotEmpty) return n.toUpperCase();
    final t = propertyType.trim();
    if (t.isNotEmpty) return t.toUpperCase();
    return 'UNIT';
  }

  Future<List<_ScopedBooking>> _loadScopedBookings(PropertyRecord? row) async {
    final merge = BnbBookingMerge(pending: PendingBookingsStore());
    final merged = <String, _ScopedBooking>{};

    void put(String key, _ScopedBooking b) => merged[key] = b;

    try {
      final res = await _repository.getAllBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (res.responseCode == '0' && data is Map && data['bookings'] is List) {
        rows = data['bookings'] as List;
      } else if (res.responseCode == '0' && data is List) {
        rows = data;
      }
      for (final e in rows.whereType<Map>()) {
        final m = Map<String, dynamic>.from(e);
        if (!_listingIdMatches(m['listingId'] ?? m['propertyId'], row)) continue;
        final item = merge.fromApiMap(m);
        final unitRef = _unitRefFromBookingMap(m);
        final statusLc = (m['status'] ?? '').toString().toLowerCase();
        final apiLooksPending = statusLc.contains('pending') ||
            statusLc.contains('await') ||
            statusLc.contains('hold');
        put(
          item.bookingKey,
          _ScopedBooking(item: item, unitRef: unitRef, apiLooksPending: apiLooksPending),
        );
      }
    } catch (_) {}

    try {
      final properties = await _propertyLocal.getAllVisibleNewestFirst(userId: '', workspaceType: 'bnb');
      for (final m in PendingBookingsStore().load()) {
        final listingId = (m['listingId'] ?? '').toString().trim();
        if (!_listingIdMatches(listingId, row)) continue;
        final property = properties.firstWhereOrNull(
          (p) => p.propertyRef.trim() == listingId || 'local_${p.id}' == listingId,
        );
        final propertyLabel = property?.propertyName.trim().isNotEmpty == true
            ? property!.propertyName.trim()
            : (property?.propertyLocation ?? 'Property');
        final localId = 'local_${m['createdAt'] ?? '${listingId}_${m['checkIn']}'}';
        final item = merge.fromPendingMap(m, propertyLabel: propertyLabel, localId: localId);
        final unitRef = _unitRefFromBookingMap(m);
        put(localId, _ScopedBooking(item: item, unitRef: unitRef, apiLooksPending: true));
      }
    } catch (_) {}

    return merged.values.toList();
  }

  bool _listingIdMatches(dynamic rawListingId, PropertyRecord? row) {
    final lid = rawListingId?.toString().trim() ?? '';
    if (lid.isEmpty) return false;
    if (_propertyId.isNotEmpty && lid == _propertyId) return true;
    if (row != null) {
      if (row.propertyRef.trim().isNotEmpty && lid == row.propertyRef.trim()) return true;
      if (lid == 'local_${row.id}') return true;
    }
    return false;
  }

  static String? _unitRefFromBookingMap(Map<String, dynamic> m) {
    for (final k in ['unitId', 'propertyUnitRef', 'unitRef', 'roomId', 'apartmentUnitId']) {
      final v = (m[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  UnitOccupancyPalette _paletteForUnit({
    required _UnitSource unit,
    required DateTime asOf,
    required List<_ScopedBooking> bookings,
    required List<TenantRecord> tenants,
  }) {
    final st = unit.dbStatus.toLowerCase();
    if (st.contains('maint') || st.contains('repair') || st.contains('out_of_order')) {
      return UnitOccupancyPalette.maintenance;
    }
    if (st.contains('clean')) {
      return UnitOccupancyPalette.cleaning;
    }

    final unitBookings = bookings.where((b) {
      final r = b.unitRef?.trim() ?? '';
      if (r.isEmpty) return false;
      return r == unit.unitRef ||
          r.toLowerCase() == unit.unitName.toLowerCase();
    }).toList();

    final fromBookings = _paletteFromBookings(unitBookings, asOf);
    if (fromBookings != null) return fromBookings;

    for (final t in tenants) {
      if (!_tenantCoversDayOnUnit(t, unit, asOf)) continue;
      return UnitOccupancyPalette.occupied;
    }

    return UnitOccupancyPalette.available;
  }

  /// **Occupied** wins over **Reserved** when both overlap the same day.
  UnitOccupancyPalette? _paletteFromBookings(List<_ScopedBooking> unitBookings, DateTime asOf) {
    var reserved = false;
    for (final b in unitBookings) {
      if (!_stayContainsDay(b.item, asOf) || b.item.isInactive) continue;
      final pend = b.item.isLocalPending ||
          !b.item.isConfirmed ||
          b.apiLooksPending;
      if (!pend) return UnitOccupancyPalette.occupied;
      reserved = true;
    }
    return reserved ? UnitOccupancyPalette.reserved : null;
  }

  bool _stayContainsDay(CheckInItem item, DateTime day) {
    final d = _dateOnly(day);
    final ci = DateTime.tryParse(item.checkInIso.trim());
    final co = DateTime.tryParse(item.checkOutIso.trim());
    if (ci == null || co == null) return false;
    final a = _dateOnly(ci);
    final b = _dateOnly(co);
    return !d.isBefore(a) && d.isBefore(b);
  }

  bool _tenantCoversDayOnUnit(TenantRecord t, _UnitSource unit, DateTime day) {
    final tid = t.apartmentUnitId.trim();
    final tlabel = t.unitLabel.trim();
    final matchesUnit = (tid.isNotEmpty && tid == unit.unitRef) ||
        (tlabel.isNotEmpty && tlabel.toLowerCase() == unit.unitName.toLowerCase());
    if (!matchesUnit) return false;
    final ls = _parseTenantLeaseStartDate(t);
    final le = _parseTenantLeaseEndDate(t);
    if (ls == null || le == null) return false;
    return BnbStayBilling.dayInStay(day, ls, le);
  }

  DateTime? _parseTenantLeaseStartDate(TenantRecord t) {
    final raw = t.leaseStartIso.trim();
    try {
      if (raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(t.createdAtMs);
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(t.createdAtMs);
    }
  }

  DateTime? _parseTenantLeaseEndDate(TenantRecord t) {
    final raw = t.leaseEndIso.trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _UnitSource {
  _UnitSource({
    required this.unitRef,
    required this.unitName,
    required this.floorIndex,
    required this.typeLine,
    required this.priceLine,
    required this.dbStatus,
  });

  final String unitRef;
  final String unitName;
  final int floorIndex;
  final String typeLine;
  final String priceLine;
  final String dbStatus;
}

import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../model/check_in_item.dart';
import '../../repository/app_repository.dart';
import '../bnb_booking_merge.dart';
import '../bnb_booking_pending_loader.dart';
import '../pending_bookings_store.dart';
import '../db/expense_local_data_source.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/income_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/rent_scheduled_maintenance_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import '../preference/preference_manager.dart';
import 'portfolio_ai_context.dart';
import 'workspace_context_service.dart';

class PortfolioAiContextService extends GetxService {
  PortfolioAiContextService({
    required PropertyLocalDataSource propertyLocal,
    required TenantLocalDataSource tenantLocal,
    required IncomeLocalDataSource incomeLocal,
    required ExpenseLocalDataSource expenseLocal,
    required RentScheduledMaintenanceLocalDataSource maintenanceLocal,
    required WorkspaceContextService workspaceContext,
    required PreferenceManager preferenceManager,
    required AppRepository repository,
    BnbBookingPendingLoader? pendingBookingLoader,
    PendingBookingsStore? pendingBookingsStore,
  })  : _propertyLocal = propertyLocal,
        _tenantLocal = tenantLocal,
        _incomeLocal = incomeLocal,
        _expenseLocal = expenseLocal,
        _maintenanceLocal = maintenanceLocal,
        _workspaceContext = workspaceContext,
        _preferenceManager = preferenceManager,
        _repository = repository,
        _pendingBookingLoader = pendingBookingLoader ??
            BnbBookingPendingLoader(
              syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
            ),
        _pendingStore = pendingBookingsStore ?? PendingBookingsStore();

  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;
  final WorkspaceContextService _workspaceContext;
  final PreferenceManager _preferenceManager;
  final AppRepository _repository;
  final BnbBookingPendingLoader _pendingBookingLoader;
  final PendingBookingsStore _pendingStore;

  static final _monthFmt = DateFormat('MMMM yyyy');

  Future<PortfolioAiContext> build() async {
    final ws = await _workspaceContext.getWorkspaceType();
    final userId = ((await _preferenceManager.getUser()).id ?? '').trim();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final threshold30 = today.add(const Duration(days: 30));

    final properties = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: ws,
    );

    var totalUnits = 0;
    final names = <String>[];
    for (final p in properties) {
      totalUnits += _unitCountForProperty(p);
      final label = _propertyLabel(p);
      if (label.isNotEmpty) names.add(label);
    }
    if (totalUnits <= 0 && properties.isNotEmpty) {
      totalUnits = properties.length;
    }

    final incomes =
        await _incomeLocal.getAllNewestFirst(workspaceType: ws);
    final expenses =
        await _expenseLocal.getAllNewestFirst(workspaceType: ws);

    var monthIncome = 0.0;
    var monthExpenses = 0.0;
    for (final r in incomes) {
      final d = r.paidLocalCalendarOrCreated();
      if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
        monthIncome += r.amountValue;
      }
    }
    for (final r in expenses) {
      final d = r.paidLocalCalendarOrCreated();
      if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
        monthExpenses += r.amountValue;
      }
    }

    final tenants = await _tenantLocal.getAllNewestFirstByWorkspace(ws);
    var activeTenants = 0;
    var leasesExpiring = 0;
    var arrearsCount = 0;
    var arrearsTotal = 0.0;
    var occupiedUnits = 0;

    for (final t in tenants) {
      final start = _parseDay(t.leaseStartIso);
      final end = _parseDay(t.leaseEndIso) ??
          DateTime(now.year + 50, 12, 31);
      final active = start != null &&
          !start.isAfter(today) &&
          !end.isBefore(today);
      if (active) {
        activeTenants++;
        occupiedUnits++;
      }
      if (end.isAfter(today) || end.isAtSameMomentAs(today)) {
        if (!end.isAfter(threshold30)) leasesExpiring++;
      }

      final spentMonths = _monthsBetween(start ?? today, today).clamp(0, 240);
      final totalMonths = _monthsBetween(
        start ?? today,
        end,
      ).clamp(1, 240);
      final totalAmount = t.rentAmountValue * totalMonths;
      final paid = _sumIncomeForTenant(t, incomes);
      final expected =
          (t.rentAmountValue * spentMonths).clamp(0, totalAmount);
      final gap = (expected - paid).clamp(0, double.infinity);
      if (gap > 0.01 && active) {
        arrearsCount++;
        arrearsTotal += gap;
      }
    }

    var activeBookings = 0;
    var checkInsToday = 0;
    var checkOutsToday = 0;

    if (ws == 'bnb') {
      final bookings = await _loadActiveBnbBookings(userId: userId);
      for (final b in bookings) {
        final ci = _parseDay(b.checkInIso);
        final co = _parseDay(b.checkOutIso);
        if (ci == null || co == null) continue;
        if (_stayOverlapsDay(ci, co, today)) activeBookings++;
        if (ci == today) checkInsToday++;
        if (co == today) checkOutsToday++;
      }
      if (totalUnits > 0) {
        occupiedUnits = activeBookings.clamp(0, totalUnits);
      } else {
        occupiedUnits = activeBookings;
      }
    }

    final occupancy = totalUnits > 0
        ? ((occupiedUnits / totalUnits) * 100).clamp(0.0, 100.0)
        : (activeTenants > 0 ? 100.0 : 0.0);

    var maintenance = 0;
    if (ws == 'rent') {
      try {
        maintenance = (await _maintenanceLocal.getAllNewestFirst()).length;
      } catch (_) {}
    }

    return PortfolioAiContext(
      workspace: ws,
      monthLabel: _monthFmt.format(now),
      propertyCount: properties.length,
      totalUnits: totalUnits,
      occupiedUnits: occupiedUnits,
      occupancyPercent: occupancy,
      activeTenants: activeTenants,
      monthIncome: monthIncome,
      monthExpenses: monthExpenses,
      monthNet: monthIncome - monthExpenses,
      arrearsTenantCount: arrearsCount,
      arrearsTotal: arrearsTotal,
      leasesExpiring30Days: leasesExpiring,
      activeBookingsToday: activeBookings,
      checkInsToday: checkInsToday,
      checkOutsToday: checkOutsToday,
      maintenanceTasks: maintenance,
      propertyNames: names.take(8).toList(),
    );
  }

  Future<List<CheckInItem>> _loadActiveBnbBookings({required String userId}) async {
    final merge = BnbBookingMerge(pending: _pendingStore);
    final merged = <String, CheckInItem>{};
    try {
      final res = await _repository.getUpcomingBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (res.responseCode == '0' && data is Map && data['bookings'] is List) {
        rows = data['bookings'] as List;
      } else if (res.responseCode == '0' && data is List) {
        rows = data;
      }
      for (final e in rows.whereType<Map>()) {
        final item = merge.fromApiMap(Map<String, dynamic>.from(e));
        if (item.isInactive) continue;
        merged[item.bookingKey] = item;
      }
    } catch (_) {}

    try {
      final properties = await _propertyLocal.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: 'bnb',
      );
      await mergePendingBnbBookings(
        merge: merge,
        merged: merged,
        properties: properties,
        loader: _pendingBookingLoader,
      );
    } catch (_) {}

    return merged.values.toList();
  }

  static int _unitCountForProperty(PropertyRecord r) {
    if (r.unitsJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(r.unitsJson);
        if (decoded is List && decoded.isNotEmpty) return decoded.length;
      } catch (_) {}
    }
    final u = r.units;
    return u > 0 ? u : 1;
  }

  static String _propertyLabel(PropertyRecord r) {
    final suite = r.propertyName.trim();
    final loc = r.propertyLocation.trim();
    if (suite.isNotEmpty && loc.isNotEmpty) return '$loc · $suite';
    return suite.isNotEmpty ? suite : loc;
  }

  static DateTime? _parseDay(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.length >= 10 && t[4] == '-' && t[7] == '-') {
      final y = int.tryParse(t.substring(0, 4));
      final m = int.tryParse(t.substring(5, 7));
      final d = int.tryParse(t.substring(8, 10));
      if (y != null &&
          m != null &&
          d != null &&
          m >= 1 &&
          m <= 12 &&
          d >= 1 &&
          d <= 31) {
        return DateTime(y, m, d);
      }
    }
    final p = DateTime.tryParse(t);
    if (p == null) return null;
    return DateTime(p.year, p.month, p.day);
  }

  static bool _stayOverlapsDay(DateTime checkIn, DateTime checkOut, DateTime day) {
    return !checkIn.isAfter(day) && checkOut.isAfter(day);
  }

  static int _monthsBetween(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  static double _sumIncomeForTenant(
    TenantRecord tenant,
    List<IncomeRecord> incomeRows,
  ) {
    var sum = 0.0;
    for (final row in incomeRows) {
      if (_incomeRowMatchesTenant(row, tenant)) sum += row.amountValue;
    }
    return sum;
  }

  static bool _incomeRowMatchesTenant(IncomeRecord income, TenantRecord tenant) {
    if (income.tenantName.trim().toLowerCase() !=
        tenant.tenantName.trim().toLowerCase()) {
      return false;
    }
    final tenantRef = tenant.propertyRef.trim();
    final incomeRef = income.propertyRef.trim();
    if (tenantRef.isNotEmpty &&
        incomeRef.isNotEmpty &&
        tenantRef != incomeRef) {
      return false;
    }
    final pl = tenant.propertyLabel.trim().toLowerCase();
    if (pl.isEmpty) return true;
    final ap = income.apartment.trim().toLowerCase();
    final unit = income.apartmentUnit.trim().toLowerCase();
    final notes = income.notes.trim().toLowerCase();
    final blob = '$ap $unit $notes'.trim();
    return blob.contains(pl) || pl.contains(ap) || ap == pl;
  }
}

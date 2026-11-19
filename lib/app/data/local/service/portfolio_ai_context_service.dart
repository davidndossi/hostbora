import 'package:get/get.dart';

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
import 'portfolio_ai_context_assembler.dart';
import 'portfolio_ai_remote_overlay.dart';
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
    PortfolioAiRemoteOverlayLoader? remoteOverlayLoader,
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
        _pendingStore = pendingBookingsStore ?? PendingBookingsStore(),
        _remoteOverlayLoader =
            remoteOverlayLoader ?? PortfolioAiRemoteOverlayLoader(repository);

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
  final PortfolioAiRemoteOverlayLoader _remoteOverlayLoader;

  Future<PortfolioAiContext> build() async {
    final ws = await _workspaceContext.getWorkspaceType();
    final userId = ((await _preferenceManager.getUser()).id ?? '').trim();
    final allWorkspaces = ws.isEmpty || ws == 'all';

    final propertiesF = _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: ws,
    );
    final incomesF = allWorkspaces
        ? _incomeLocal.getAllNewestFirst()
        : _incomeLocal.getAllNewestFirst(workspaceType: ws);
    final expensesF = allWorkspaces
        ? _expenseLocal.getAllNewestFirst()
        : _expenseLocal.getAllNewestFirst(workspaceType: ws);
    final tenantsF = allWorkspaces
        ? _tenantLocal.getAllNewestFirst()
        : _tenantLocal.getAllNewestFirstByWorkspace(ws);
    final bookingsF = ws == 'bnb'
        ? _loadActiveBnbBookings(userId: userId)
        : Future<List<CheckInItem>>.value(const []);
    final maintenanceF = ws == 'rent'
        ? _maintenanceCount()
        : Future<int>.value(0);

    final properties = await propertiesF;
    final incomes = await incomesF;
    final expenses = await expensesF;
    final tenants = await tenantsF;
    final bookings = await bookingsF;
    final maintenance = await maintenanceF;

    final overlay = await _loadOverlay(incomes: incomes, expenses: expenses);

    return PortfolioAiContextAssembler.assemble(
      workspace: ws,
      properties: properties,
      tenants: tenants,
      incomes: [...incomes, ...overlay.extraIncomes],
      expenses: [...expenses, ...overlay.extraExpenses],
      bookings: bookings,
      maintenanceTasks: maintenance,
      remoteActiveBookings: overlay.remoteActiveBookings,
      includedRemote: !overlay.isEmpty,
    );
  }

  Future<PortfolioAiRemoteOverlay> _loadOverlay({
    required List<IncomeRecord> incomes,
    required List<ExpenseRecord> expenses,
  }) async {
    try {
      return await _remoteOverlayLoader.load(
        localPaymentIds: {
          for (final r in incomes)
            if (r.backendPaymentId.trim().isNotEmpty) r.backendPaymentId.trim(),
        },
        localExpenseIds: {
          for (final r in expenses)
            if (r.backendExpenseId.trim().isNotEmpty) r.backendExpenseId.trim(),
        },
      );
    } catch (_) {
      return const PortfolioAiRemoteOverlay();
    }
  }

  Future<int> _maintenanceCount() async {
    try {
      return (await _maintenanceLocal.getAllNewestFirst()).length;
    } catch (_) {
      return 0;
    }
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
}

import 'dart:convert';

import 'package:get/get.dart';

import '../../../core/utils/sync_freshness.dart';
import '../../../modules/maintenance_tasks/model/maintenance_task.dart';
import '../../../modules/maintenance_tasks/task_assignment_store.dart';
import '../../model/add_expense_request.dart';
import '../../model/cancel_booking_request.dart';
import '../../model/checkout_booking_request.dart';
import '../../model/record_payment_request.dart';
import '../../model/update_booking_request.dart';
import '../../model/update_calendar_subscription_request.dart';
import '../../repository/app_repository.dart';
import '../../service/subscription_service.dart';
import '../bnb_booking_overrides_store.dart';
import '../db/expense_local_data_source.dart';
import '../db/income_local_data_source.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/synced_entity_store.dart';
import '../preference/preference_manager.dart';

/// Pulls bookings, expenses, incomes, tasks, calendar subscriptions, and
/// subscription status. The newer edit wins on each row.
class AccountRecencySync {
  AccountRecencySync({
    required AppRepository repository,
    required OfflineSyncQueueLocalDataSource syncQueue,
  })  : _repository = repository,
        _syncQueue = syncQueue;

  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final SyncedEntityStore _mirror = SyncedEntityStore();

  Future<void> run() async {
    await syncBookings();
    await syncExpenses();
    await syncIncomes();
    await syncTasks();
    await syncCalendarSubscriptions();
    await syncSubscriptionStatus();
  }

  Future<void> syncBookings() async {
    try {
      final res = await _repository.getAllBookings(size: 200);
      if (res.data == null) return;
      if (!res.isSuccess && res.responseCode != null) return;
      await reconcileBookings(_extractMaps(res.data));
    } catch (_) {}
  }

  /// Writes server bookings onto the phone, and pushes a newer phone override.
  Future<void> reconcileBookings(List<Map<String, dynamic>> remoteMaps) async {
    final overrides = BnbBookingOverridesStore();
    for (final map in remoteMaps) {
      try {
        await _reconcileBooking(map, overrides);
      } catch (_) {}
    }
  }

  Future<void> _reconcileBooking(
    Map<String, dynamic> map,
    BnbBookingOverridesStore overrides,
  ) async {
    final remoteUpdated = SyncFreshness.fromMap(map);
    final bookingId = _firstText(map, const ['bookingId', 'id', 'booking_id']);
    if (bookingId.isEmpty) return;
    final guestKey =
        '${_firstText(map, const ['guestName'])}_${_firstText(map, const ['checkIn'])}';
    final keys = <String>{
      bookingId,
      if (guestKey != '_') guestKey,
    };
    String? winningKey;
    for (final key in keys) {
      if (overrides.winsOver(key, remoteUpdated)) {
        winningKey = key;
        break;
      }
    }
    if (winningKey != null) {
      final override = overrides.get(winningKey) ?? const <String, dynamic>{};
      final localMs = SyncFreshness.millis(override['updatedAtMs']);
      final payload = Map<String, dynamic>.from(map);
      final status = override['status']?.toString() ?? '';
      if (status.isNotEmpty) payload['status'] = status;
      final checkOut = override['checkOut']?.toString().trim() ?? '';
      if (checkOut.isNotEmpty) payload['checkOut'] = checkOut;
      await _mirror.saveLocal(
        entityType: SyncedEntityStore.bookingType,
        entityKey: bookingId,
        payload: payload,
        localUpdatedAtMs: localMs > 0 ? localMs : DateTime.now().millisecondsSinceEpoch,
        remoteUpdatedAtMs: remoteUpdated,
      );
      await _pushBookingOverride(
        bookingId: bookingId,
        remoteCheckOut: _firstText(map, const ['checkOut']),
        override: override,
      );
      return;
    }
    await _mirror.saveRemoteIfNotOlder(
      entityType: SyncedEntityStore.bookingType,
      entityKey: bookingId,
      payload: map,
      remoteUpdatedAtMs: remoteUpdated,
    );
  }

  Future<void> _pushBookingOverride({
    required String bookingId,
    required String remoteCheckOut,
    required Map<String, dynamic> override,
  }) async {
    final status = override['status']?.toString() ?? '';
    try {
      if (status == 'cancelled') {
        await _repository.cancelBooking(
          CancelBookingRequest(bookingId: bookingId),
        );
      } else if (status == 'checked_out') {
        await _repository.checkoutBooking(
          CheckoutBookingRequest(bookingId: bookingId),
        );
      }
      final checkOut = override['checkOut']?.toString().trim() ?? '';
      if (checkOut.isNotEmpty && checkOut != remoteCheckOut.trim()) {
        await _repository.updateBooking(
          UpdateBookingRequest(bookingId: bookingId, checkOut: checkOut),
        );
      }
    } catch (_) {
      if (status == 'cancelled') {
        await _syncQueue.enqueue(
          entityType: 'booking',
          operation: 'cancel',
          payloadJson: jsonEncode({'bookingId': bookingId}),
          dedupeKey: 'booking:cancel:$bookingId',
        );
      } else if (status == 'checked_out') {
        await _syncQueue.enqueue(
          entityType: 'booking',
          operation: 'checkout',
          payloadJson: jsonEncode({'bookingId': bookingId}),
          dedupeKey: 'booking:checkout:$bookingId',
        );
      }
      final checkOut = override['checkOut']?.toString().trim() ?? '';
      if (checkOut.isNotEmpty && checkOut != remoteCheckOut.trim()) {
        await _syncQueue.enqueue(
          entityType: 'booking',
          operation: 'update',
          payloadJson: jsonEncode({
            'bookingId': bookingId,
            'checkOut': checkOut,
          }),
          dedupeKey: 'booking:update:$bookingId',
        );
      }
    }
  }

  Future<void> syncExpenses() async {
    try {
      final res = await _repository.getExpenses();
      if (res.data == null) return;
      if (!res.isSuccess && res.responseCode != null) return;
      if (!Get.isRegistered<ExpenseLocalDataSource>()) return;
      final local = Get.find<ExpenseLocalDataSource>();
      final seen = <int>{};
      for (final map in _extractMaps(res.data)) {
        final merge = await local.upsertFromRemote(
          backendExpenseId: _firstText(map, const ['id', 'expenseId', 'expense_id']),
          tenantName: _firstText(map, const ['vendor', 'tenantName', 'name']),
          amountValue: _amount(map),
          datePaidIso: _firstText(map, const [
            'expenseDate',
            'date',
            'datePaid',
            'createdAt',
          ]),
          category: _firstText(map, const ['category']),
          notes: _firstText(map, const ['description', 'notes']),
          apartment: _firstText(map, const ['propertyName', 'apartment', 'location']),
          workspaceType: _firstText(map, const ['workspaceType', 'workspace_type']),
          currencyCode: _firstText(map, const ['currency', 'currencyCode']),
          remoteUpdatedAtMs: SyncFreshness.fromMap(map),
        );
        seen.add(merge.record.id);
        if (merge.keptLocal) await _pushExpense(merge.record);
      }
      final all = await local.getAllNewestFirst();
      for (final row in all) {
        if (seen.contains(row.id)) continue;
        if (row.backendExpenseId.trim().isNotEmpty) continue;
        await _pushExpense(row);
      }
    } catch (_) {}
  }

  Future<void> _pushExpense(ExpenseRecord row) async {
    final request = AddExpenseRequest(
      amount: row.amountValue,
      category: row.category.trim().isEmpty ? 'Other' : row.category.trim(),
      expenseDate: _day(row.datePaidIso),
      vendor: row.tenantName.trim().isEmpty ? row.apartment : row.tenantName,
      description: row.notes.trim().isEmpty ? null : row.notes.trim(),
    );
    final backendId = row.backendExpenseId.trim();
    try {
      if (backendId.isNotEmpty) {
        final res = await _repository.updateExpense(backendId, request);
        if (!res.isSuccess) throw Exception(res.message);
        return;
      }
      final res = await _repository.addExpense(request);
      if (!res.isSuccess) throw Exception(res.message);
      final id = _idFromResponse(res.data, const ['expenseId', 'id']);
      if (id.isNotEmpty && Get.isRegistered<ExpenseLocalDataSource>()) {
        await Get.find<ExpenseLocalDataSource>().saveBackendExpenseId(
          localId: row.id,
          backendId: id,
        );
      }
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'expense',
        operation: backendId.isEmpty ? 'create' : 'update',
        payloadJson: jsonEncode({
          ...request.toJson(),
          'localExpenseId': row.id,
          if (backendId.isNotEmpty) 'backendExpenseId': backendId,
        }),
        dedupeKey: 'expense:${backendId.isEmpty ? 'create' : 'update'}:${row.id}',
      );
    }
  }

  Future<void> syncIncomes() async {
    try {
      final res = await _repository.getPayments();
      if (res.data == null) return;
      if (!res.isSuccess && res.responseCode != null) return;
      if (!Get.isRegistered<IncomeLocalDataSource>()) return;
      final local = Get.find<IncomeLocalDataSource>();
      final seen = <int>{};
      for (final map in _extractMaps(res.data)) {
        final merge = await local.upsertFromRemote(
          backendPaymentId: _firstText(map, const ['id', 'paymentId', 'payment_id']),
          tenantName: _firstText(map, const ['tenantName', 'guestName', 'name']),
          amountValue: _amount(map),
          datePaidIso: _firstText(map, const [
            'paymentDate',
            'datePaid',
            'date',
            'createdAt',
          ]),
          category: _firstText(map, const ['paymentMethod', 'category', 'method']),
          notes: _firstText(map, const ['notes', 'description']),
          apartment: _firstText(map, const ['propertyName', 'apartment', 'location']),
          apartmentUnit: _firstText(map, const ['unitName', 'apartmentUnit']),
          propertyRef: _firstText(map, const ['propertyRef', 'property_ref', 'listingId']),
          bookingId: _firstText(map, const ['bookingId', 'booking_id']),
          workspaceType: _firstText(map, const ['workspaceType', 'workspace_type']),
          currencyCode: _firstText(map, const ['currency', 'currencyCode']),
          remoteUpdatedAtMs: SyncFreshness.fromMap(map),
          tenantId: int.tryParse(
                _firstText(map, const ['tenantId', 'tenant_id']),
              ) ??
              0,
        );
        seen.add(merge.record.id);
        if (merge.keptLocal) await _pushIncome(merge.record);
      }
      final all = await local.getAllNewestFirst();
      for (final row in all) {
        if (seen.contains(row.id)) continue;
        if (row.backendPaymentId.trim().isNotEmpty) continue;
        await _pushIncome(row);
      }
    } catch (_) {}
  }

  Future<void> _pushIncome(IncomeRecord row) async {
    final backendId = row.backendPaymentId.trim();
    final body = <String, dynamic>{
      'amount': row.amountValue,
      'paymentMethod': row.category.trim().isEmpty ? 'Cash' : row.category.trim(),
      'paymentDate': _day(row.datePaidIso),
      'status': 'PAID',
      if (row.bookingId.trim().isNotEmpty) 'bookingId': row.bookingId.trim(),
      if (row.tenantName.trim().isNotEmpty) 'tenantName': row.tenantName.trim(),
      if (row.notes.trim().isNotEmpty) 'notes': row.notes.trim(),
      if (row.propertyRef.trim().isNotEmpty) 'propertyRef': row.propertyRef.trim(),
      'updated_at_ms': row.updatedAtMs > 0 ? row.updatedAtMs : row.createdAtMs,
      'localIncomeId': row.id,
    };
    try {
      if (backendId.isNotEmpty) {
        final res = await _repository.updatePayment(backendId, body);
        if (!res.isSuccess) throw Exception(res.message);
        return;
      }
      final res = await _repository.recordPayment(
        RecordPaymentRequest(
          amount: row.amountValue,
          paymentMethod: body['paymentMethod'] as String,
          bookingId: row.bookingId.trim().isEmpty ? null : row.bookingId.trim(),
          paymentDate: body['paymentDate'] as String,
          status: 'PAID',
          idempotencyKey: 'payment:create:${row.id}',
        ),
      );
      if (!res.isSuccess) throw Exception(res.message);
      final id = _idFromResponse(res.data, const ['paymentId', 'id']);
      if (id.isNotEmpty && Get.isRegistered<IncomeLocalDataSource>()) {
        await Get.find<IncomeLocalDataSource>().saveBackendPaymentId(
          localId: row.id,
          backendId: id,
        );
      }
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'payment',
        operation: backendId.isEmpty ? 'create' : 'update',
        payloadJson: jsonEncode({
          ...body,
          if (backendId.isNotEmpty) 'backendPaymentId': backendId,
        }),
        dedupeKey: 'payment:${backendId.isEmpty ? 'create' : 'update'}:${row.id}',
      );
    }
  }

  Future<void> syncTasks() async {
    try {
      final res = await _repository.getTasks();
      if (res.data == null) return;
      if (!res.isSuccess && res.responseCode != null) return;
      final patches = await TaskAssignmentStore.readPatches();
      for (final map in _extractMaps(res.data)) {
        final task = MaintenanceTask.fromApiMap(map);
        if (task.id.isEmpty) continue;
        final patch = patches[task.id];
        final patchMap = patch is Map ? Map<String, dynamic>.from(patch) : null;
        final localMs = SyncFreshness.millis(patchMap?['updatedAtMs']);
        final remoteMs = task.remoteUpdatedAtMs;
        final phoneNewer = localMs > 0 && (remoteMs <= 0 || localMs > remoteMs);
        if (phoneNewer && patchMap != null) {
          final localTask = _taskFromPatch(task, patchMap);
          try {
            final update = await _repository.updateTask(
              task.id,
              localTask.toUpdateRequest(),
            );
            if (!update.isSuccess) throw Exception(update.message);
          } catch (_) {
            await _syncQueue.enqueue(
              entityType: 'task',
              operation: 'update',
              payloadJson: jsonEncode({
                'taskId': task.id,
                ...localTask.toUpdateRequest().toJson(),
              }),
              dedupeKey: 'task:update:${task.id}',
            );
          }
          await _mirror.saveLocal(
            entityType: SyncedEntityStore.taskType,
            entityKey: task.id,
            payload: map,
            localUpdatedAtMs: localMs,
            remoteUpdatedAtMs: remoteMs,
          );
          continue;
        }
        await _mirror.saveRemoteIfNotOlder(
          entityType: SyncedEntityStore.taskType,
          entityKey: task.id,
          payload: map,
          remoteUpdatedAtMs: remoteMs,
        );
      }
    } catch (_) {}
  }

  MaintenanceTask _taskFromPatch(MaintenanceTask remote, Map<String, dynamic> patch) {
    final statusName = patch['status']?.toString() ?? '';
    final completed = patch['isCompleted'] == true ||
        patch['isCompleted']?.toString() == 'true' ||
        statusName == 'completed';
    final assignee = patch['assignee']?.toString().trim() ?? '';
    return remote.copyWith(
      assignee: assignee.isEmpty ? remote.assignee : assignee,
      status: completed
          ? TaskStatus.completed
          : (statusName == 'inProgress'
              ? TaskStatus.inProgress
              : remote.status),
      isCompleted: completed,
    );
  }

  Future<void> syncCalendarSubscriptions() async {
    try {
      if (!Get.isRegistered<PropertyLocalDataSource>()) return;
      String userId = '';
      if (Get.isRegistered<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      )) {
        userId = ((await Get.find<PreferenceManager>(
                  tag: (PreferenceManager).toString(),
                ).getUser())
                    .id ??
                '')
            .trim();
      }
      final properties = await Get.find<PropertyLocalDataSource>().fetchAll(
        userId: userId,
      );
      final listingIds = <String>{};
      for (final property in properties) {
        final ref = property.propertyRef.trim();
        if (ref.isNotEmpty) listingIds.add(ref);
        listingIds.add('local_${property.id}');
      }
      for (final listingId in listingIds) {
        try {
          final res = await _repository.getCalendarSubscriptions(listingId);
          if (res.data == null) continue;
          if (!res.isSuccess && res.responseCode != null) continue;
          for (final map in _extractMaps(res.data, const [
            'subscriptions',
            'items',
            'content',
            'data',
          ])) {
            final id = _firstText(map, const ['id', 'subscriptionId']);
            if (id.isEmpty) continue;
            final remoteUpdated = SyncFreshness.fromMap(map);
            final existing = await _mirror.find(
              SyncedEntityStore.calendarType,
              id,
            );
            final phoneNewer = existing != null &&
                existing.localUpdatedAtMs > remoteUpdated &&
                existing.localUpdatedAtMs > 0;
            if (phoneNewer) {
              final payload = existing.payload;
              await _repository.updateCalendarSubscription(
                id,
                UpdateCalendarSubscriptionRequest(
                  sourceUrl: payload['sourceUrl']?.toString(),
                  label: payload['label']?.toString(),
                  enabled: payload['enabled'] is bool
                      ? payload['enabled'] as bool
                      : null,
                ),
              );
              await _mirror.saveLocal(
                entityType: SyncedEntityStore.calendarType,
                entityKey: id,
                payload: payload,
                localUpdatedAtMs: remoteUpdated > 0
                    ? remoteUpdated
                    : existing.localUpdatedAtMs,
                remoteUpdatedAtMs: remoteUpdated,
              );
              continue;
            }
            await _mirror.saveRemoteIfNotOlder(
              entityType: SyncedEntityStore.calendarType,
              entityKey: id,
              payload: map,
              remoteUpdatedAtMs: remoteUpdated,
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> syncSubscriptionStatus() async {
    try {
      if (!Get.isRegistered<SubscriptionService>()) return;
      await Get.find<SubscriptionService>().refresh();
    } catch (_) {}
  }

  static List<Map<String, dynamic>> _extractMaps(
    dynamic data, [
    List<String> keys = const [
      'bookings',
      'expenses',
      'payments',
      'tasks',
      'subscriptions',
      'content',
      'items',
      'data',
    ],
  ]) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      for (final key in keys) {
        final nested = data[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      if (data['id'] != null || data['bookingId'] != null) {
        return [Map<String, dynamic>.from(data)];
      }
    }
    return const [];
  }

  static String _firstText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static double _amount(Map<String, dynamic> map) {
    for (final key in const ['amount', 'amountValue', 'total']) {
      final value = map[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static String _day(String raw) {
    final text = raw.trim();
    if (text.length >= 10) return text.substring(0, 10);
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  static String _idFromResponse(dynamic data, List<String> keys) {
    if (data is Map) {
      return _firstText(Map<String, dynamic>.from(data), keys);
    }
    return '';
  }
}

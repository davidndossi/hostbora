import 'package:get/get.dart';
import 'dart:convert';

import '../data/local/db/property_local_data_source.dart';
import '../data/local/db/property_unit_local_data_source.dart';
import '/app/data/model/add_task_request.dart';
import '/app/data/model/scheduled_maintenance_request.dart';
import '/app/data/model/inventory_item_request.dart';
import '/app/data/model/schedule_payment_reminder_request.dart';
import '/app/data/model/add_expense_request.dart';
import '/app/data/model/add_listing_request.dart';
import '/app/data/model/cancel_booking_request.dart';
import '/app/data/model/checkout_booking_request.dart';
import '/app/data/model/create_booking_request.dart';
import '/app/data/model/update_booking_request.dart';
import '/app/data/model/record_payment_request.dart';
import '/app/data/model/staff_request.dart';
import '/app/data/repository/app_repository.dart';
import '/app/data/local/db/rent_payment_reminder_local_data_source.dart';
import '/app/data/local/db/offline_sync_queue_local_data_source.dart';
import '/app/data/local/service/offline_sync_ui_refresh.dart';
import '/app/data/local/db/property_members_local_data_source.dart';
import '/app/data/local/db/expense_local_data_source.dart';
import '/app/data/local/db/exchange_rate_local_data_source.dart';
import '/app/data/local/db/income_local_data_source.dart';
import '/app/data/local/service/currency_service.dart';
import '/app/data/local/db/rent_loyalty_offer_local_data_source.dart';
import '/app/data/local/db/rent_notification_log_local_data_source.dart';
import '/app/data/local/db/rent_property_estimate_local_data_source.dart';
import '/app/data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '/app/data/local/db/inventory_item_local_data_source.dart';
import '/app/data/local/db/inventory_movement_local_data_source.dart';
import '/app/data/local/db/rent_staff_local_data_source.dart';
import '/app/data/local/db/rent_tenant_charge_local_data_source.dart';
import '/app/data/local/db/client_event_local_data_source.dart';
import '/app/data/local/db/tenant_local_data_source.dart';
import '/app/data/local/db/tenant_rating_local_data_source.dart';
import '/app/data/local/db/rent_utility_topup_local_data_source.dart';
import '/app/data/local/db/rent_whatsapp_template_local_data_source.dart';
import '/app/data/local/service/local_notification_scheduler_service.dart';
import '/app/data/local/service/offline_sync_worker_service.dart';
import '/app/data/local/service/portfolio_ai_context_service.dart';
import '/app/data/local/service/portfolio_ai_hybrid_service.dart';
import '/app/data/local/service/rent_real_data_snapshot_service.dart';
import '/app/data/local/service/property_break_even_notification_service.dart';
import '/app/data/local/service/rent_notification_rules_service.dart';
import '/app/data/local/service/remote_account_sync_service.dart';
import '/app/data/local/service/bnb_messaging_contacts_service.dart';
import '/app/data/local/service/scheduled_whatsapp_dispatch_service.dart';
import '/app/data/local/service/tenant_lease_reminder_service.dart';
import '/app/data/local/service/workspace_context_service.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/preference/preference_manager_impl.dart';
import '/app/data/service/app_review_service.dart';

class LocalSourceBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PreferenceManager>(
      () => PreferenceManagerImpl(),
      tag: (PreferenceManager).toString(),
      fenix: true,
    );
    Get.put<WorkspaceContextService>(
      WorkspaceContextService(
        preferenceManager: Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
      ),
      permanent: true,
    ).init();
    Get.put<AppReviewService>(
      AppReviewService(
        preferenceManager: Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
      ),
      permanent: true,
    );
    Get.lazyPut<ExchangeRateLocalDataSource>(
      () => ExchangeRateLocalDataSource(),
      fenix: true,
    );
    Get.putAsync<CurrencyService>(
      () => CurrencyService().init(),
      permanent: true,
    );
    // Get.lazyPut<RentPropertyLocalDataSource>(
    //   () => RentPropertyLocalDataSource(),
    //   fenix: true,
    // );
    // Get.lazyPut<BnBPropertyLocalDataSource>(
    //   () => BnBPropertyLocalDataSource(),
    //   fenix: true,
    // );
    Get.lazyPut<TenantLocalDataSource>(
      () => TenantLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<ClientEventLocalDataSource>(
      () => ClientEventLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<TenantRatingLocalDataSource>(
      () => TenantRatingLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<PropertyLocalDataSource>(
      () => PropertyLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<PropertyUnitLocalDataSource>(
      () => PropertyUnitLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<PropertyMembersLocalDataSource>(
      () => PropertyMembersLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentPropertyEstimateLocalDataSource>(
      () => RentPropertyEstimateLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentStaffLocalDataSource>(
      () => RentStaffLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<IncomeLocalDataSource>(
      () => IncomeLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<ExpenseLocalDataSource>(
      () => ExpenseLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentLoyaltyOfferLocalDataSource>(
      () => RentLoyaltyOfferLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentTenantChargeLocalDataSource>(
      () => RentTenantChargeLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentScheduledMaintenanceLocalDataSource>(
      () => RentScheduledMaintenanceLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<InventoryItemLocalDataSource>(
      () => InventoryItemLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<InventoryMovementLocalDataSource>(
      () => InventoryMovementLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentPaymentReminderLocalDataSource>(
      () => RentPaymentReminderLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentNotificationLogLocalDataSource>(
      () => RentNotificationLogLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentUtilityTopUpLocalDataSource>(
      () => RentUtilityTopUpLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentWhatsappTemplateLocalDataSource>(
      () => RentWhatsappTemplateLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentRealDataSnapshotService>(
      () => RentRealDataSnapshotService(
        propertyLocal: Get.find<PropertyLocalDataSource>(),
        tenantLocal: Get.find<TenantLocalDataSource>(),
        staffLocal: Get.find<RentStaffLocalDataSource>(),
        incomeLocal: Get.find<IncomeLocalDataSource>(),
        expenseLocal: Get.find<ExpenseLocalDataSource>(),
        loyaltyLocal: Get.find<RentLoyaltyOfferLocalDataSource>(),
        maintenanceLocal: Get.find<RentScheduledMaintenanceLocalDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<PortfolioAiContextService>(
      () => PortfolioAiContextService(
        propertyLocal: Get.find<PropertyLocalDataSource>(),
        tenantLocal: Get.find<TenantLocalDataSource>(),
        incomeLocal: Get.find<IncomeLocalDataSource>(),
        expenseLocal: Get.find<ExpenseLocalDataSource>(),
        maintenanceLocal: Get.find<RentScheduledMaintenanceLocalDataSource>(),
        workspaceContext: Get.find<WorkspaceContextService>(),
        preferenceManager: Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
      ),
      fenix: true,
    );
    Get.lazyPut<PortfolioAiHybridService>(
      () => PortfolioAiHybridService(
        contextService: Get.find<PortfolioAiContextService>(),
        repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
      ),
      fenix: true,
    );
    Get.put<LocalNotificationSchedulerService>(
      LocalNotificationSchedulerService(),
      permanent: true,
    ).start();
    Get.put<TenantLeaseReminderService>(
      TenantLeaseReminderService(
        tenantLocal: Get.find<TenantLocalDataSource>(),
        preferenceManager: Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
      ),
      permanent: true,
    ).start();
    Get.lazyPut<BnbMessagingContactsService>(
      () => BnbMessagingContactsService(
        repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
        propertyLocal: Get.find<PropertyLocalDataSource>(),
        tenantLocal: Get.find<TenantLocalDataSource>(),
        syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
      ),
      fenix: true,
    );
    Get.put<ScheduledWhatsappDispatchService>(
      ScheduledWhatsappDispatchService(
        repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
      ),
      permanent: true,
    ).start();
    Get.put<PropertyBreakEvenNotificationService>(
      PropertyBreakEvenNotificationService(
        estimateLocal: Get.find<RentPropertyEstimateLocalDataSource>(),
        incomeLocal: Get.find<IncomeLocalDataSource>(),
        expenseLocal: Get.find<ExpenseLocalDataSource>(),
        tenantLocal: Get.find<TenantLocalDataSource>(),
        notificationLogLocal: Get.find<RentNotificationLogLocalDataSource>(),
        preferenceManager: Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        notificationScheduler: Get.find<LocalNotificationSchedulerService>(),
      ),
      permanent: true,
    );
    Get.put<RentNotificationRulesService>(
      RentNotificationRulesService(
        tenantLocal: Get.find<TenantLocalDataSource>(),
        staffLocal: Get.find<RentStaffLocalDataSource>(),
        maintenanceLocal: Get.find<RentScheduledMaintenanceLocalDataSource>(),
        notificationLogLocal: Get.find<RentNotificationLogLocalDataSource>(),
        preferenceManager: Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        notificationScheduler: Get.find<LocalNotificationSchedulerService>(),
      ),
      permanent: true,
    ).start();
    Get.lazyPut<OfflineSyncQueueLocalDataSource>(
      () => OfflineSyncQueueLocalDataSource(),
      fenix: true,
    );
    final syncWorker = Get.put<OfflineSyncWorkerService>(
      OfflineSyncWorkerService(
        queue: Get.find<OfflineSyncQueueLocalDataSource>(),
      ),
      permanent: true,
    );
    Get.put<RemoteAccountSyncService>(
      RemoteAccountSyncService(
        repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
        propertyLocal: Get.find<PropertyLocalDataSource>(),
        staffLocal: Get.find<RentStaffLocalDataSource>(),
        preferenceManager: Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        syncWorker: syncWorker,
      ),
      permanent: true,
    );

    syncWorker.registerHandler(
      entityType: 'rent_scheduled_maintenance',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.addScheduledMaintenance(
          ScheduledMaintenanceRequest(
            propertyLabel: map['propertyLabel'] as String?,
            propertyRef: map['propertyRef'] as String?,
            apartmentUnitId: map['apartmentUnitId'] as String?,
            category: map['category'] as String? ?? 'General',
            description: map['description'] as String?,
            scheduledDateIso: map['scheduledDateIso'] as String?,
            priority: map['priority'] as String? ?? 'medium',
            workspaceType: map['workspaceType'] as String?,
          ),
        );
        final saved = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!saved) throw Exception(res.message ?? 'sync failed');
        final localId = map['localId'] as int?;
        if (localId != null) {
          final maintenanceLocal =
              Get.find<RentScheduledMaintenanceLocalDataSource>();
          await maintenanceLocal.updateSyncStatus(localId, 'synced');
          final backendId = (res.data is Map)
              ? ((res.data as Map)['maintenanceId'] ??
                      (res.data as Map)['id'])
                  ?.toString() ??
                  ''
              : '';
          if (backendId.isNotEmpty) {
            await maintenanceLocal.saveBackendTaskId(
              localId: localId,
              backendId: backendId,
            );
          }
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'inventory_item',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.createInventoryItem(
          InventoryItemRequest(
            clientItemId: map['clientItemId'] as String?,
            propertyRef: map['propertyRef'] as String?,
            propertyLabel: map['propertyLabel'] as String?,
            apartmentUnitId: map['apartmentUnitId'] as String?,
            apartmentUnitName: map['apartmentUnitName'] as String?,
            name: map['name'] as String? ?? '',
            category: map['category'] as String? ?? 'Other',
            quantity: (map['quantity'] as num?)?.toInt() ?? 0,
            reorderLevel: (map['reorderLevel'] as num?)?.toInt() ?? 0,
            condition: map['condition'] as String? ?? 'Good',
            locationNote: map['locationNote'] as String?,
            purchaseValue: (map['purchaseValue'] as num?)?.toDouble(),
            currency: map['currency'] as String?,
          ),
        );
        final saved = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!saved) throw Exception(res.message ?? 'sync failed');
        final localId = map['localId'] as int?;
        if (localId != null) {
          final itemLocal = Get.find<InventoryItemLocalDataSource>();
          await itemLocal.updateSyncStatus(localId, 'synced');
          final backendId = (res.data is Map)
              ? ((res.data as Map)['itemId'] ?? (res.data as Map)['id'])
                  ?.toString() ??
                  ''
              : '';
          if (backendId.isNotEmpty) {
            await itemLocal.saveBackendItemId(
              localId: localId,
              backendId: backendId,
            );
          }
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'inventory_item',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final backendId = (map['backendItemId'] as String? ?? '').trim();
        if (backendId.isEmpty) {
          throw Exception('inventory item backend id missing');
        }
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.updateInventoryItem(
          backendId,
          InventoryItemRequest(
            clientItemId: map['clientItemId'] as String?,
            propertyRef: map['propertyRef'] as String?,
            propertyLabel: map['propertyLabel'] as String?,
            apartmentUnitId: map['apartmentUnitId'] as String?,
            apartmentUnitName: map['apartmentUnitName'] as String?,
            name: map['name'] as String? ?? '',
            category: map['category'] as String? ?? 'Other',
            quantity: (map['quantity'] as num?)?.toInt() ?? 0,
            reorderLevel: (map['reorderLevel'] as num?)?.toInt() ?? 0,
            condition: map['condition'] as String? ?? 'Good',
            locationNote: map['locationNote'] as String?,
            purchaseValue: (map['purchaseValue'] as num?)?.toDouble(),
            currency: map['currency'] as String?,
          ),
        );
        final saved = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!saved) throw Exception(res.message ?? 'sync failed');
        final localId = map['localId'] as int?;
        if (localId != null) {
          await Get.find<InventoryItemLocalDataSource>()
              .updateSyncStatus(localId, 'synced');
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'inventory_movement',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final itemLocal = Get.find<InventoryItemLocalDataSource>();
        var backendItemId = (map['backendItemId'] as String? ?? '').trim();
        if (backendItemId.isEmpty) {
          final itemLocalId = map['itemLocalId'] as int?;
          if (itemLocalId != null) {
            final row = await itemLocal.getById(itemLocalId);
            backendItemId = row?.backendItemId.trim() ?? '';
          }
        }
        if (backendItemId.isEmpty) {
          throw Exception('inventory item not synced yet');
        }
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.createInventoryMovement(
          backendItemId,
          InventoryMovementRequest(
            clientMovementId: map['clientMovementId'] as String?,
            movementType: map['movementType'] as String? ?? 'adjust',
            quantityDelta: (map['quantityDelta'] as num?)?.toInt() ?? 0,
            notes: map['notes'] as String?,
          ),
        );
        final saved = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!saved) throw Exception(res.message ?? 'sync failed');
        final localMovementId = map['localMovementId'] as int?;
        if (localMovementId != null) {
          final movementLocal = Get.find<InventoryMovementLocalDataSource>();
          await movementLocal.updateSyncStatus(localMovementId, 'synced');
          final backendId = (res.data is Map)
              ? ((res.data as Map)['movementId'] ?? (res.data as Map)['id'])
                  ?.toString() ??
                  ''
              : '';
          if (backendId.isNotEmpty) {
            await movementLocal.saveBackendMovementId(
              localId: localMovementId,
              backendId: backendId,
            );
          }
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'rent_payment_reminder',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        await repository.schedulePaymentReminder(
          SchedulePaymentReminderRequest.fromJson(map),
        );
        final localId = map['localId'] as int?;
        if (localId != null) {
          await Get.find<RentPaymentReminderLocalDataSource>().updateSyncStatus(
            localId,
            'synced',
          );
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'booking',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.createBooking(
          CreateBookingRequest.fromJson(map),
        );
        final ok =
            res.responseCode == null ||
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) {
          throw Exception(res.message ?? 'Booking sync failed');
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'booking',
      operation: 'checkout',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.checkoutBooking(
          CheckoutBookingRequest.fromJson(map),
        );
        final ok =
            res.responseCode == null ||
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) {
          throw Exception(res.message ?? 'Booking checkout sync failed');
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'booking',
      operation: 'cancel',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.cancelBooking(
          CancelBookingRequest.fromJson(map),
        );
        final ok =
            res.responseCode == null ||
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) {
          throw Exception(res.message ?? 'Booking cancel sync failed');
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'booking',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.updateBooking(
          UpdateBookingRequest.fromJson(map),
        );
        final ok =
            res.responseCode == null ||
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) {
          throw Exception(res.message ?? 'Booking update sync failed');
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'payment',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.recordPayment(
          RecordPaymentRequest.fromJson(map),
        );
        final ok =
            res.responseCode == null ||
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) {
          throw Exception(res.message ?? 'Payment sync failed');
        }
        // Store remote ID so deletes can reach the right record.
        final backendId = (res.data is Map)
            ? (res.data as Map)['paymentId']?.toString() ?? ''
            : '';
        final localId = (map['localIncomeId'] as num?)?.toInt();
        if (backendId.isNotEmpty && localId != null && localId > 0) {
          await Get.find<IncomeLocalDataSource>().saveBackendPaymentId(
            localId: localId,
            backendId: backendId,
          );
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'expense',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.addExpense(
          AddExpenseRequest.fromJson(map),
        );
        final ok =
            res.responseCode == null ||
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Expense sync failed');

        // Persist the backend UUID so edits can reach the right record later
        final backendId = (res.data is Map)
            ? (res.data as Map)['expenseId']?.toString() ?? ''
            : '';
        final localId = (map['localExpenseId'] as num?)?.toInt();
        if (backendId.isNotEmpty && localId != null && localId > 0) {
          final expenseLocal = Get.find<ExpenseLocalDataSource>();
          await expenseLocal.saveBackendExpenseId(
            localId: localId,
            backendId: backendId,
          );
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'expense',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final backendId = map['backendExpenseId'] as String? ?? '';
        if (backendId.isEmpty) throw Exception('Missing backendExpenseId in expense:update payload');
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.updateExpense(
          backendId,
          AddExpenseRequest.fromJson(map),
        );
        final ok =
            res.responseCode == null ||
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Expense update sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'listing',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final listingMap =
            (map['listing'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final roomPhotoPathsRaw =
            (map['roomPhotoPaths'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final roomPhotoPaths = <String, List<String>>{};
        for (final e in roomPhotoPathsRaw.entries) {
          if (e.value is List) {
            roomPhotoPaths[e.key] = (e.value as List)
                .map((v) => v.toString())
                .toList();
          }
        }
        final coverPath = (map['coverPhotoPath'] ?? '').toString().trim();
        final res = await repository.publishListing(
          AddListingRequest.fromJson(listingMap),
          roomPhotoPaths,
          coverPhotoPath: coverPath.isEmpty ? null : coverPath,
        );
        final ok =
            res.responseCode == null ||
            res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) {
          throw Exception(res.message ?? 'Listing sync failed');
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'task',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final req = AddTaskRequest(
          title: map['title'] as String? ?? '',
          description: map['description'] as String?,
          dueDate: map['dueDate'] as String?,
          propertyLabel: map['propertyLabel'] as String?,
          propertyRef: map['propertyRef'] as String?,
          workspaceType: map['workspaceType'] as String?,
          assignee: map['assignee'] as String?,
        );
        final res = await repository.addTask(req);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Task sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'task',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final taskId = (map['taskId'] as String?) ?? '';
        if (taskId.isEmpty) return;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final req = AddTaskRequest(
          title: map['title'] as String? ?? '',
          description: map['description'] as String?,
          dueDate: map['dueDate'] as String?,
          propertyLabel: map['propertyLabel'] as String?,
          propertyRef: map['propertyRef'] as String?,
          workspaceType: map['workspaceType'] as String?,
          assignee: map['assignee'] as String?,
        );
        final res = await repository.updateTask(taskId, req);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Task update sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'listing',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final listingId = map['listingId'] as String? ?? '';
        if (listingId.isEmpty) throw Exception('No listingId in payload');
        final listingData =
            (map['listing'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final roomPhotoPathsRaw =
            (map['roomPhotoPaths'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final roomPhotoPaths = <String, List<String>>{};
        for (final e in roomPhotoPathsRaw.entries) {
          if (e.value is List) {
            roomPhotoPaths[e.key] =
                (e.value as List).map((v) => v.toString()).toList();
          }
        }
        final coverPath = (map['coverPhotoPath'] ?? '').toString().trim();
        final res = await repository.updateListing(
          listingId,
          AddListingRequest.fromJson(listingData),
          roomPhotoPaths,
          coverPhotoPath: coverPath.isEmpty ? null : coverPath,
        );
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Listing update sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'unit',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final listingId = map['listingId'] as String? ?? '';
        final unitId = map['unitId'] as String? ?? '';
        if (listingId.isEmpty || unitId.isEmpty) {
          throw Exception('Missing listingId or unitId in unit:update payload');
        }
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final unitData =
            (map['unit'] as Map?)?.cast<String, dynamic>() ?? map;
        final res = await repository.updateUnit(listingId, unitId, unitData);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Unit update sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'wa_template',
      operation: 'submit',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.saveWhatsAppTemplateDraft(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'WA template submit sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'tenant',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.createTenant(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
        // Store remote ID so deletes can reach the right record.
        final backendId = (res.data is Map)
            ? (res.data as Map)['id']?.toString() ?? ''
            : '';
        final localId = (map['localTenantId'] as num?)?.toInt();
        if (backendId.isNotEmpty && localId != null && localId > 0) {
          await Get.find<TenantLocalDataSource>().saveBackendTenantId(
            localId: localId,
            backendId: backendId,
          );
        }
      },
    );
    syncWorker.registerHandler(
      entityType: 'tenant',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final id = (map['id'] as String?) ?? '';
        if (id.isEmpty) throw Exception('Missing id in tenant:update payload');
        final res = await repository.updateTenant(id, map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'document',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.uploadVaultDocument(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'staff',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final req = StaffRequest.fromSyncMap(map);
        final res = await repository.createStaff(req.toApiJson());
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'staff',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final req = StaffRequest.fromSyncMap(map);
        final id = req.id ?? (map['id'] as String?) ?? '';
        if (id.isEmpty) throw Exception('Missing id in staff:update payload');
        final res = await repository.updateStaff(id, req.toApiJson());
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'loyalty',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.createLoyaltyOffer(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'tenant_charge',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.createTenantCharge(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'lease',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.renewLease(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'estimate',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.saveEstimate(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'estimate',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final id = (map['id'] as String?) ?? '';
        if (id.isEmpty) throw Exception('Missing id in estimate:update payload');
        final res = await repository.updateEstimate(id, map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'utility',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.addUtilityTopUp(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'wa_template',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.saveWhatsAppTemplateDraft(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    syncWorker.registerHandler(
      entityType: 'wa_template',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final id = (map['id'] as String?) ?? '';
        if (id.isEmpty) throw Exception('Missing id in wa_template:update payload');
        final res = await repository.updateWhatsAppTemplateDraft(id, map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'Sync failed');
      },
    );
    // ── property:create ───────────────────────────────────────────────────
    syncWorker.registerHandler(
      entityType: 'property',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.createProperty(map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'property:create sync failed');
      },
    );

    // ── property:update ───────────────────────────────────────────────────
    syncWorker.registerHandler(
      entityType: 'property',
      operation: 'update',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final propertyRef = (map['property_ref'] as String?) ?? '';
        if (propertyRef.isEmpty) {
          throw Exception('Missing property_ref in property:update payload');
        }
        final res = await repository.updatePropertyByRef(propertyRef, map);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'property:update sync failed');
      },
    );

    // ── expense:delete ────────────────────────────────────────────────────
    syncWorker.registerHandler(
      entityType: 'expense',
      operation: 'delete',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final backendId = (map['backendExpenseId'] as String?) ?? '';
        if (backendId.isEmpty) return;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.deleteExpense(backendId);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'expense:delete sync failed');
      },
    );

    // ── payment:delete ────────────────────────────────────────────────────
    syncWorker.registerHandler(
      entityType: 'payment',
      operation: 'delete',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final paymentId = (map['paymentId'] as String?) ?? '';
        if (paymentId.isEmpty) return;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.deletePayment(paymentId);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'payment:delete sync failed');
      },
    );

    // ── tenant:delete ─────────────────────────────────────────────────────
    syncWorker.registerHandler(
      entityType: 'tenant',
      operation: 'delete',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final id = (map['id'] as String?) ?? '';
        if (id.isEmpty) return;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.deleteTenant(id);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'tenant:delete sync failed');
      },
    );

    // ── task:delete ───────────────────────────────────────────────────────
    syncWorker.registerHandler(
      entityType: 'task',
      operation: 'delete',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final taskId = (map['taskId'] as String?) ?? '';
        if (taskId.isEmpty) return;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final res = await repository.deleteTask(taskId);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'task:delete sync failed');
      },
    );

    registerOfflineSyncUiRefresh(syncWorker);
    syncWorker.start();
  }
}

import 'package:get/get.dart';
import 'dart:convert';

import '../data/local/db/property_local_data_source.dart';
import '../data/local/db/property_unit_local_data_source.dart';
import '/app/data/model/add_task_request.dart';
import '/app/data/model/add_expense_request.dart';
import '/app/data/model/add_listing_request.dart';
import '/app/data/model/cancel_booking_request.dart';
import '/app/data/model/checkout_booking_request.dart';
import '/app/data/model/create_booking_request.dart';
import '/app/data/model/update_booking_request.dart';
import '/app/data/model/record_payment_request.dart';
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
import '/app/data/local/db/rent_staff_local_data_source.dart';
import '/app/data/local/db/rent_tenant_charge_local_data_source.dart';
import '/app/data/local/db/tenant_local_data_source.dart';
import '/app/data/local/db/rent_utility_topup_local_data_source.dart';
import '/app/data/local/db/rent_whatsapp_template_local_data_source.dart';
import '/app/data/local/service/local_notification_scheduler_service.dart';
import '/app/data/local/service/offline_sync_worker_service.dart';
import '/app/data/local/service/portfolio_ai_context_service.dart';
import '/app/data/local/service/portfolio_ai_hybrid_service.dart';
import '/app/data/local/service/rent_real_data_snapshot_service.dart';
import '/app/data/local/service/property_break_even_notification_service.dart';
import '/app/data/local/service/rent_notification_rules_service.dart';
import '/app/data/local/service/bnb_messaging_contacts_service.dart';
import '/app/data/local/service/scheduled_whatsapp_dispatch_service.dart';
import '/app/data/local/service/tenant_lease_reminder_service.dart';
import '/app/data/local/service/workspace_context_service.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/preference/preference_manager_impl.dart';

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

    syncWorker.registerHandler(
      entityType: 'rent_scheduled_maintenance',
      operation: 'create',
      handler: (item) async {
        final map = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        await repository.addTask(
          AddTaskRequest(
            title: map['title'] as String? ?? 'Maintenance',
            description: map['description'] as String?,
            dueDate: map['dueDate'] as String?,
            propertyLabel: map['propertyLabel'] as String?,
            propertyRef: map['propertyRef'] as String?,
            workspaceType: map['workspaceType'] as String?,
          ),
        );
        final localId = map['localId'] as int?;
        if (localId != null) {
          await Get.find<RentScheduledMaintenanceLocalDataSource>()
              .updateSyncStatus(localId, 'synced');
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
        await repository.addTask(
          AddTaskRequest(
            title: map['title'] as String? ?? 'Payment reminder',
            description: map['description'] as String?,
            dueDate: map['dueDate'] as String?,
            propertyLabel: map['propertyLabel'] as String?,
            propertyRef: map['propertyRef'] as String?,
            workspaceType: map['workspaceType'] as String?,
          ),
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
        if (!ok) {
          throw Exception(res.message ?? 'Expense sync failed');
        }
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
        final res = await repository.createStaff(map);
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
        final id = (map['id'] as String?) ?? '';
        if (id.isEmpty) throw Exception('Missing id in staff:update payload');
        final res = await repository.updateStaff(id, map);
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
    registerOfflineSyncUiRefresh(syncWorker);
    syncWorker.start();
  }
}

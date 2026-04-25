import 'package:get/get.dart';
import 'dart:convert';

import '/app/data/model/add_task_request.dart';
import '/app/data/repository/app_repository.dart';
import '/app/data/local/db/rent_payment_reminder_local_data_source.dart';
import '/app/data/local/db/offline_sync_queue_local_data_source.dart';
import '/app/data/local/db/property_members_local_data_source.dart';
import '/app/data/local/db/rent_expense_local_data_source.dart';
import '/app/data/local/db/rent_income_local_data_source.dart';
import '/app/data/local/db/rent_loyalty_offer_local_data_source.dart';
import '/app/data/local/db/rent_notification_log_local_data_source.dart';
import '/app/data/local/db/rent_property_local_data_source.dart';
import '/app/data/local/db/rent_property_estimate_local_data_source.dart';
import '/app/data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '/app/data/local/db/rent_staff_local_data_source.dart';
import '/app/data/local/db/rent_tenant_charge_local_data_source.dart';
import '/app/data/local/db/rent_tenant_local_data_source.dart';
import '/app/data/local/db/rent_utility_topup_local_data_source.dart';
import '/app/data/local/db/rent_whatsapp_template_local_data_source.dart';
import '/app/data/local/service/local_notification_scheduler_service.dart';
import '/app/data/local/service/offline_sync_worker_service.dart';
import '/app/data/local/service/rent_real_data_snapshot_service.dart';
import '/app/data/local/service/rent_notification_rules_service.dart';
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
    Get.lazyPut<RentPropertyLocalDataSource>(
      () => RentPropertyLocalDataSource(),
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
    Get.lazyPut<RentIncomeLocalDataSource>(
      () => RentIncomeLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentExpenseLocalDataSource>(
      () => RentExpenseLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentTenantLocalDataSource>(
      () => RentTenantLocalDataSource(),
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
        propertyLocal: Get.find<RentPropertyLocalDataSource>(),
        tenantLocal: Get.find<RentTenantLocalDataSource>(),
        staffLocal: Get.find<RentStaffLocalDataSource>(),
        incomeLocal: Get.find<RentIncomeLocalDataSource>(),
        expenseLocal: Get.find<RentExpenseLocalDataSource>(),
        loyaltyLocal: Get.find<RentLoyaltyOfferLocalDataSource>(),
        maintenanceLocal: Get.find<RentScheduledMaintenanceLocalDataSource>(),
      ),
      fenix: true,
    );
    Get.put<LocalNotificationSchedulerService>(
      LocalNotificationSchedulerService(),
      permanent: true,
    ).start();
    Get.put<TenantLeaseReminderService>(
      TenantLeaseReminderService(
        tenantLocal: Get.find<RentTenantLocalDataSource>(),
        preferenceManager: Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
      ),
      permanent: true,
    ).start();
    Get.put<RentNotificationRulesService>(
      RentNotificationRulesService(
        tenantLocal: Get.find<RentTenantLocalDataSource>(),
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
        final repository = Get.find<AppRepository>(tag: (AppRepository).toString());
        await repository.addTask(
          AddTaskRequest(
            title: map['title'] as String? ?? 'Maintenance',
            description: map['description'] as String?,
            dueDate: map['dueDate'] as String?,
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
        final repository = Get.find<AppRepository>(tag: (AppRepository).toString());
        await repository.addTask(
          AddTaskRequest(
            title: map['title'] as String? ?? 'Payment reminder',
            description: map['description'] as String?,
            dueDate: map['dueDate'] as String?,
          ),
        );
        final localId = map['localId'] as int?;
        if (localId != null) {
          await Get.find<RentPaymentReminderLocalDataSource>()
              .updateSyncStatus(localId, 'synced');
        }
      },
    );
    syncWorker.start();
  }
}

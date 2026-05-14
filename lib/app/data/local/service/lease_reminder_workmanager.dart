import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';

import '/app/data/local/db/tenant_local_data_source.dart';
import '/app/data/local/db/rent_staff_local_data_source.dart';
import '/app/data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '/app/data/local/db/rent_notification_log_local_data_source.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/preference/preference_manager_impl.dart';
import '/app/data/local/service/local_notification_scheduler_service.dart';
import '/app/data/local/service/rent_notification_rules_service.dart';
import '/app/data/local/service/tenant_lease_reminder_service.dart';
import '/app/data/remote/remote_data_source.dart';
import '/app/data/remote/remote_data_source_impl.dart';
import '/app/data/repository/app_repository.dart';
import '/app/data/repository/app_repository_impl.dart';
import '/flavors/build_config.dart';
import '/flavors/env_config.dart';
import '/flavors/environment.dart';

const tenantLeaseReminderTask = 'tenant_lease_reminder_daily_task';
const tenantLeaseReminderUnique = 'tenant_lease_reminder_daily_unique';

@pragma('vm:entry-point')
void leaseReminderCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != tenantLeaseReminderTask) return true;

    WidgetsFlutterBinding.ensureInitialized();

    final appName = inputData?['appName'] as String? ?? 'Host Bora';
    final baseUrl = inputData?['baseUrl'] as String? ?? '';
    if (baseUrl.isEmpty) return false;

    BuildConfig.instantiate(
      envType: Environment.DEVELOPMENT,
      envConfig: EnvConfig(
        appName: appName,
        baseUrl: baseUrl,
        shouldCollectCrashLog: false,
      ),
    );

    if (!Get.isRegistered<PreferenceManager>(tag: (PreferenceManager).toString())) {
      Get.put<PreferenceManager>(
        PreferenceManagerImpl(),
        tag: (PreferenceManager).toString(),
      );
    }
    if (!Get.isRegistered<RemoteDataSource>(tag: (RemoteDataSource).toString())) {
      Get.put<RemoteDataSource>(
        RemoteDataSourceImpl(),
        tag: (RemoteDataSource).toString(),
      );
    }
    if (!Get.isRegistered<AppRepository>(tag: (AppRepository).toString())) {
      Get.put<AppRepository>(
        AppRepositoryImpl(),
        tag: (AppRepository).toString(),
      );
    }

    final service = TenantLeaseReminderService(
      tenantLocal: TenantLocalDataSource(),
      preferenceManager: Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
      repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
    );

    try {
      await service.runNow();
      final notificationScheduler = LocalNotificationSchedulerService();
      final rulesService = RentNotificationRulesService(
        tenantLocal: TenantLocalDataSource(),
        staffLocal: RentStaffLocalDataSource(),
        maintenanceLocal: RentScheduledMaintenanceLocalDataSource(),
        notificationLogLocal: RentNotificationLogLocalDataSource(),
        preferenceManager: Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
        notificationScheduler: notificationScheduler,
      );
      await rulesService.runNow();
      return true;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Work manager lease reminder failed: $e');
      }
      return false;
    }
  });
}

Future<void> initializeLeaseReminderWorkmanager({
  required String appName,
  required String baseUrl,
}) async {
  await Workmanager().initialize(
    leaseReminderCallbackDispatcher,
  );

  await Workmanager().registerPeriodicTask(
    tenantLeaseReminderUnique,
    tenantLeaseReminderTask,
    frequency: const Duration(hours: 24),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    inputData: {
      'appName': appName,
      'baseUrl': baseUrl,
    },
  );
}

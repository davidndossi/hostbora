import 'package:get/get.dart';

import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/portfolio_ai_context_service.dart';
import '../../../data/local/service/portfolio_ai_hybrid_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/repository/app_repository.dart';
import '../controllers/ai_manager_controller.dart';

class AiManagerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PortfolioAiContextService>()) {
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
    }
    if (!Get.isRegistered<PortfolioAiHybridService>()) {
      Get.lazyPut<PortfolioAiHybridService>(
        () => PortfolioAiHybridService(
          contextService: Get.find<PortfolioAiContextService>(),
          repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
        ),
        fenix: true,
      );
    }
    Get.lazyPut<AiManagerController>(
      AiManagerController.new,
      fenix: true,
    );
  }
}

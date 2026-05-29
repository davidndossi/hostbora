import 'package:get/get.dart';

import '../base/base_controller.dart';
import '../utils/property_financial_time_series.dart';
import '../utils/property_listing_finance_scope.dart';
import '../../data/local/db/expense_local_data_source.dart';
import '../../data/local/db/income_local_data_source.dart';
import '../../data/local/db/property_local_data_source.dart';

/// Loads per-listing income/cost time series for trend charts.
mixin ListingFinancialTrendsMixin on BaseController {
  final financialTrends = Rxn<PropertyFinancialTimeSeries>();
  final financialTrendsLoading = false.obs;

  Future<void> loadListingFinancialTrends({
    required String workspaceType,
    required String propertyId,
    required String propertyName,
    required String propertyLocation,
  }) async {
    financialTrendsLoading.value = true;
    try {
      final scope = await PropertyListingFinanceScope.resolve(
        propertyId: propertyId,
        propertyName: propertyName,
        propertyLocation: propertyLocation,
        propertyLocal: Get.find<PropertyLocalDataSource>(),
      );
      final ws = workspaceType.trim().toLowerCase();
      final incomes =
          await Get.find<IncomeLocalDataSource>().getAllNewestFirst(workspaceType: ws);
      final expenses =
          await Get.find<ExpenseLocalDataSource>().getAllNewestFirst(workspaceType: ws);
      financialTrends.value = PropertyFinancialTimeSeriesBuilder.build(
        scope: scope,
        incomes: incomes,
        expenses: expenses,
      );
    } catch (_) {
      financialTrends.value = const PropertyFinancialTimeSeries(
        dateLabels: [],
        incomeByPeriod: [],
        costsByPeriod: [],
      );
    } finally {
      financialTrendsLoading.value = false;
    }
  }
}

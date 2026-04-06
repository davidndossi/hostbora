import 'package:get/get.dart';

import '/app/data/local/db/rent_expense_local_data_source.dart';
import '/app/data/local/db/rent_income_local_data_source.dart';
import '/app/data/local/db/rent_loyalty_offer_local_data_source.dart';
import '/app/data/local/db/rent_property_local_data_source.dart';
import '/app/data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '/app/data/local/db/rent_staff_local_data_source.dart';
import '/app/data/local/db/rent_tenant_local_data_source.dart';

class RentRealDataSnapshot {
  const RentRealDataSnapshot({
    required this.properties,
    required this.tenants,
    required this.staff,
    required this.loyaltyOffers,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.maintenanceTasks,
    required this.expiringLeasesIn30Days,
  });

  final int properties;
  final int tenants;
  final int staff;
  final int loyaltyOffers;
  final double incomeTotal;
  final double expenseTotal;
  final int maintenanceTasks;
  final int expiringLeasesIn30Days;

  double get netProfit => incomeTotal - expenseTotal;
}

class RentRealDataSnapshotService extends GetxService {
  RentRealDataSnapshotService({
    required RentPropertyLocalDataSource propertyLocal,
    required RentTenantLocalDataSource tenantLocal,
    required RentStaffLocalDataSource staffLocal,
    required RentIncomeLocalDataSource incomeLocal,
    required RentExpenseLocalDataSource expenseLocal,
    required RentLoyaltyOfferLocalDataSource loyaltyLocal,
    required RentScheduledMaintenanceLocalDataSource maintenanceLocal,
  })  : _propertyLocal = propertyLocal,
        _tenantLocal = tenantLocal,
        _staffLocal = staffLocal,
        _incomeLocal = incomeLocal,
        _expenseLocal = expenseLocal,
        _loyaltyLocal = loyaltyLocal,
        _maintenanceLocal = maintenanceLocal;

  final RentPropertyLocalDataSource _propertyLocal;
  final RentTenantLocalDataSource _tenantLocal;
  final RentStaffLocalDataSource _staffLocal;
  final RentIncomeLocalDataSource _incomeLocal;
  final RentExpenseLocalDataSource _expenseLocal;
  final RentLoyaltyOfferLocalDataSource _loyaltyLocal;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;

  Future<RentRealDataSnapshot> load() async {
    final properties = await _propertyLocal.getAllNewestFirst();
    final tenants = await _tenantLocal.getAllNewestFirst();
    final staff = await _staffLocal.getAllNewestFirst();
    final income = await _incomeLocal.getAllNewestFirst();
    final expense = await _expenseLocal.getAllNewestFirst();
    final loyalty = await _loyaltyLocal.getAllNewestFirst();
    final maintenance = await _maintenanceLocal.getAllNewestFirst();

    final incomeTotal = income.fold<double>(0, (sum, e) => sum + e.amountValue);
    final expenseTotal = expense.fold<double>(0, (sum, e) => sum + e.amountValue);

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final threshold = day.add(const Duration(days: 30));
    final expiring = tenants.where((t) {
      try {
        final end = DateTime.parse(t.leaseEndIso);
        final endDay = DateTime(end.year, end.month, end.day);
        return (endDay.isAtSameMomentAs(day) || endDay.isAfter(day)) &&
            (endDay.isAtSameMomentAs(threshold) || endDay.isBefore(threshold));
      } catch (_) {
        return false;
      }
    }).length;

    return RentRealDataSnapshot(
      properties: properties.length,
      tenants: tenants.length,
      staff: staff.length,
      loyaltyOffers: loyalty.length,
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
      maintenanceTasks: maintenance.length,
      expiringLeasesIn30Days: expiring,
    );
  }
}

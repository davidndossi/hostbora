/// Snapshot of portfolio metrics for hybrid AI (local answers + LLM context).
class PortfolioAiPropertySlice {
  const PortfolioAiPropertySlice({
    required this.name,
    required this.propertyRef,
    required this.units,
    required this.occupied,
    required this.occupancyPercent,
    required this.monthIncome,
    required this.monthExpenses,
    required this.monthExpected,
  });

  final String name;
  final String propertyRef;
  final int units;
  final int occupied;
  final double occupancyPercent;
  final double monthIncome;
  final double monthExpenses;
  final double monthExpected;

  Map<String, dynamic> toJson() => {
        'name': name,
        'propertyRef': propertyRef,
        'units': units,
        'occupied': occupied,
        'occupancyPercent': occupancyPercent,
        'monthIncome': monthIncome,
        'monthExpenses': monthExpenses,
        'monthExpected': monthExpected,
      };
}

class PortfolioAiExpenseBucket {
  const PortfolioAiExpenseBucket({
    required this.category,
    required this.amount,
  });

  final String category;
  final double amount;

  Map<String, dynamic> toJson() => {
        'category': category,
        'amount': amount,
      };
}

class PortfolioAiArrearsRow {
  const PortfolioAiArrearsRow({
    required this.name,
    required this.place,
    required this.amount,
  });

  final String name;
  final String place;
  final double amount;

  Map<String, dynamic> toJson() => {
        'name': name,
        'place': place,
        'amount': amount,
      };
}

class PortfolioAiContext {
  const PortfolioAiContext({
    required this.workspace,
    required this.monthLabel,
    required this.propertyCount,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.occupancyPercent,
    required this.activeTenants,
    required this.monthIncome,
    required this.monthExpenses,
    required this.monthNet,
    required this.arrearsTenantCount,
    required this.arrearsTotal,
    required this.leasesExpiring30Days,
    required this.activeBookingsToday,
    required this.checkInsToday,
    required this.checkOutsToday,
    required this.maintenanceTasks,
    required this.propertyNames,
    this.monthExpected = 0,
    this.collectionRatePercent = 0,
    this.prevMonthIncome = 0,
    this.prevMonthExpenses = 0,
    this.prevMonthLabel = '',
    this.expenseCategories = const [],
    this.properties = const [],
    this.arrearsRows = const [],
    this.includedRemote = false,
  });

  final String workspace;
  final String monthLabel;
  final int propertyCount;
  final int totalUnits;
  final int occupiedUnits;
  final double occupancyPercent;
  final int activeTenants;
  final double monthIncome;
  final double monthExpenses;
  final double monthNet;
  final int arrearsTenantCount;
  final double arrearsTotal;
  final int leasesExpiring30Days;
  final int activeBookingsToday;
  final int checkInsToday;
  final int checkOutsToday;
  final int maintenanceTasks;
  final List<String> propertyNames;

  /// Rent / stay expected for [monthLabel] from active leases.
  final double monthExpected;

  /// `monthIncome / monthExpected * 100`, or 0 when nothing is expected.
  final double collectionRatePercent;

  final double prevMonthIncome;
  final double prevMonthExpenses;
  final String prevMonthLabel;
  final List<PortfolioAiExpenseBucket> expenseCategories;
  final List<PortfolioAiPropertySlice> properties;
  final List<PortfolioAiArrearsRow> arrearsRows;

  /// True when live backend rows were merged on top of the local DB.
  final bool includedRemote;

  bool get isRent => workspace == 'rent';
  bool get isBnb => workspace == 'bnb';

  factory PortfolioAiContext.empty({String workspace = 'rent'}) {
    return PortfolioAiContext(
      workspace: workspace,
      monthLabel: '',
      propertyCount: 0,
      totalUnits: 0,
      occupiedUnits: 0,
      occupancyPercent: 0,
      activeTenants: 0,
      monthIncome: 0,
      monthExpenses: 0,
      monthNet: 0,
      arrearsTenantCount: 0,
      arrearsTotal: 0,
      leasesExpiring30Days: 0,
      activeBookingsToday: 0,
      checkInsToday: 0,
      checkOutsToday: 0,
      maintenanceTasks: 0,
      propertyNames: const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'workspace': workspace,
        'month': monthLabel,
        'previousMonth': prevMonthLabel,
        'propertyCount': propertyCount,
        'totalUnits': totalUnits,
        'occupiedUnits': occupiedUnits,
        'occupancyPercent': occupancyPercent,
        'activeTenants': activeTenants,
        'monthIncome': monthIncome,
        'monthExpenses': monthExpenses,
        'monthNet': monthNet,
        'monthExpected': monthExpected,
        'collectionRatePercent': collectionRatePercent,
        'prevMonthIncome': prevMonthIncome,
        'prevMonthExpenses': prevMonthExpenses,
        'arrearsTenantCount': arrearsTenantCount,
        'arrearsTotal': arrearsTotal,
        'leasesExpiring30Days': leasesExpiring30Days,
        'activeBookingsToday': activeBookingsToday,
        'checkInsToday': checkInsToday,
        'checkOutsToday': checkOutsToday,
        'maintenanceTasks': maintenanceTasks,
        'propertyNames': propertyNames,
        'expenseCategories': expenseCategories.map((e) => e.toJson()).toList(),
        'properties': properties.map((e) => e.toJson()).toList(),
        'arrears': arrearsRows.map((e) => e.toJson()).toList(),
        'includedRemote': includedRemote,
      };

  String welcomeSummary({
    required String Function(num amount) formatMoney,
    required bool isSw,
  }) {
    final wsLabel = isRent
        ? (isSw ? 'Kodi' : 'Rent')
        : (isSw ? 'BnB' : 'BnB');
    final occ = occupancyPercent.toStringAsFixed(1);
    final rate = collectionRatePercent.toStringAsFixed(0);
    if (isSw) {
      return 'Nipo tayari kujibu maswali kuhusu $wsLabel yako ($monthLabel). '
          'Una mali $propertyCount, ukodishaji $occ%, mapato ${formatMoney(monthIncome.round())}'
          '${monthExpected > 0 ? ', ukusanyaji $rate%' : ''}. '
          'Uliza ukodishaji kwa mali, matumizi, deni, au ukusanyaji wa kodi.';
    }
    return 'I can answer questions about your $wsLabel portfolio ($monthLabel). '
        'You have $propertyCount propert${propertyCount == 1 ? 'y' : 'ies'}, '
        '$occ% occupancy, and ${formatMoney(monthIncome.round())} income this month'
        '${monthExpected > 0 ? ' ($rate% collected vs expected)' : ''}. '
        'Ask about occupancy by property, expenses, arrears, or rent collection.';
  }
}

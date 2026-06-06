/// Snapshot of portfolio metrics for hybrid AI (local answers + LLM context).
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
        'propertyCount': propertyCount,
        'totalUnits': totalUnits,
        'occupiedUnits': occupiedUnits,
        'occupancyPercent': occupancyPercent,
        'activeTenants': activeTenants,
        'monthIncome': monthIncome,
        'monthExpenses': monthExpenses,
        'monthNet': monthNet,
        'arrearsTenantCount': arrearsTenantCount,
        'arrearsTotal': arrearsTotal,
        'leasesExpiring30Days': leasesExpiring30Days,
        'activeBookingsToday': activeBookingsToday,
        'checkInsToday': checkInsToday,
        'checkOutsToday': checkOutsToday,
        'maintenanceTasks': maintenanceTasks,
        'propertyNames': propertyNames,
      };

  String welcomeSummary({
    required String Function(num amount) formatMoney,
    required bool isSw,
  }) {
    final wsLabel = isRent
        ? (isSw ? 'Kodi' : 'Rent')
        : (isSw ? 'BnB' : 'BnB');
    final occ = occupancyPercent.toStringAsFixed(1);
    if (isSw) {
      return 'Nipo tayari kujibu maswali kuhusu $wsLabel yako (${monthLabel}). '
          'Una mali $propertyCount, ukodishaji ${occ}%, mapato ya mwezi ${formatMoney(monthIncome.round())}. '
          'Uliza chochote — mfano ukodishaji, deni, au mikataba inayoisha.';
    }
    return 'I can answer questions about your $wsLabel portfolio (${monthLabel}). '
        'You have $propertyCount propert${propertyCount == 1 ? 'y' : 'ies'}, '
        '${occ}% occupancy, and ${formatMoney(monthIncome.round())} income this month. '
        'Ask about occupancy, arrears, leases expiring, or anything else in your data.';
  }
}

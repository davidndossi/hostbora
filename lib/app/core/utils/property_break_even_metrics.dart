/// Break-even helpers for property principal vs rental income.
class PropertyBreakEvenMetrics {
  const PropertyBreakEvenMetrics._();

  /// Months until cumulative [monthlyNetIncome] covers [principalCost].
  static int? monthsToBreakEven({
    required double principalCost,
    required double monthlyNetIncome,
  }) {
    if (principalCost <= 0 || monthlyNetIncome <= 0) return null;
    return (principalCost / monthlyNetIncome).ceil();
  }

  static bool isBreakEvenReached({
    required double totalCapital,
    required double incomeGeneratedToDate,
  }) =>
      totalCapital > 0 && incomeGeneratedToDate >= totalCapital;

  /// Projected calendar day when cumulative net income covers [totalCapital].
  static DateTime? projectedBreakEvenDate({
    required double totalCapital,
    required double monthlyNetIncome,
    DateTime? from,
  }) {
    final months = monthsToBreakEven(
      principalCost: totalCapital,
      monthlyNetIncome: monthlyNetIncome,
    );
    if (months == null) return null;
    final base = from ?? DateTime.now();
    final day = DateTime(base.year, base.month, base.day).add(Duration(days: months * 30));
    return DateTime(day.year, day.month, day.day, 9);
  }

  /// Human-readable break-even from principal and monthly net cash flow.
  static String formatBreakEven({
    required double principalCost,
    required double monthlyNetIncome,
    required double incomeGeneratedToDate,
    bool isSw = false,
  }) {
    if (principalCost <= 0) {
      return isSw ? 'Ongeza makadirio ya gharama za mali' : 'Add property cost estimates';
    }
    if (incomeGeneratedToDate >= principalCost && principalCost > 0) {
      return isSw ? 'Umiliki — mapato yamezidi mtaji' : 'Break-even reached — income exceeds principal';
    }
    final months = monthsToBreakEven(
      principalCost: principalCost,
      monthlyNetIncome: monthlyNetIncome,
    );
    if (months == null) {
      return isSw
          ? 'Hakuna mapato ya kutosha kwa makadirio'
          : 'Insufficient income for break-even estimate';
    }
    return formatMonths(months, isSw: isSw);
  }

  static String formatMonths(int months, {bool isSw = false}) {
    if (months <= 0) {
      return isSw ? 'Umiliki tayari' : 'Break-even now';
    }
    if (months < 2) {
      final days = months * 30;
      return isSw ? 'Umiliki katika takriban siku $days' : 'Break-even in ~$days days';
    }
    if (months < 24) {
      return isSw
          ? 'Umiliki katika takriban miezi $months'
          : 'Break-even in ~$months months';
    }
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) {
      return isSw
          ? 'Umiliki katika takriban miaka $years'
          : 'Break-even in ~$years years';
    }
    return isSw
        ? 'Umiliki katika takriban miaka $years miezi $rem'
        : 'Break-even in ~$years years $rem months';
  }
}

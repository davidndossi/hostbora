import 'portfolio_ai_context.dart';

class PortfolioAiLocalAnswer {
  const PortfolioAiLocalAnswer({
    required this.matched,
    required this.text,
  });

  final bool matched;
  final String text;
}

/// Answers common portfolio questions from [PortfolioAiContext] without calling the LLM.
abstract class PortfolioAiLocalResolver {
  PortfolioAiLocalResolver._();

  static PortfolioAiLocalAnswer resolve({
    required String question,
    required PortfolioAiContext ctx,
    required String Function(num amount) formatMoney,
    required bool isSw,
  }) {
    final q = question.trim().toLowerCase();
    if (q.isEmpty) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: isSw
            ? 'Andika swali lako — mfano "Kiwango cha ukodishaji?" au "Mapato ya mwezi huu".'
            : 'Type a question — e.g. "What\'s my occupancy rate?" or "Monthly income this month".',
      );
    }

    if (_matches(q, const [
      'occupancy',
      'occupied',
      'vacant',
      'ukodishaji',
      'vyeo',
      'units occupied',
    ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _occupancyAnswer(ctx, formatMoney, isSw),
      );
    }

    if (_matches(q, const [
      'income',
      'revenue',
      'earnings',
      'mapato',
      'monthly income',
      'collection',
      'kodi iliyolipwa',
      'nimekusanya',
      'malipo ya mwezi',
    ]) &&
        !_matches(q, const ['expense', 'profit', 'net', 'gharama'])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _incomeAnswer(ctx, formatMoney, isSw),
      );
    }

    if (_matches(q, const [
      'expense',
      'expenses',
      'spending',
      'gharama',
      'matumizi',
      'costs',
    ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _expenseAnswer(ctx, formatMoney, isSw),
      );
    }

    if (_matches(q, const [
      'profit',
      'net',
      'p&l',
      'faida',
      'margin',
    ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _profitAnswer(ctx, formatMoney, isSw),
      );
    }

    if (_matches(q, const [
      'arrear',
      'overdue',
      'unpaid',
      'deni',
      'malipo',
      'behind',
      'madeni',
      'hawajalipa',
      'bado kulipa',
      'malimbikizo',
    ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _arrearsAnswer(ctx, formatMoney, isSw),
      );
    }

    if (_matches(q, const [
      'expir',
      'renew',
      'ending',
      'inayoisha',
      'mkataba',
      'lease',
    ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _leaseExpiryAnswer(ctx, isSw),
      );
    }

    if (_matches(q, const [
      'tenant',
      'wapangaji',
      'renters',
      'guest',
    ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _tenantAnswer(ctx, isSw),
      );
    }

    if (_matches(q, const [
      'propert',
      'listing',
      'portfolio',
      'mali',
      'nyumba',
    ]) &&
        !_matches(q, const ['how many tenant'])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _propertyAnswer(ctx, isSw),
      );
    }

    if (ctx.isBnb &&
        _matches(q, const [
          'booking',
          'check-in',
          'check in',
          'check-out',
          'checkout',
          'guest',
          'reservation',
        ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _bookingAnswer(ctx, isSw),
      );
    }

    if (ctx.isRent &&
        _matches(q, const [
          'maintenance',
          'repair',
          'matengenezo',
        ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _maintenanceAnswer(ctx, isSw),
      );
    }

    if (_matches(q, const [
      'summary',
      'overview',
      'snapshot',
      'dashboard',
      'muhtasari',
      'hali',
    ])) {
      return PortfolioAiLocalAnswer(
        matched: true,
        text: _summaryAnswer(ctx, formatMoney, isSw),
      );
    }

    return const PortfolioAiLocalAnswer(matched: false, text: '');
  }

  static bool _matches(String q, List<String> needles) {
    for (final n in needles) {
      if (q.contains(n)) return true;
    }
    return false;
  }

  static String _occupancyAnswer(
    PortfolioAiContext ctx,
    String Function(num) formatMoney,
    bool isSw,
  ) {
    final pct = ctx.occupancyPercent.toStringAsFixed(1);
    if (ctx.isBnb) {
      if (isSw) {
        return 'Ukodishaji wa leo: $pct% (${ctx.occupiedUnits} kati ya ${ctx.totalUnits} vitengo). '
            'Uhifadhi hai leo: ${ctx.activeBookingsToday}. '
            'Mapato ya ${ctx.monthLabel}: ${formatMoney(ctx.monthIncome.round())}.';
      }
      return 'Current occupancy: $pct% (${ctx.occupiedUnits} of ${ctx.totalUnits} units). '
          'Active stays today: ${ctx.activeBookingsToday}. '
          '${ctx.monthLabel} income: ${formatMoney(ctx.monthIncome.round())}.';
    }
    if (isSw) {
      return 'Ukodishaji wa sasa: $pct% (${ctx.occupiedUnits} kati ya ${ctx.totalUnits} vitengo). '
          'Wapangaji hai: ${ctx.activeTenants}.';
    }
    return 'Current occupancy: $pct% (${ctx.occupiedUnits} of ${ctx.totalUnits} units). '
        'Active tenants: ${ctx.activeTenants}.';
  }

  static String _incomeAnswer(
    PortfolioAiContext ctx,
    String Function(num) formatMoney,
    bool isSw,
  ) {
    if (isSw) {
      return 'Mapato ya ${ctx.monthLabel}: ${formatMoney(ctx.monthIncome.round())} '
          '(${ctx.propertyCount} mali, ${ctx.workspace == 'rent' ? 'kodi' : 'BnB'}).';
    }
    return '${ctx.monthLabel} income: ${formatMoney(ctx.monthIncome.round())} '
        'across ${ctx.propertyCount} propert${ctx.propertyCount == 1 ? 'y' : 'ies'} (${ctx.workspace}).';
  }

  static String _expenseAnswer(
    PortfolioAiContext ctx,
    String Function(num) formatMoney,
    bool isSw,
  ) {
    if (isSw) {
      return 'Matumizi ya ${ctx.monthLabel}: ${formatMoney(ctx.monthExpenses.round())}.';
    }
    return '${ctx.monthLabel} expenses: ${formatMoney(ctx.monthExpenses.round())}.';
  }

  static String _profitAnswer(
    PortfolioAiContext ctx,
    String Function(num) formatMoney,
    bool isSw,
  ) {
    final net = ctx.monthNet;
    final sign = net >= 0 ? '+' : '';
    if (isSw) {
      return 'Muhtasari wa ${ctx.monthLabel}:\n'
          'Mapato: ${formatMoney(ctx.monthIncome.round())}\n'
          'Matumizi: ${formatMoney(ctx.monthExpenses.round())}\n'
          'Faida halisi: $sign${formatMoney(net.round())}';
    }
    return '${ctx.monthLabel} P&L:\n'
        'Income: ${formatMoney(ctx.monthIncome.round())}\n'
        'Expenses: ${formatMoney(ctx.monthExpenses.round())}\n'
        'Net: $sign${formatMoney(net.round())}';
  }

  static String _arrearsAnswer(
    PortfolioAiContext ctx,
    String Function(num) formatMoney,
    bool isSw,
  ) {
    if (ctx.arrearsTenantCount == 0) {
      return isSw
          ? 'Hakuna wapangaji wenye deni lililoonekana kwa data iliyopo.'
          : 'No tenants with outstanding arrears in your current data.';
    }
    if (isSw) {
      return 'Wapangaji ${ctx.arrearsTenantCount} wana deni linalokadiriwa '
          '${formatMoney(ctx.arrearsTotal.round())} (kulingana na malipo yaliyorekodiwa).';
    }
    return '${ctx.arrearsTenantCount} tenant${ctx.arrearsTenantCount == 1 ? '' : 's'} '
        'with about ${formatMoney(ctx.arrearsTotal.round())} in arrears '
        '(based on recorded payments vs expected rent).';
  }

  static String _leaseExpiryAnswer(PortfolioAiContext ctx, bool isSw) {
    if (ctx.leasesExpiring30Days == 0) {
      return isSw
          ? 'Hakuna mikataba inayoisha ndani ya siku 30 zijazo.'
          : 'No leases expiring in the next 30 days.';
    }
    if (isSw) {
      return 'Mikataba ${ctx.leasesExpiring30Days} inayoisha ndani ya siku 30. '
          'Angalia orodha ya wapangaji kwa maelezo.';
    }
    return '${ctx.leasesExpiring30Days} lease${ctx.leasesExpiring30Days == 1 ? '' : 's'} '
        'expiring within 30 days. Open tenant tracker for details.';
  }

  static String _tenantAnswer(PortfolioAiContext ctx, bool isSw) {
    if (isSw) {
      return 'Wapangaji hai: ${ctx.activeTenants}. '
          'Jumla ya mali: ${ctx.propertyCount}, vitengo: ${ctx.totalUnits}.';
    }
    return 'Active tenants: ${ctx.activeTenants}. '
        'Properties: ${ctx.propertyCount}, units: ${ctx.totalUnits}.';
  }

  static String _propertyAnswer(PortfolioAiContext ctx, bool isSw) {
    final names = ctx.propertyNames;
    final list = names.isEmpty
        ? (isSw ? '(hakuna majina yaliyohifadhiwa)' : '(no saved names)')
        : names.take(5).join('\n• ');
    if (isSw) {
      return 'Una mali ${ctx.propertyCount} (${ctx.totalUnits} vitengo).\n'
          '${names.isEmpty ? '' : 'Mali:\n• $list'}';
    }
    return 'You have ${ctx.propertyCount} propert${ctx.propertyCount == 1 ? 'y' : 'ies'} '
        '(${ctx.totalUnits} units).\n${names.isEmpty ? '' : 'Properties:\n• $list'}';
  }

  static String _bookingAnswer(PortfolioAiContext ctx, bool isSw) {
    if (isSw) {
      return 'Leo: uingizaji ${ctx.checkInsToday}, uondaji ${ctx.checkOutsToday}, '
          'uhifadhi hai ${ctx.activeBookingsToday}.';
    }
    return 'Today: ${ctx.checkInsToday} check-in${ctx.checkInsToday == 1 ? '' : 's'}, '
        '${ctx.checkOutsToday} check-out${ctx.checkOutsToday == 1 ? '' : 's'}, '
        '${ctx.activeBookingsToday} active stay${ctx.activeBookingsToday == 1 ? '' : 's'}.';
  }

  static String _maintenanceAnswer(PortfolioAiContext ctx, bool isSw) {
    if (isSw) {
      return 'Kazi za matengenezo zilizopangwa: ${ctx.maintenanceTasks}.';
    }
    return 'Scheduled maintenance tasks on record: ${ctx.maintenanceTasks}.';
  }

  static String _summaryAnswer(
    PortfolioAiContext ctx,
    String Function(num) formatMoney,
    bool isSw,
  ) {
    final pct = ctx.occupancyPercent.toStringAsFixed(1);
    if (isSw) {
      return 'Muhtasari (${ctx.monthLabel}, ${ctx.workspace}):\n'
          '• Mali: ${ctx.propertyCount} · Vitengo: ${ctx.totalUnits}\n'
          '• Ukodishaji: $pct%\n'
          '• Mapato: ${formatMoney(ctx.monthIncome.round())}\n'
          '• Matumizi: ${formatMoney(ctx.monthExpenses.round())}\n'
          '• Faida: ${formatMoney(ctx.monthNet.round())}\n'
          '• Deni (wapangaji): ${ctx.arrearsTenantCount} · '
          '${formatMoney(ctx.arrearsTotal.round())}\n'
          '• Mikataba inayoisha (30d): ${ctx.leasesExpiring30Days}';
    }
    return 'Portfolio snapshot (${ctx.monthLabel}, ${ctx.workspace}):\n'
        '• Properties: ${ctx.propertyCount} · Units: ${ctx.totalUnits}\n'
        '• Occupancy: $pct%\n'
        '• Income: ${formatMoney(ctx.monthIncome.round())}\n'
        '• Expenses: ${formatMoney(ctx.monthExpenses.round())}\n'
        '• Net: ${formatMoney(ctx.monthNet.round())}\n'
        '• Arrears: ${ctx.arrearsTenantCount} tenants · '
        '${formatMoney(ctx.arrearsTotal.round())}\n'
        '• Leases expiring (30d): ${ctx.leasesExpiring30Days}';
  }
}

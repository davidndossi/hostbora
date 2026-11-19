import 'dart:convert';

import '../../../data/local/service/portfolio_ai_context.dart';
import '../../../data/local/service/portfolio_ai_local_resolver.dart';

/// One number on a summary card, matching the home summary tiles.
class HostGenUiMetric {
  const HostGenUiMetric({required this.label, required this.value});

  final String label;
  final String value;

  Map<String, String> toJson() => {'label': label, 'value': value};
}

/// One row in a list card, matching recent payments and property rows.
class HostGenUiRow {
  const HostGenUiRow({
    required this.title,
    this.subtitle = '',
    this.trailing = '',
  });

  final String title;
  final String subtitle;
  final String trailing;

  Map<String, String> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'trailing': trailing,
      };
}

/// A pill the model or a local answer can offer. [action] is a [HostGenUiActions] key.
class HostGenUiAction {
  const HostGenUiAction({required this.label, required this.action});

  final String label;
  final String action;

  Map<String, String> toJson() => {'label': label, 'action': action};
}

/// Action keys the generated card is allowed to fire.
abstract class HostGenUiActions {
  static const addProperty = 'ADD_PROPERTY';
  static const addIncome = 'ADD_INCOME';
  static const addExpense = 'ADD_EXPENSE';
  static const addBooking = 'ADD_BOOKING';
  static const addTenant = 'ADD_TENANT';
  static const sendReminder = 'SEND_REMINDER';
  static const openProperties = 'OPEN_PROPERTIES';
  static const openTenants = 'OPEN_TENANTS';
  static const openBookings = 'OPEN_BOOKINGS';
  static const openPayments = 'OPEN_PAYMENTS';
  static const openExpenses = 'OPEN_EXPENSES';
  static const openMaintenance = 'OPEN_MAINTENANCE';
  static const openInventory = 'OPEN_INVENTORY';
  static const openCalendar = 'OPEN_CALENDAR';
  static const openReports = 'OPEN_REPORTS';

  static const known = <String>{
    addProperty,
    addIncome,
    addExpense,
    addBooking,
    addTenant,
    sendReminder,
    openProperties,
    openTenants,
    openBookings,
    openPayments,
    openExpenses,
    openMaintenance,
    openInventory,
    openCalendar,
    openReports,
  };
}

/// Data for one GenUI `HostAnswer` surface.
class HostGenUiLayout {
  const HostGenUiLayout({
    required this.title,
    this.body = '',
    this.metrics = const [],
    this.rows = const [],
    this.actions = const [],
  });

  final String title;
  final String body;
  final List<HostGenUiMetric> metrics;
  final List<HostGenUiRow> rows;
  final List<HostGenUiAction> actions;

  factory HostGenUiLayout.note({
    required String title,
    required String body,
    List<HostGenUiAction> actions = const [],
  }) {
    return HostGenUiLayout(title: title, body: body, actions: actions);
  }

  /// Portfolio snapshot laid out like the home summary.
  factory HostGenUiLayout.summary({
    required PortfolioAiContext ctx,
    required String Function(num amount) formatMoney,
    required bool isSw,
  }) {
    final pct = '${ctx.occupancyPercent.toStringAsFixed(1)}%';
    return HostGenUiLayout(
      title: isSw ? 'Muhtasari wa portfolio' : 'Portfolio summary',
      body: ctx.welcomeSummary(formatMoney: formatMoney, isSw: isSw),
      metrics: [
        HostGenUiMetric(
          label: isSw ? 'Ukodishaji' : 'Occupancy',
          value: pct,
        ),
        HostGenUiMetric(
          label: isSw ? 'Mapato' : 'Income',
          value: formatMoney(ctx.monthIncome.round()),
        ),
        HostGenUiMetric(
          label: isSw ? 'Matumizi' : 'Expenses',
          value: formatMoney(ctx.monthExpenses.round()),
        ),
        HostGenUiMetric(
          label: isSw ? 'Faida' : 'Net',
          value: formatMoney(ctx.monthNet.round()),
        ),
        HostGenUiMetric(
          label: isSw ? 'Ukusanyaji' : 'Collected',
          value: '${ctx.collectionRatePercent.toStringAsFixed(0)}%',
        ),
        HostGenUiMetric(
          label: isSw ? 'Vitengo' : 'Units',
          value: '${ctx.occupiedUnits}/${ctx.totalUnits}',
        ),
      ],
      rows: [
        for (final p in ctx.properties.take(6))
          HostGenUiRow(
            title: p.name,
            subtitle: isSw
                ? '${p.occupied}/${p.units} vitengo'
                : '${p.occupied}/${p.units} units',
            trailing: '${p.occupancyPercent.toStringAsFixed(0)}%',
          ),
        if (ctx.properties.isEmpty)
          for (final name in ctx.propertyNames.take(6)) HostGenUiRow(title: name),
      ],
      actions: _followUps(isSw, const [
        HostGenUiActions.openProperties,
        HostGenUiActions.addProperty,
      ]),
    );
  }

  /// Turns a recognized portfolio question into the same card language as Home.
  /// Returns null when the question needs the model.
  static HostGenUiLayout? fromQuestion({
    required String question,
    required PortfolioAiContext ctx,
    required String Function(num amount) formatMoney,
    required bool isSw,
  }) {
    final local = PortfolioAiLocalResolver.resolve(
      question: question,
      ctx: ctx,
      formatMoney: formatMoney,
      isSw: isSw,
    );
    if (!local.matched) return null;

    final q = question.trim().toLowerCase();
    final topic = _topicFor(q, ctx);
    if (topic == null) {
      return HostGenUiLayout.note(
        title: isSw ? 'Jibu' : 'Answer',
        body: local.text,
      );
    }
    return _layoutForTopic(
      topic: topic,
      ctx: ctx,
      formatMoney: formatMoney,
      isSw: isSw,
      body: local.text,
    );
  }

  /// Parses a model reply. Prose that is not JSON becomes a note card.
  factory HostGenUiLayout.parseModel(String raw, {required bool isSw}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return HostGenUiLayout.note(
        title: isSw ? 'Jibu' : 'Answer',
        body: isSw
            ? 'Sina jibu kwa hilo kwa sasa.'
            : 'I do not have an answer for that yet.',
      );
    }
    final jsonText = _stripToJsonObject(trimmed);
    if (jsonText == null) {
      return HostGenUiLayout.note(
        title: isSw ? 'Jibu' : 'Answer',
        body: trimmed,
      );
    }
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return HostGenUiLayout.note(
          title: isSw ? 'Jibu' : 'Answer',
          body: trimmed,
        );
      }
      return HostGenUiLayout._fromModelMap(decoded, isSw: isSw, fallback: trimmed);
    } catch (_) {
      return HostGenUiLayout.note(
        title: isSw ? 'Jibu' : 'Answer',
        body: trimmed,
      );
    }
  }

  factory HostGenUiLayout._fromModelMap(
    Map<dynamic, dynamic> map, {
    required bool isSw,
    required String fallback,
  }) {
    final title = map['title']?.toString().trim() ?? '';
    final body = map['body']?.toString().trim() ?? '';
    final metrics = _metricsOf(map['metrics']);
    final rows = _rowsOf(map['rows']);
    final actions = _actionsOf(map['actions']);
    if (title.isEmpty && body.isEmpty && metrics.isEmpty && rows.isEmpty) {
      return HostGenUiLayout.note(
        title: isSw ? 'Jibu' : 'Answer',
        body: fallback,
      );
    }
    return HostGenUiLayout(
      title: title.isEmpty ? (isSw ? 'Jibu' : 'Answer') : title,
      body: body,
      metrics: metrics,
      rows: rows,
      actions: actions,
    );
  }

  Map<String, Object?> toComponentJson() => {
        'id': 'root',
        'component': 'HostAnswer',
        'title': title,
        'body': body,
        'metrics': metrics.map((m) => m.toJson()).toList(),
        'rows': rows.map((r) => r.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  static bool shouldTreatAsAction(String text) {
    final q = text.trim().toLowerCase();
    if (q.isEmpty) return false;
    if (!_command.hasMatch(q)) return false;
    final asks = q.contains('?') || _questionLead.hasMatch(q);
    if (!asks) return true;
    return _leadingCommand.hasMatch(q);
  }

  static final _command = RegExp(
    r'\b(?:add|create|record|log|open|launch|send|schedule|book|register|'
    r'check[\s-]?in|check[\s-]?out|go to|'
    r'ongeza|rekodi|fungua|tuma|panga|sajili|pokesha|shusha|maliza)\b',
    caseSensitive: false,
  );

  static final _leadingCommand = RegExp(
    r'^(?:please\s+|tafadhali\s+)?(?:add|create|record|log|open|launch|send|'
    r'schedule|book|register|check[\s-]?in|check[\s-]?out|'
    r'ongeza|rekodi|fungua|tuma|panga|sajili|pokesha|shusha|maliza)\b',
    caseSensitive: false,
  );

  static final _questionLead = RegExp(
    r'\b(?:what|how|why|when|which|who|show|list|any|occupancy|income|'
    r'expense|profit|arrear|summary|overview|nini|vipi|onyesha|orodha|'
    r'kiwango|muhtasari|mapato|matumizi|deni|ukodishaji)\b',
    caseSensitive: false,
  );

  static String? _topicFor(String q, PortfolioAiContext ctx) {
    bool has(List<String> needles) => needles.any(q.contains);
    if (has(const ['occupancy', 'occupied', 'vacant', 'ukodishaji', 'vyeo'])) {
      return 'occupancy';
    }
    if (has(const [
      'collection',
      'expected',
      'collection rate',
      'ukusanyaji',
      'kodi inayotarajiwa',
      'nimekusanya',
      'kodi iliyolipwa',
    ])) {
      return 'collection';
    }
    if (has(const [
          'income',
          'revenue',
          'earnings',
          'mapato',
        ]) &&
        !has(const ['expense', 'profit', 'net', 'gharama'])) {
      return 'income';
    }
    if (has(const ['expense', 'expenses', 'spending', 'gharama', 'matumizi', 'costs'])) {
      return 'expense';
    }
    if (has(const ['profit', 'net', 'p&l', 'faida', 'margin'])) return 'profit';
    if (has(const [
      'arrear',
      'overdue',
      'unpaid',
      'deni',
      'behind',
      'madeni',
      'hawajalipa',
      'malimbikizo',
    ])) {
      return 'arrears';
    }
    if (has(const ['expir', 'renew', 'ending', 'inayoisha', 'mkataba', 'lease'])) {
      return 'lease';
    }
    if (has(const ['tenant', 'wapangaji', 'renters', 'mpangaji'])) return 'tenant';
    if (has(const ['propert', 'listing', 'portfolio', 'mali', 'nyumba', 'summary', 'overview', 'snapshot', 'dashboard', 'muhtasari'])) {
      return 'summary';
    }
    if (ctx.isBnb &&
        has(const ['booking', 'check-in', 'check in', 'check-out', 'checkout', 'guest', 'reservation'])) {
      return 'booking';
    }
    if (ctx.isRent && has(const ['maintenance', 'repair', 'matengenezo'])) {
      return 'maintenance';
    }
    if (has(const ['summary', 'overview', 'snapshot', 'dashboard', 'muhtasari', 'hali'])) {
      return 'summary';
    }
    return null;
  }

  static HostGenUiLayout _layoutForTopic({
    required String topic,
    required PortfolioAiContext ctx,
    required String Function(num amount) formatMoney,
    required bool isSw,
    required String body,
  }) {
    switch (topic) {
      case 'occupancy':
        return HostGenUiLayout(
          title: isSw ? 'Ukodishaji' : 'Occupancy',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: isSw ? 'Ukodishaji' : 'Occupancy',
              value: '${ctx.occupancyPercent.toStringAsFixed(1)}%',
            ),
            HostGenUiMetric(
              label: isSw ? 'Vitengo' : 'Units',
              value: '${ctx.occupiedUnits}/${ctx.totalUnits}',
            ),
            HostGenUiMetric(
              label: isSw ? 'Wapangaji' : 'Tenants',
              value: '${ctx.activeTenants}',
            ),
            if (ctx.isBnb)
              HostGenUiMetric(
                label: isSw ? 'Leo' : 'Stays today',
                value: '${ctx.activeBookingsToday}',
              ),
          ],
          rows: [
            for (final p in ctx.properties.take(6))
              HostGenUiRow(
                title: p.name,
                subtitle: '${p.occupied}/${p.units}',
                trailing: '${p.occupancyPercent.toStringAsFixed(0)}%',
              ),
          ],
          actions: _followUps(isSw, const [
            HostGenUiActions.openTenants,
            HostGenUiActions.addTenant,
          ]),
        );
      case 'income':
        return HostGenUiLayout(
          title: isSw ? 'Mapato' : 'Income',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: ctx.monthLabel.isEmpty
                  ? (isSw ? 'Mwezi huu' : 'This month')
                  : ctx.monthLabel,
              value: formatMoney(ctx.monthIncome.round()),
            ),
            if (ctx.prevMonthLabel.isNotEmpty)
              HostGenUiMetric(
                label: ctx.prevMonthLabel,
                value: formatMoney(ctx.prevMonthIncome.round()),
              ),
            HostGenUiMetric(
              label: isSw ? 'Mali' : 'Properties',
              value: '${ctx.propertyCount}',
            ),
          ],
          actions: _followUps(isSw, const [
            HostGenUiActions.addIncome,
            HostGenUiActions.openPayments,
          ]),
        );
      case 'collection':
        return HostGenUiLayout(
          title: isSw ? 'Ukusanyaji' : 'Collection',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: isSw ? 'Iliyokusanywa' : 'Collected',
              value: formatMoney(ctx.monthIncome.round()),
            ),
            HostGenUiMetric(
              label: isSw ? 'Inayotarajiwa' : 'Expected',
              value: formatMoney(ctx.monthExpected.round()),
            ),
            HostGenUiMetric(
              label: isSw ? 'Kiwango' : 'Rate',
              value: '${ctx.collectionRatePercent.toStringAsFixed(0)}%',
            ),
          ],
          rows: [
            for (final row in ctx.arrearsRows.take(6))
              HostGenUiRow(
                title: row.name,
                subtitle: row.place,
                trailing: formatMoney(row.amount.round()),
              ),
          ],
          actions: _followUps(isSw, const [
            HostGenUiActions.sendReminder,
            HostGenUiActions.openPayments,
          ]),
        );
      case 'expense':
        return HostGenUiLayout(
          title: isSw ? 'Matumizi' : 'Expenses',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: ctx.monthLabel.isEmpty
                  ? (isSw ? 'Mwezi huu' : 'This month')
                  : ctx.monthLabel,
              value: formatMoney(ctx.monthExpenses.round()),
            ),
            if (ctx.prevMonthLabel.isNotEmpty)
              HostGenUiMetric(
                label: ctx.prevMonthLabel,
                value: formatMoney(ctx.prevMonthExpenses.round()),
              ),
          ],
          rows: [
            for (final b in ctx.expenseCategories.take(6))
              HostGenUiRow(
                title: b.category,
                trailing: formatMoney(b.amount.round()),
              ),
          ],
          actions: _followUps(isSw, const [
            HostGenUiActions.addExpense,
            HostGenUiActions.openExpenses,
          ]),
        );
      case 'profit':
        return HostGenUiLayout(
          title: isSw ? 'Faida' : 'Profit',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: isSw ? 'Mapato' : 'Income',
              value: formatMoney(ctx.monthIncome.round()),
            ),
            HostGenUiMetric(
              label: isSw ? 'Matumizi' : 'Expenses',
              value: formatMoney(ctx.monthExpenses.round()),
            ),
            HostGenUiMetric(
              label: isSw ? 'Faida' : 'Net',
              value: formatMoney(ctx.monthNet.round()),
            ),
          ],
          actions: _followUps(isSw, const [HostGenUiActions.openReports]),
        );
      case 'arrears':
        return HostGenUiLayout(
          title: isSw ? 'Deni' : 'Arrears',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: isSw ? 'Wapangaji' : 'Tenants',
              value: '${ctx.arrearsTenantCount}',
            ),
            HostGenUiMetric(
              label: isSw ? 'Kiasi' : 'Amount',
              value: formatMoney(ctx.arrearsTotal.round()),
            ),
          ],
          rows: [
            for (final row in ctx.arrearsRows.take(6))
              HostGenUiRow(
                title: row.name,
                subtitle: row.place,
                trailing: formatMoney(row.amount.round()),
              ),
          ],
          actions: _followUps(isSw, const [
            HostGenUiActions.sendReminder,
            HostGenUiActions.openTenants,
          ]),
        );
      case 'lease':
        return HostGenUiLayout(
          title: isSw ? 'Mikataba' : 'Leases',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: isSw ? 'Zinaisha (siku 30)' : 'Expiring (30 days)',
              value: '${ctx.leasesExpiring30Days}',
            ),
          ],
          actions: _followUps(isSw, const [HostGenUiActions.openTenants]),
        );
      case 'tenant':
        return HostGenUiLayout(
          title: isSw ? 'Wapangaji' : 'Tenants',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: isSw ? 'Hai' : 'Active',
              value: '${ctx.activeTenants}',
            ),
            HostGenUiMetric(
              label: isSw ? 'Vitengo' : 'Units',
              value: '${ctx.totalUnits}',
            ),
          ],
          actions: _followUps(isSw, const [
            HostGenUiActions.openTenants,
            HostGenUiActions.addTenant,
          ]),
        );
      case 'booking':
        return HostGenUiLayout(
          title: isSw ? 'Uhifadhi' : 'Bookings',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: isSw ? 'Kuingia' : 'Check-ins',
              value: '${ctx.checkInsToday}',
            ),
            HostGenUiMetric(
              label: isSw ? 'Kuondoka' : 'Check-outs',
              value: '${ctx.checkOutsToday}',
            ),
            HostGenUiMetric(
              label: isSw ? 'Hai' : 'Active',
              value: '${ctx.activeBookingsToday}',
            ),
          ],
          actions: _followUps(isSw, const [
            HostGenUiActions.openBookings,
            HostGenUiActions.addBooking,
          ]),
        );
      case 'maintenance':
        return HostGenUiLayout(
          title: isSw ? 'Matengenezo' : 'Maintenance',
          body: body,
          metrics: [
            HostGenUiMetric(
              label: isSw ? 'Kazi' : 'Tasks',
              value: '${ctx.maintenanceTasks}',
            ),
          ],
          actions: _followUps(isSw, const [HostGenUiActions.openMaintenance]),
        );
      case 'summary':
        final card = HostGenUiLayout.summary(
          ctx: ctx,
          formatMoney: formatMoney,
          isSw: isSw,
        );
        return HostGenUiLayout(
          title: card.title,
          body: body,
          metrics: card.metrics,
          rows: card.rows,
          actions: card.actions,
        );
      default:
        return HostGenUiLayout.note(
          title: isSw ? 'Jibu' : 'Answer',
          body: body,
        );
    }
  }

  static List<HostGenUiAction> _followUps(bool isSw, List<String> keys) {
    return [
      for (final key in keys)
        if (_labelFor(key, isSw) != null)
          HostGenUiAction(label: _labelFor(key, isSw)!, action: key),
    ];
  }

  static String? _labelFor(String key, bool isSw) {
    switch (key) {
      case HostGenUiActions.addProperty:
        return isSw ? 'Ongeza mali' : 'Add property';
      case HostGenUiActions.addIncome:
        return isSw ? 'Ongeza mapato' : 'Add income';
      case HostGenUiActions.addExpense:
        return isSw ? 'Ongeza matumizi' : 'Add expense';
      case HostGenUiActions.addBooking:
        return isSw ? 'Ongeza uhifadhi' : 'Add booking';
      case HostGenUiActions.addTenant:
        return isSw ? 'Ongeza mpangaji' : 'Add tenant';
      case HostGenUiActions.sendReminder:
        return isSw ? 'Tuma kikumbusho' : 'Send reminder';
      case HostGenUiActions.openProperties:
        return isSw ? 'Mali zangu' : 'My properties';
      case HostGenUiActions.openTenants:
        return isSw ? 'Wapangaji' : 'Tenants';
      case HostGenUiActions.openBookings:
        return isSw ? 'Uhifadhi' : 'Bookings';
      case HostGenUiActions.openPayments:
        return isSw ? 'Malipo' : 'Payments';
      case HostGenUiActions.openExpenses:
        return isSw ? 'Matumizi' : 'Expenses';
      case HostGenUiActions.openMaintenance:
        return isSw ? 'Matengenezo' : 'Maintenance';
      case HostGenUiActions.openInventory:
        return isSw ? 'Vifaa' : 'Inventory';
      case HostGenUiActions.openCalendar:
        return isSw ? 'Kalenda' : 'Calendar';
      case HostGenUiActions.openReports:
        return isSw ? 'Ripoti' : 'Reports';
      default:
        return null;
    }
  }

  static List<HostGenUiMetric> _metricsOf(Object? raw) {
    if (raw is! List) return const [];
    final out = <HostGenUiMetric>[];
    for (final item in raw.take(6)) {
      if (item is! Map) continue;
      final label = item['label']?.toString().trim() ?? '';
      final value = item['value']?.toString().trim() ?? '';
      if (label.isEmpty || value.isEmpty) continue;
      out.add(HostGenUiMetric(label: label, value: value));
    }
    return out;
  }

  static List<HostGenUiRow> _rowsOf(Object? raw) {
    if (raw is! List) return const [];
    final out = <HostGenUiRow>[];
    for (final item in raw.take(8)) {
      if (item is! Map) continue;
      final title = item['title']?.toString().trim() ?? '';
      if (title.isEmpty) continue;
      out.add(
        HostGenUiRow(
          title: title,
          subtitle: item['subtitle']?.toString().trim() ?? '',
          trailing: item['trailing']?.toString().trim() ?? '',
        ),
      );
    }
    return out;
  }

  static List<HostGenUiAction> _actionsOf(Object? raw) {
    if (raw is! List) return const [];
    final out = <HostGenUiAction>[];
    for (final item in raw.take(4)) {
      if (item is! Map) continue;
      final action = item['action']?.toString().trim().toUpperCase() ?? '';
      final label = item['label']?.toString().trim() ?? '';
      if (!HostGenUiActions.known.contains(action) || label.isEmpty) continue;
      out.add(HostGenUiAction(label: label, action: action));
    }
    return out;
  }

  static String? _stripToJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }
}

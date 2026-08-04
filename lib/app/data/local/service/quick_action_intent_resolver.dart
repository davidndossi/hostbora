import 'dart:convert';

import '../../../network/exceptions/base_exception.dart';
import '../../../routes/app_pages.dart';
import '../../model/general_response.dart';
import '../../repository/app_repository.dart';

/// The five quick actions that have a dedicated step-by-step wizard (or a
/// direct redirect) wired into the home "What do you want to do?" dialog.
enum QuickActionIntent {
  addProperty,
  addIncome,
  addExpense,
  addBooking,
  addTenant,
  unknown,
}

/// Why free-text "Other" resolution could not open a screen.
enum QuickActionFailureKind {
  /// User submitted blank text.
  empty,

  /// Network / AI service error (or unexpected exception).
  serviceUnavailable,

  /// AI (and local heuristics) could not match the request to a known action.
  unrecognized,
}

/// Result of classifying a free-text "Other (Specify)" request: either one
/// of the five wizard-backed [QuickActionIntent]s, a direct HostBora route to
/// open, or a typed failure the UI can explain.
class QuickActionResolution {
  const QuickActionResolution.wizard(QuickActionIntent action)
      : wizardAction = action,
        routeName = null,
        failureKind = null,
        failureDetail = null;

  const QuickActionResolution.route(this.routeName)
      : wizardAction = null,
        failureKind = null,
        failureDetail = null;

  const QuickActionResolution.failure(
    this.failureKind, {
    this.failureDetail,
  })  : wizardAction = null,
        routeName = null;

  final QuickActionIntent? wizardAction;
  final String? routeName;
  final QuickActionFailureKind? failureKind;
  final String? failureDetail;

  bool get isSuccess => wizardAction != null || routeName != null;
}

/// Describes one other HostBora screen the free-text request can be routed
/// to directly, beyond the five step-by-step quick actions.
class _RouteEntry {
  const _RouteEntry(this.route, this.description);

  final String route;
  final String description;
}

/// Uses the app's existing generic AI passthrough (`AppRepository.sendAiRequest`,
/// backed by `POST /api/ai/request`) to classify a free-text request typed by
/// the user (the "Other (Specify)" option). High-confidence local keyword
/// matching runs first so common HostBora requests still work when AI is
/// offline or returns an unexpected payload.
class QuickActionIntentResolver {
  QuickActionIntentResolver({required AppRepository repository})
      : _repository = repository;

  final AppRepository _repository;

  static const _wizardActionKeys = <String, QuickActionIntent>{
    'ADD_PROPERTY': QuickActionIntent.addProperty,
    'ADD_INCOME': QuickActionIntent.addIncome,
    'ADD_EXPENSE': QuickActionIntent.addExpense,
    'ADD_BOOKING': QuickActionIntent.addBooking,
    'ADD_TENANT': QuickActionIntent.addTenant,
  };

  /// Other HostBora destinations the model may route free text to directly.
  /// Deliberately limited to hubs/dashboards/lists/forms that render
  /// sensibly without a specific record id (no booking/tenant/staff/task/
  /// listing id required) — anything needing a concrete existing record is
  /// left out so navigation never lands on a broken/empty detail screen.
  static const Map<String, _RouteEntry> _routeKeys = {
    'SETTINGS': _RouteEntry(Routes.SETTINGS, 'app settings and preferences'),
    'NOTIFICATIONS': _RouteEntry(Routes.NOTIFICATIONS, 'notifications inbox'),
    'SUPPORT': _RouteEntry(Routes.SUPPORT, 'contact customer support'),
    'FEEDBACK': _RouteEntry(Routes.FEEDBACK, 'send app feedback'),
    'SECURITY': _RouteEntry(
      Routes.SECURITY,
      'security settings: app lock, PIN, biometrics',
    ),
    'SUBSCRIPTION': _RouteEntry(
      Routes.SUBSCRIPTION,
      'subscription plan and billing',
    ),
    'HELP_CENTER': _RouteEntry(
      Routes.HELP_CENTER,
      'help center and how-to guides',
    ),
    'CALENDAR_SYNC': _RouteEntry(
      Routes.CALENDAR_SYNC,
      'sync bookings with external calendars (Google/Airbnb/Booking.com)',
    ),
    'MY_PROPERTIES': _RouteEntry(
      Routes.MY_PROPERTIES,
      'list of your rent properties',
    ),
    'FINANCIAL_OVERVIEW': _RouteEntry(
      Routes.FINANCIAL_OVERVIEW,
      'overall financial overview across properties',
    ),
    'REPORTS_HUB': _RouteEntry(
      Routes.REPORTS_HUB,
      'reports and analytics hub',
    ),
    'EXPENSE_ANALYSIS': _RouteEntry(
      Routes.EXPENSE_ANALYSIS,
      'expense breakdown and analysis',
    ),
    'PRICE_ANALYSIS': _RouteEntry(
      Routes.PRICE_ANALYSIS,
      'BnB price/rate analysis',
    ),
    'AI_PRICING_OPTIMIZER': _RouteEntry(
      Routes.AI_PRICING_OPTIMIZER,
      'AI-powered pricing optimizer suggestions',
    ),
    'HOST_CALENDAR': _RouteEntry(
      Routes.HOST_CALENDAR,
      'BnB host calendar of bookings and availability',
    ),
    'ALL_BOOKINGS': _RouteEntry(
      Routes.ALL_BOOKINGS,
      'list of all BnB bookings',
    ),
    'GUEST_HISTORY': _RouteEntry(
      Routes.GUEST_HISTORY,
      'history of past BnB guests',
    ),
    'RENT_HOST_DASHBOARD_PAYMENT_ALERTS': _RouteEntry(
      Routes.RENT_HOST_DASHBOARD_PAYMENT_ALERTS,
      'rent payment alerts dashboard (overdue/upcoming rent)',
    ),
    'RENT_PROFIT_ANALYSIS_DASHBOARD': _RouteEntry(
      Routes.RENT_PROFIT_ANALYSIS_DASHBOARD,
      'rent profit analysis dashboard',
    ),
    'RENT_LISTING_ANALYTICS_DASHBOARD': _RouteEntry(
      Routes.RENT_LISTING_ANALYTICS_DASHBOARD,
      'rent listing analytics dashboard',
    ),
    'RENT_MANAGE_PAYMENTS': _RouteEntry(
      Routes.RENT_MANAGE_PAYMENTS,
      'manage and track rent payments',
    ),
    'RENT_EXPECTED_PAYMENT_SCHEDULE': _RouteEntry(
      Routes.RENT_EXPECTED_PAYMENT_SCHEDULE,
      'upcoming/expected rent payment schedule',
    ),
    'RENT_MANAGE_EXPENSES': _RouteEntry(
      Routes.RENT_MANAGE_EXPENSES,
      'manage rent property expenses',
    ),
    'RENT_MONTHLY_PL_SUMMARY': _RouteEntry(
      Routes.RENT_MONTHLY_PL_SUMMARY,
      'monthly profit & loss summary for rent properties',
    ),
    'RENT_CONTRACT_HUB': _RouteEntry(
      Routes.RENT_CONTRACT_HUB,
      'rental contracts / lease hub',
    ),
    'RENT_PROPERTY_ROI_ANALYSIS': _RouteEntry(
      Routes.RENT_PROPERTY_ROI_ANALYSIS,
      'property return-on-investment (ROI) analysis',
    ),
    'RENT_MAINTENANCE_COST_ANALYSIS': _RouteEntry(
      Routes.RENT_MAINTENANCE_COST_ANALYSIS,
      'maintenance cost analysis',
    ),
    'RENT_FINANCIAL_COMPARISON': _RouteEntry(
      Routes.RENT_FINANCIAL_COMPARISON,
      'financial comparison across periods or properties',
    ),
    'RENT_STAFF_MANAGEMENT': _RouteEntry(
      Routes.RENT_STAFF_MANAGEMENT,
      'manage rent property staff',
    ),
    'RENT_SCHEDULE_MAINTENANCE_FORM': _RouteEntry(
      Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
      'schedule a maintenance visit',
    ),
    'RENT_DEFINE_TENANT_CHARGES': _RouteEntry(
      Routes.RENT_DEFINE_TENANT_CHARGES,
      'define/configure tenant charges',
    ),
    'TENANTS': _RouteEntry(
      Routes.TENANTS,
      'tenant residency and payment tracker',
    ),
    'ALL_TENANTS': _RouteEntry(Routes.ALL_TENANTS, 'list of all tenants'),
    'RENT_DEFINE_LOYALTY_OFFERS': _RouteEntry(
      Routes.RENT_DEFINE_LOYALTY_OFFERS,
      'define tenant loyalty offers',
    ),
    'RENT_ACTIVE_LOYALTY_PROGRAMS': _RouteEntry(
      Routes.RENT_ACTIVE_LOYALTY_PROGRAMS,
      'view active tenant loyalty programs',
    ),
    'RENT_SMART_UTILITY_DASHBOARD': _RouteEntry(
      Routes.RENT_SMART_UTILITY_DASHBOARD,
      'smart utility usage dashboard',
    ),
    'RENT_CONCIERGE_INBOX': _RouteEntry(
      Routes.RENT_CONCIERGE_INBOX,
      'concierge / tenant messages inbox',
    ),
    'RENT_LOYALTY_THRESHOLDS': _RouteEntry(
      Routes.RENT_LOYALTY_THRESHOLDS,
      'configure loyalty program thresholds',
    ),
    'RENT_ESTATE_MANAGER_DASHBOARD': _RouteEntry(
      Routes.RENT_ESTATE_MANAGER_DASHBOARD,
      'estate manager dashboard',
    ),
    'RENT_LISTING_ACTIVITY_LOG': _RouteEntry(
      Routes.RENT_LISTING_ACTIVITY_LOG,
      'listing activity / audit log',
    ),
    'RENT_WHATSAPP_TEMPLATE_BUILDER': _RouteEntry(
      Routes.RENT_WHATSAPP_TEMPLATE_BUILDER,
      'build WhatsApp message templates for tenants',
    ),
    'RENT_RECURRING_REMINDERS': _RouteEntry(
      Routes.RENT_RECURRING_REMINDERS,
      'schedule rent payment reminders for tenants',
    ),
    'TEAM_AND_STAFF': _RouteEntry(
      Routes.TEAM_AND_STAFF,
      'team and staff list',
    ),
    'MAINTENANCE_TASKS': _RouteEntry(
      Routes.MAINTENANCE_TASKS,
      'maintenance tasks list',
    ),
    'ADD_TASK': _RouteEntry(
      Routes.ADD_TASK,
      'create a new maintenance task',
    ),
    'DOCUMENTS': _RouteEntry(Routes.DOCUMENTS, 'documents list'),
    'PROPERTY_VAULT': _RouteEntry(
      Routes.PROPERTY_VAULT,
      'secure property document vault',
    ),
    'DOCUMENT_SCANNER': _RouteEntry(
      Routes.DOCUMENT_SCANNER,
      'scan a new document',
    ),
    'ADD_DOCUMENT': _RouteEntry(
      Routes.ADD_DOCUMENT,
      'add/upload a document',
    ),
    'SMART_ACCESS': _RouteEntry(
      Routes.SMART_ACCESS,
      'smart access hub (smart locks, entry)',
    ),
    'GUEST_ACCESS_CODES': _RouteEntry(
      Routes.GUEST_ACCESS_CODES,
      'guest access codes',
    ),
    'SEND_SMS': _RouteEntry(
      Routes.SEND_SMS,
      'send an SMS to tenants or guests',
    ),
    'ADMIN_WHATSAPP_CREDENTIALS': _RouteEntry(
      Routes.ADMIN_WHATSAPP_CREDENTIALS,
      'WhatsApp Business credentials (admin)',
    ),
    'AI_MANAGER': _RouteEntry(
      Routes.AI_MANAGER,
      'AI assistant chat for portfolio questions, insights and automations',
    ),
    'INTERIOR_DESIGN_STUDIO': _RouteEntry(
      Routes.INTERIOR_DESIGN_STUDIO,
      'AI interior design studio',
    ),
    'DESIGN_MOODBOARDS': _RouteEntry(
      Routes.DESIGN_MOODBOARDS,
      'design moodboards list',
    ),
    'INVENTORY_TRACKING': _RouteEntry(
      Routes.INVENTORY_TRACKING,
      'inventory tracking',
    ),
    'INVENTORY_ITEM_FORM': _RouteEntry(
      Routes.INVENTORY_ITEM_FORM,
      'add a new inventory item',
    ),
  };

  /// Returns the resolved intent — a wizard action, a direct route, or a
  /// failure the UI can explain with a clear message.
  Future<QuickActionResolution> resolve(String freeText) async {
    final text = freeText.trim();
    if (text.isEmpty) {
      return const QuickActionResolution.failure(QuickActionFailureKind.empty);
    }

    final local = _matchLocally(text);
    if (local != null) return local;

    try {
      final res = await _repository.sendAiRequest({
        'prompt': _buildPrompt(text),
        'type': 'quick_action_intent',
      });

      if (!res.isSuccess) {
        final detail = res.message?.trim();
        return QuickActionResolution.failure(
          QuickActionFailureKind.serviceUnavailable,
          failureDetail: (detail != null && detail.isNotEmpty) ? detail : null,
        );
      }

      final parsed = _parseResolution(res);
      if (parsed.isSuccess) return parsed;

      // AI replied but we could not map it — treat as unrecognized.
      return const QuickActionResolution.failure(
        QuickActionFailureKind.unrecognized,
      );
    } catch (e) {
      return QuickActionResolution.failure(
        QuickActionFailureKind.serviceUnavailable,
        failureDetail: _friendlyExceptionMessage(e),
      );
    }
  }

  /// Local EN/SW phrase matching so everyday requests succeed even when AI
  /// is offline. Longer / more specific phrases are checked first.
  QuickActionResolution? _matchLocally(String text) {
    final n = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    bool hasAny(List<String> phrases) =>
        phrases.any((p) => n.contains(p));

    if (hasAny([
      'add property',
      'new property',
      'create property',
      'register property',
      'add listing',
      'new listing',
      'ongeza mali',
      'sajili mali',
      'mali mpya',
      'ongeza nyumba',
    ])) {
      return const QuickActionResolution.wizard(QuickActionIntent.addProperty);
    }
    if (hasAny([
      'add tenant',
      'new tenant',
      'create tenant',
      'ongeza mpangaji',
      'mpangaji mpya',
      'add lease',
      'new lease',
    ])) {
      return const QuickActionResolution.wizard(QuickActionIntent.addTenant);
    }
    if (hasAny([
      'add income',
      'record income',
      'record payment',
      'log income',
      'ongeza mapato',
      'rekodi malipo',
      'rekodi mapato',
      'payment received',
    ])) {
      return const QuickActionResolution.wizard(QuickActionIntent.addIncome);
    }
    if (hasAny([
      'add expense',
      'record expense',
      'log expense',
      'ongeza matumizi',
      'rekodi gharama',
      'rekodi matumizi',
      'log a cost',
      'log a bill',
    ])) {
      return const QuickActionResolution.wizard(QuickActionIntent.addExpense);
    }
    if (hasAny([
      'add booking',
      'new booking',
      'create booking',
      'ongeza uhifadhi',
      'uhifadhi mpya',
      'new reservation',
      'schedule a reservation',
    ])) {
      return const QuickActionResolution.wizard(QuickActionIntent.addBooking);
    }
    if (hasAny([
      'send reminder',
      'schedule reminder',
      'rent reminder',
      'tuma kikumbusho',
      'panga kikumbusho',
      'ukumbusho wa kodi',
      'whatsapp reminder',
    ])) {
      return const QuickActionResolution.route(Routes.RENT_RECURRING_REMINDERS);
    }
    if (hasAny(['help center', 'kituo cha msaada', 'how to', 'msaada'])) {
      return const QuickActionResolution.route(Routes.HELP_CENTER);
    }
    if (hasAny(['settings', 'preferences', 'mipangilio'])) {
      return const QuickActionResolution.route(Routes.SETTINGS);
    }
    if (hasAny(['reports', 'analytics', 'ripoti'])) {
      return const QuickActionResolution.route(Routes.REPORTS_HUB);
    }
    if (hasAny(['calendar sync', 'sync calendar', 'google calendar'])) {
      return const QuickActionResolution.route(Routes.CALENDAR_SYNC);
    }
    if (hasAny(['host calendar', 'booking calendar', 'kalenda'])) {
      return const QuickActionResolution.route(Routes.HOST_CALENDAR);
    }
    if (hasAny(['manage payments', 'rent payments', 'malipo ya kodi'])) {
      return const QuickActionResolution.route(Routes.RENT_MANAGE_PAYMENTS);
    }
    if (hasAny([
      'schedule maintenance',
      'panga matengenezo',
      'maintenance',
      'matengenezo',
    ])) {
      return const QuickActionResolution.route(
        Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
      );
    }
    if (hasAny(['staff', 'wafanyakazi', 'team'])) {
      return const QuickActionResolution.route(Routes.TEAM_AND_STAFF);
    }
    if (hasAny(['send sms', 'tuma sms'])) {
      return const QuickActionResolution.route(Routes.SEND_SMS);
    }
    if (hasAny(['document vault', 'documents', 'hati', 'vault'])) {
      return const QuickActionResolution.route(Routes.DOCUMENTS);
    }
    if (hasAny(['ai assistant', 'ai manager', 'ask ai'])) {
      return const QuickActionResolution.route(Routes.AI_MANAGER);
    }
    if (hasAny(['subscription', 'billing', 'usajili'])) {
      return const QuickActionResolution.route(Routes.SUBSCRIPTION);
    }
    if (hasAny(['contact support', 'customer support', 'msaada wa wateja'])) {
      return const QuickActionResolution.route(Routes.SUPPORT);
    }
    return null;
  }

  String? _friendlyExceptionMessage(Object e) {
    if (e is BaseException) {
      final msg = e.message.trim();
      if (msg.isNotEmpty) return msg;
    }
    final raw = e.toString().trim();
    if (raw.isEmpty || raw == 'Exception') return null;
    // Avoid dumping long stack-like strings into the UI.
    if (raw.length > 160) return null;
    return raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  String _buildPrompt(String text) {
    final routeCatalog = _routeKeys.entries
        .map((e) => '- ${e.key}: ${e.value.description}')
        .join('\n');

    return '''
You are the intent classifier for "HostBora", a mobile app used by landlords,
hosts, and property managers in Tanzania to run both short-stay BnB
properties and long-term rental properties from one place. HostBora covers a
wide range of features, including: adding/editing properties and apartment
units; BnB guest bookings and a host calendar; rent tenants, leases, and
schedule/track rent payments; recording income and expenses; financial
reports and profit/loss dashboards; subscription and payment-link billing
(via Snippe/WhatsApp); staff and maintenance task management; document vault
and scanning; smart access/guest codes; utilities and loyalty programs for
rent tenants; WhatsApp/SMS communications; and AI-assisted tools (pricing,
insights, interior design, automations, portfolio Q&A).

The user typed a free-text request from the home screen's quick-actions
dialog. First, check if it clearly matches ONE of these five specific quick
actions:

- ADD_PROPERTY: create a new rental/BnB property listing (or add apartment units)
- ADD_INCOME: record a rent/booking payment received
- ADD_EXPENSE: record money spent (maintenance, supplies, utilities, salaries, tax, etc.)
- ADD_BOOKING: create a new BnB/guest booking
- ADD_TENANT: add a new tenant/lease to a rental unit

If it matches one of those, reply with strict JSON in this exact shape:
{"action": "ADD_PROPERTY"}

Otherwise, check if the request instead matches opening one of these other
HostBora screens (each identified by a route key):

$routeCatalog

If it matches one of those, reply with strict JSON in this exact shape,
using the exact route key from the list above:
{"action": "OPEN_ROUTE", "route": "HOST_CALENDAR"}

If the request is unrelated to HostBora, or you cannot confidently match it
to any of the actions or routes above, reply with strict JSON in this exact
shape:
{"action": "UNKNOWN"}

Reply with ONLY strict JSON, no markdown, no explanation.

User request: "$text"
''';
  }

  QuickActionResolution _parseResolution(GeneralResponse res) {
    final text = _extractReplyText(res);
    if (text.isEmpty) {
      return const QuickActionResolution.failure(
        QuickActionFailureKind.unrecognized,
      );
    }
    final jsonText = _stripToJsonObject(text);
    if (jsonText == null) {
      return const QuickActionResolution.failure(
        QuickActionFailureKind.unrecognized,
      );
    }

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map) {
        final action = decoded['action']?.toString().trim().toUpperCase();
        if (action == null || action.isEmpty || action == 'UNKNOWN') {
          return const QuickActionResolution.failure(
            QuickActionFailureKind.unrecognized,
          );
        }

        final wizard = _wizardActionKeys[action];
        if (wizard != null) return QuickActionResolution.wizard(wizard);

        if (action == 'OPEN_ROUTE') {
          final routeKey =
              decoded['route']?.toString().trim().toUpperCase() ?? '';
          final entry = _routeKeys[routeKey];
          if (entry != null) return QuickActionResolution.route(entry.route);
        }
      }
    } catch (_) {}
    return const QuickActionResolution.failure(
      QuickActionFailureKind.unrecognized,
    );
  }

  /// Extracts the first `{...}` block from the model's reply, tolerating
  /// markdown code fences or surrounding prose.
  String? _stripToJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  static String _extractReplyText(GeneralResponse res) {
    final data = res.data;
    if (data is String) return data;
    if (data is Map) {
      for (final key in ['text', 'reply', 'answer', 'content', 'message']) {
        final v = data[key]?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
    }
    return data?.toString() ?? '';
  }
}

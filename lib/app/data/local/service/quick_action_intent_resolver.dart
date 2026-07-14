import 'dart:convert';

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

/// Result of classifying a free-text "Other (Specify)" request: either one
/// of the five wizard-backed [QuickActionIntent]s, a direct HostBora route to
/// open, or unknown (could not confidently classify).
class QuickActionResolution {
  const QuickActionResolution.wizard(QuickActionIntent action)
      : wizardAction = action,
        routeName = null;

  const QuickActionResolution.route(this.routeName) : wizardAction = null;

  const QuickActionResolution.unknown()
      : wizardAction = null,
        routeName = null;

  final QuickActionIntent? wizardAction;
  final String? routeName;

  bool get isUnknown => wizardAction == null && routeName == null;
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
/// the user (the "Other (Specify)" option). The prompt gives the model
/// context on the full HostBora app — both BnB and Rent management, finance,
/// staff, documents, smart access, communications, and AI tools — plus a
/// catalog of the concrete screens it can open, so it can route the request
/// far beyond just the five headline quick actions. No new backend endpoint
/// is required: the model is instructed to reply with strict JSON, which is
/// parsed on the client.
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

  /// Returns the resolved intent — a wizard action, a direct route, or
  /// unknown if the AI could not confidently classify the request or the
  /// call failed.
  Future<QuickActionResolution> resolve(String freeText) async {
    final text = freeText.trim();
    if (text.isEmpty) return const QuickActionResolution.unknown();

    try {
      final res = await _repository.sendAiRequest({
        'prompt': _buildPrompt(text),
        'type': 'quick_action_intent',
      });
      return _parseResolution(res);
    } catch (_) {
      return const QuickActionResolution.unknown();
    }
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
    if (text.isEmpty) return const QuickActionResolution.unknown();
    final jsonText = _stripToJsonObject(text);
    if (jsonText == null) return const QuickActionResolution.unknown();

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map) {
        final action = decoded['action']?.toString().trim().toUpperCase();
        if (action == null || action.isEmpty) {
          return const QuickActionResolution.unknown();
        }

        final wizard = _wizardActionKeys[action];
        if (wizard != null) return QuickActionResolution.wizard(wizard);

        if (action == 'OPEN_ROUTE') {
          final routeKey = decoded['route']?.toString().trim().toUpperCase() ?? '';
          final entry = _routeKeys[routeKey];
          if (entry != null) return QuickActionResolution.route(entry.route);
        }
      }
    } catch (_) {}
    return const QuickActionResolution.unknown();
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

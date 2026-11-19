import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/local/db/property_local_data_source.dart';
import '../../data/local/preference/preference_manager.dart';
import '../../data/model/subscription_status.dart';
import '../../data/service/subscription_service.dart';
import '../../routes/app_pages.dart';
import '../utils/plan_gate.dart';

/// What the signed-in plan is allowed to open and how far it can grow.
enum PlanCapability {
  starter,
  pro,
  ultra,
}

/// Enforces one subscription tier. Free and Starter share [FreeStarterPlanAgent].
abstract class PlanAccessAgent {
  const PlanAccessAgent();

  String get name;

  /// Null means no property cap.
  int? get maxProperties;

  /// Null means no per-property unit cap.
  int? get maxUnitsPerProperty;

  /// When true, lists and totals stay inside the current calendar month.
  bool get currentMonthOnly;

  bool allows(PlanCapability capability);

  /// Plan the user must buy to pass a denied route. Null means the route is open.
  RequiredPlan? upgradeForRoute(String route) {
    final capability = _capabilityForRoute(route);
    if (capability == null || allows(capability)) return null;
    return capability == PlanCapability.ultra
        ? RequiredPlan.ultra
        : RequiredPlan.pro;
  }
}

/// Agent 1. Free is the same toolkit as Starter, with a smaller portfolio
/// and only the current month of history.
class FreeStarterPlanAgent extends PlanAccessAgent {
  const FreeStarterPlanAgent({required this.isFree});

  final bool isFree;

  @override
  String get name => isFree ? 'Free' : 'Starter';

  @override
  int? get maxProperties => isFree ? 1 : 3;

  @override
  int? get maxUnitsPerProperty => isFree ? 2 : null;

  @override
  bool get currentMonthOnly => isFree;

  @override
  bool allows(PlanCapability capability) => capability == PlanCapability.starter;
}

/// Agent 2. Pro adds team, messaging, documents, reports, and a 10-property cap.
class ProPlanAgent extends PlanAccessAgent {
  const ProPlanAgent();

  @override
  String get name => 'Pro';

  @override
  int? get maxProperties => 10;

  @override
  int? get maxUnitsPerProperty => null;

  @override
  bool get currentMonthOnly => false;

  @override
  bool allows(PlanCapability capability) => capability != PlanCapability.ultra;
}

/// Agent 3. Ultra opens every feature and removes the property cap.
class UltraPlanAgent extends PlanAccessAgent {
  const UltraPlanAgent();

  @override
  String get name => 'Ultra';

  @override
  int? get maxProperties => null;

  @override
  int? get maxUnitsPerProperty => null;

  @override
  bool get currentMonthOnly => false;

  @override
  bool allows(PlanCapability capability) => true;
}

/// Picks the agent for the signed-in subscription and applies its rules.
class PlanAccess {
  PlanAccess._();

  static PlanAccessAgent get agent {
    if (!Get.isRegistered<SubscriptionService>()) {
      return const FreeStarterPlanAgent(isFree: true);
    }
    final status = Get.find<SubscriptionService>().status.value;
    return agentFor(status);
  }

  static PlanAccessAgent agentFor(SubscriptionStatus status) {
    if (status.status == 'loading') {
      return const UltraPlanAgent();
    }
    if (!status.isActive) {
      return const FreeStarterPlanAgent(isFree: true);
    }
    switch (status.plan) {
      case 'ultra':
        return const UltraPlanAgent();
      case 'pro':
        return const ProPlanAgent();
      case 'starter':
        return const FreeStarterPlanAgent(isFree: false);
      default:
        return const FreeStarterPlanAgent(isFree: false);
    }
  }

  static bool allowsRoute(String? route) {
    if (route == null || route.isEmpty) return true;
    return agent.upgradeForRoute(route) == null;
  }

  static DateTime? historyStart([DateTime? now]) {
    if (!agent.currentMonthOnly) return null;
    final clock = now ?? DateTime.now();
    return DateTime(clock.year, clock.month, 1);
  }

  static bool isInPlanHistory(DateTime day) {
    final start = historyStart();
    if (start == null) return true;
    final date = DateTime(day.year, day.month, day.day);
    return !date.isBefore(start);
  }

  static void denyRoute(String route) {
    final required = agent.upgradeForRoute(route);
    if (required == null) return;
    final feature = _featureLabel(route);
    PlanGate.showUpgradeSheet(required, featureName: feature);
  }

  static Future<bool> canAddProperty() async {
    final max = agent.maxProperties;
    if (max == null) return true;
    final count = await _visiblePropertyCount();
    if (count < max) return true;
    final next = _planAbovePropertyCap();
    final sw = Get.locale?.languageCode == 'sw';
    PlanGate.showUpgradeSheet(
      next.required,
      planName: next.name,
      featureName: sw ? 'Mali zaidi' : 'More properties',
      subtitle: sw
          ? '${agent.name} inaruhusu mali $max. ${next.name} inaongeza kikomo.'
          : '${agent.name} includes up to $max ${max == 1 ? 'property' : 'properties'}. ${next.name} raises that limit.',
    );
    return false;
  }

  static bool canAddUnit({required int currentUnitCount}) {
    final max = agent.maxUnitsPerProperty;
    if (max == null || currentUnitCount < max) return true;
    final sw = Get.locale?.languageCode == 'sw';
    PlanGate.showUpgradeSheet(
      RequiredPlan.pro,
      planName: 'Starter',
      featureName: sw ? 'Uniti zaidi' : 'More units',
      subtitle: sw
          ? 'Mpango wa bila malipo unaruhusu uniti $max kwa mali. Starter inaondoa kikomo hicho.'
          : 'Free includes up to $max units on a property. Starter removes that limit.',
    );
    return false;
  }
}

class PlanAccessNavigatorObserver extends NavigatorObserver {
  String? _promptingRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name == null || allowsRouteSafe(name)) return;
    if (_promptingRoute == name) return;
    _promptingRoute = name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptingRoute = null;
      if (Get.currentRoute == name) {
        final nav = Get.key.currentState;
        if (nav != null && nav.canPop()) nav.pop();
      }
      if (Get.isBottomSheetOpen == true) return;
      PlanAccess.denyRoute(name);
    });
  }

  static bool allowsRouteSafe(String name) {
    if (!Get.isRegistered<SubscriptionService>()) return true;
    return PlanAccess.allowsRoute(name);
  }
}

Future<int> _visiblePropertyCount() async {
  if (!Get.isRegistered<PropertyLocalDataSource>()) return 0;
  var userId = '';
  try {
    final prefs = Get.find<PreferenceManager>(
      tag: (PreferenceManager).toString(),
    );
    userId = (await prefs.getUser()).id?.trim() ?? '';
  } catch (_) {}
  final local = Get.find<PropertyLocalDataSource>();
  final ids = <int>{};
  for (final workspace in const ['bnb', 'rent']) {
    final rows = await local.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: workspace,
    );
    for (final row in rows) {
      ids.add(row.id);
    }
  }
  return ids.length;
}

({RequiredPlan required, String name}) _planAbovePropertyCap() {
  final current = PlanAccess.agent;
  if (current is UltraPlanAgent) {
    return (required: RequiredPlan.ultra, name: 'Ultra');
  }
  if (current is ProPlanAgent) {
    return (required: RequiredPlan.ultra, name: 'Ultra');
  }
  if (current is FreeStarterPlanAgent && !current.isFree) {
    return (required: RequiredPlan.pro, name: 'Pro');
  }
  return (required: RequiredPlan.pro, name: 'Starter');
}

PlanCapability? _capabilityForRoute(String route) {
  if (_ultraRoutes.contains(route)) return PlanCapability.ultra;
  if (_proRoutes.contains(route)) return PlanCapability.pro;
  return null;
}

String _featureLabel(String route) {
  return _featureLabels[route] ?? 'This feature';
}

const _proRoutes = <String>{
  Routes.TEAM_AND_STAFF,
  Routes.STAFF_DETAIL,
  Routes.RENT_STAFF_MANAGEMENT,
  Routes.RENT_STAFF_PAYROLL_DETAILS,
  Routes.CALENDAR_SYNC,
  Routes.SEND_SMS,
  Routes.RENT_WHATSAPP_TEMPLATE_BUILDER,
  Routes.DOCUMENTS,
  Routes.PROPERTY_VAULT,
  Routes.DOCUMENT_SCANNER,
  Routes.REFINE_SCAN,
  Routes.ADD_DOCUMENT,
  Routes.INVENTORY_TRACKING,
  Routes.INVENTORY_ITEM_FORM,
  Routes.REPORTS_HUB,
  Routes.REPORTS_MONTHLY_INCOME,
  Routes.EXPENSE_ANALYSIS,
  Routes.RENT_PROFIT_ANALYSIS_DASHBOARD,
  Routes.RENT_LISTING_ANALYTICS_DASHBOARD,
  Routes.RENT_PROPERTY_ROI_ANALYSIS,
  Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
  Routes.RENT_MONTHLY_PL_SUMMARY,
  Routes.RENT_MAINTENANCE_COST_ANALYSIS,
  Routes.RENT_APARTMENT_REPORTS,
  Routes.RENT_EXPECTED_PAYMENT_SCHEDULE,
  Routes.RENT_LEASE_RENEWAL_FORM,
  Routes.RENT_SHARE_RENEWED_LEASE,
  Routes.RENT_CONTRACT_HUB,
  Routes.RENT_DEFINE_LOYALTY_OFFERS,
  Routes.RENT_ACTIVE_LOYALTY_PROGRAMS,
  Routes.RENT_CONCIERGE_INBOX,
  Routes.MY_NETWORK,
  Routes.PROPERTY_MANAGERS,
  Routes.PROPERTY_MANAGER_PROFILE,
  Routes.RENT_SMART_UTILITY_DASHBOARD,
  Routes.RENT_UTILITY_USAGE_GRAPH,
};

const _ultraRoutes = <String>{
  Routes.SMART_ACCESS,
  Routes.ENTRY_LOGS,
  Routes.AI_MANAGER,
  Routes.AI_INSIGHTS,
  Routes.AI_AUTOMATIONS,
  Routes.PRICE_ANALYSIS,
  Routes.AI_PRICING_OPTIMIZER,
  Routes.INTERIOR_DESIGN_STUDIO,
  Routes.DESIGN_MOODBOARD,
  Routes.DESIGN_MOODBOARDS,
};

const _featureLabels = <String, String>{
  Routes.TEAM_AND_STAFF: 'Staff',
  Routes.STAFF_DETAIL: 'Staff',
  Routes.RENT_STAFF_MANAGEMENT: 'Staff',
  Routes.RENT_STAFF_PAYROLL_DETAILS: 'Payroll',
  Routes.CALENDAR_SYNC: 'Calendar sync',
  Routes.SEND_SMS: 'SMS / WhatsApp',
  Routes.RENT_WHATSAPP_TEMPLATE_BUILDER: 'WhatsApp templates',
  Routes.DOCUMENTS: 'Document vault',
  Routes.PROPERTY_VAULT: 'Document vault',
  Routes.DOCUMENT_SCANNER: 'Document scanner',
  Routes.REFINE_SCAN: 'Document scanner',
  Routes.ADD_DOCUMENT: 'Document vault',
  Routes.INVENTORY_TRACKING: 'Inventory',
  Routes.INVENTORY_ITEM_FORM: 'Inventory',
  Routes.REPORTS_HUB: 'Reports',
  Routes.REPORTS_MONTHLY_INCOME: 'Reports',
  Routes.EXPENSE_ANALYSIS: 'Expense analysis',
  Routes.RENT_PROFIT_ANALYSIS_DASHBOARD: 'Profit analysis',
  Routes.RENT_LISTING_ANALYTICS_DASHBOARD: 'Listing analytics',
  Routes.RENT_PROPERTY_ROI_ANALYSIS: 'ROI analysis',
  Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM: 'ROI analysis',
  Routes.RENT_MONTHLY_PL_SUMMARY: 'Monthly profit and loss',
  Routes.RENT_MAINTENANCE_COST_ANALYSIS: 'Maintenance cost analysis',
  Routes.RENT_APARTMENT_REPORTS: 'Apartment reports',
  Routes.RENT_EXPECTED_PAYMENT_SCHEDULE: 'Payment schedules',
  Routes.RENT_LEASE_RENEWAL_FORM: 'Lease renewal',
  Routes.RENT_SHARE_RENEWED_LEASE: 'Lease renewal',
  Routes.RENT_CONTRACT_HUB: 'Contract hub',
  Routes.RENT_DEFINE_LOYALTY_OFFERS: 'Loyalty programs',
  Routes.RENT_ACTIVE_LOYALTY_PROGRAMS: 'Loyalty programs',
  Routes.RENT_CONCIERGE_INBOX: 'Concierge inbox',
  Routes.MY_NETWORK: 'My Network',
  Routes.PROPERTY_MANAGERS: 'Property managers',
  Routes.PROPERTY_MANAGER_PROFILE: 'Property managers',
  Routes.RENT_SMART_UTILITY_DASHBOARD: 'Utility dashboard',
  Routes.RENT_UTILITY_USAGE_GRAPH: 'Utility usage',
  Routes.SMART_ACCESS: 'Smart locks',
  Routes.ENTRY_LOGS: 'Entry logs',
  Routes.AI_MANAGER: 'AI Manager',
  Routes.AI_INSIGHTS: 'AI Manager',
  Routes.AI_AUTOMATIONS: 'AI Manager',
  Routes.PRICE_ANALYSIS: 'AI pricing',
  Routes.AI_PRICING_OPTIMIZER: 'AI pricing',
  Routes.INTERIOR_DESIGN_STUDIO: 'Interior design studio',
  Routes.DESIGN_MOODBOARD: 'Interior design studio',
  Routes.DESIGN_MOODBOARDS: 'Interior design studio',
};

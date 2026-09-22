import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import '../../routes/app_pages.dart';

/// Checklist keys shared with the Kotlin API. Owner-only actions are not listed.
class StaffPermissions {
  static const viewProperties = 'view_properties';
  static const editProperties = 'edit_properties';
  static const viewBookings = 'view_bookings';
  static const checkInOut = 'check_in_out';
  static const messageGuest = 'message_guest';
  static const manageBookings = 'manage_bookings';
  static const viewPayments = 'view_payments';
  static const recordPayment = 'record_payment';
  static const viewExpenses = 'view_expenses';
  static const manageExpenses = 'manage_expenses';
  static const viewReports = 'view_reports';
  static const exportReports = 'export_reports';
  static const viewInventory = 'view_inventory';
  static const manageInventory = 'manage_inventory';
  static const viewTasks = 'view_tasks';
  static const completeTasks = 'complete_tasks';
  static const manageTasks = 'manage_tasks';
  static const viewTenants = 'view_tenants';
  static const manageTenants = 'manage_tenants';

  static const roleCleaner = 'cleaner';
  static const roleCaretaker = 'caretaker';
  static const roleFrontDesk = 'front_desk';
  static const roleAccountant = 'accountant';
  static const roleManager = 'manager';

  static const roles = <String>[
    roleCleaner,
    roleCaretaker,
    roleFrontDesk,
    roleAccountant,
    roleManager,
  ];

  static const groups = <StaffPermissionGroup>[
    StaffPermissionGroup('properties', [viewProperties, editProperties]),
    StaffPermissionGroup('bookings', [
      viewBookings,
      checkInOut,
      messageGuest,
      manageBookings,
    ]),
    StaffPermissionGroup('payments', [viewPayments, recordPayment]),
    StaffPermissionGroup('expenses', [viewExpenses, manageExpenses]),
    StaffPermissionGroup('reports', [viewReports, exportReports]),
    StaffPermissionGroup('inventory', [viewInventory, manageInventory]),
    StaffPermissionGroup('tasks', [viewTasks, completeTasks, manageTasks]),
    StaffPermissionGroup('tenants', [viewTenants, manageTenants]),
  ];

  static const all = <String>[
    viewProperties,
    editProperties,
    viewBookings,
    checkInOut,
    messageGuest,
    manageBookings,
    viewPayments,
    recordPayment,
    viewExpenses,
    manageExpenses,
    viewReports,
    exportReports,
    viewInventory,
    manageInventory,
    viewTasks,
    completeTasks,
    manageTasks,
    viewTenants,
    manageTenants,
  ];

  static Set<String> preset(String role) {
    switch (role) {
      case roleCaretaker:
        return {
          viewTasks,
          completeTasks,
          viewInventory,
          viewBookings,
          checkInOut,
          messageGuest,
        };
      case roleFrontDesk:
        return {
          viewBookings,
          manageBookings,
          checkInOut,
          messageGuest,
          viewPayments,
          recordPayment,
        };
      case roleAccountant:
        return {
          viewPayments,
          recordPayment,
          viewExpenses,
          manageExpenses,
          viewReports,
          exportReports,
        };
      case roleManager:
        return all.toSet();
      case roleCleaner:
      default:
        return {viewTasks, completeTasks, viewInventory};
    }
  }

  /// Cleaner and caretaker start on selected properties. Other roles start on all.
  static bool defaultAllProperties(String role) {
    return role != roleCleaner && role != roleCaretaker;
  }
}

class StaffPermissionGroup {
  const StaffPermissionGroup(this.id, this.keys);
  final String id;
  final List<String> keys;
}

/// Session flags loaded from login and GET /api/me/access.
/// Owners and portfolio managers stay unrestricted (`restricted == false`).
class StaffAccessStore extends GetxService {
  StaffAccessStore(this._prefs);

  final PreferenceManager _prefs;

  final restricted = false.obs;
  final permissions = <String>{}.obs;
  final allProperties = true.obs;
  final propertyRefs = <String>{}.obs;

  DateTime? _deniedAt;

  bool allows(String key) => !restricted.value || permissions.contains(key);

  bool allowsAny(Iterable<String> keys) => !restricted.value || keys.any(permissions.contains);

  bool allowsRoute(String? route) {
    if (route == null || route.isEmpty) return true;
    if (!restricted.value) return true;
    if (_ownerOnlyRoutes.contains(route)) return false;
    if (route == Routes.TASK_DETAIL) {
      return allowsAny(const [
        StaffPermissions.viewTasks,
        StaffPermissions.completeTasks,
      ]);
    }
    final required = _routePermission[route];
    if (required == null) {
      if (route.contains('report') ||
          route.contains('profit') ||
          route.contains('analytics') ||
          route.contains('financial')) {
        return allows(StaffPermissions.viewReports);
      }
      return true;
    }
    return allows(required);
  }

  bool allowsMenu(String menuCodeName) {
    switch (menuCodeName) {
      case 'PROPERTIES':
        return allows(StaffPermissions.viewProperties);
      case 'FINANCES':
        return allowsAny(const [
          StaffPermissions.viewPayments,
          StaffPermissions.viewExpenses,
          StaffPermissions.viewReports,
        ]);
      case 'MAINTENANCE':
        return allowsAny(const [
          StaffPermissions.viewTasks,
          StaffPermissions.completeTasks,
          StaffPermissions.viewInventory,
        ]);
      default:
        return true;
    }
  }

  Future<void> load() async {
    restricted.value = await _prefs.getBool(
      PreferenceManager.keyStaffRestricted,
      defaultValue: false,
    );
    final stored = await _prefs.getStringList(PreferenceManager.keyStaffPermissions);
    permissions
      ..clear()
      ..addAll(stored);
    allProperties.value = await _prefs.getBool(
      PreferenceManager.keyStaffAllProperties,
      defaultValue: true,
    );
    final refs = await _prefs.getStringList(PreferenceManager.keyStaffPropertyRefs);
    propertyRefs
      ..clear()
      ..addAll(refs);
  }

  Future<void> applyPayload(Map<String, dynamic>? map) async {
    if (map == null || !map.containsKey('staffRestricted')) {
      await applyUnrestricted();
      return;
    }
    final isRestricted = map['staffRestricted'] == true;
    if (!isRestricted) {
      await applyUnrestricted();
      return;
    }
    final rawPerms = map['staffPermissions'];
    final perms = <String>{};
    if (rawPerms is List) {
      for (final item in rawPerms) {
        final key = item.toString().trim();
        if (key.isNotEmpty) perms.add(key);
      }
    }
    final scope = map['propertyScope'];
    var all = true;
    final refs = <String>{};
    if (scope is Map) {
      all = scope['allProperties'] == true;
      final rawRefs = scope['propertyRefs'];
      if (rawRefs is List) {
        for (final item in rawRefs) {
          final ref = item.toString().trim();
          if (ref.isNotEmpty) refs.add(ref);
        }
      }
    }
    restricted.value = true;
    permissions
      ..clear()
      ..addAll(perms);
    allProperties.value = all;
    propertyRefs
      ..clear()
      ..addAll(refs);
    await _prefs.setBool(PreferenceManager.keyStaffRestricted, true);
    await _prefs.setStringList(
      PreferenceManager.keyStaffPermissions,
      perms.toList(),
    );
    await _prefs.setBool(PreferenceManager.keyStaffAllProperties, all);
    await _prefs.setStringList(
      PreferenceManager.keyStaffPropertyRefs,
      refs.toList(),
    );
  }

  Future<void> applyUnrestricted() async {
    restricted.value = false;
    permissions.clear();
    allProperties.value = true;
    propertyRefs.clear();
    await _prefs.setBool(PreferenceManager.keyStaffRestricted, false);
    await _prefs.setStringList(PreferenceManager.keyStaffPermissions, const []);
    await _prefs.setBool(PreferenceManager.keyStaffAllProperties, true);
    await _prefs.setStringList(PreferenceManager.keyStaffPropertyRefs, const []);
  }

  void showDenied() {
    final now = DateTime.now();
    if (_deniedAt != null && now.difference(_deniedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _deniedAt = now;
    final sw = Get.locale?.languageCode == 'sw';
    Get.snackbar(
      sw ? 'Ruhusa' : 'Access',
      sw ? 'Huna ruhusa' : "You don't have access",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
    );
  }
}

class StaffAccessNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name == null || !Get.isRegistered<StaffAccessStore>()) return;
    final store = Get.find<StaffAccessStore>();
    if (store.allowsRoute(name)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.showDenied();
      final nav = Get.key.currentState;
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
    });
  }
}

const _ownerOnlyRoutes = <String>{
  Routes.SUBSCRIPTION,
  Routes.TEAM_AND_STAFF,
  Routes.RENT_STAFF_MANAGEMENT,
  Routes.STAFF_DETAIL,
  Routes.RENT_STAFF_PAYROLL_DETAILS,
};

const _routePermission = <String, String>{
  Routes.MY_PROPERTIES: StaffPermissions.viewProperties,
  Routes.LISTING_DETAILS: StaffPermissions.viewProperties,
  Routes.LISTING_UNIT_OCCUPANCY: StaffPermissions.viewProperties,
  Routes.ADD_LISTING: StaffPermissions.editProperties,
  Routes.EDIT_LISTING: StaffPermissions.editProperties,
  Routes.EDIT_UNIT: StaffPermissions.editProperties,
  Routes.ALL_BOOKINGS: StaffPermissions.viewBookings,
  Routes.BOOKING_DETAILS: StaffPermissions.viewBookings,
  Routes.HOST_CALENDAR: StaffPermissions.viewBookings,
  Routes.GUEST_HISTORY: StaffPermissions.viewBookings,
  Routes.ADD_NEW_BOOKING: StaffPermissions.manageBookings,
  Routes.RENT_MANAGE_PAYMENTS: StaffPermissions.viewPayments,
  Routes.RENT_EXPECTED_PAYMENT_SCHEDULE: StaffPermissions.viewPayments,
  Routes.RECORD_PAYMENT: StaffPermissions.recordPayment,
  Routes.RENT_MANAGE_EXPENSES: StaffPermissions.viewExpenses,
  Routes.EXPENSE_ANALYSIS: StaffPermissions.viewExpenses,
  Routes.ADD_EXPENSE: StaffPermissions.manageExpenses,
  Routes.FINANCIAL_OVERVIEW: StaffPermissions.viewReports,
  Routes.REPORTS_HUB: StaffPermissions.viewReports,
  Routes.REPORTS_MONTHLY_INCOME: StaffPermissions.viewReports,
  Routes.INVENTORY_TRACKING: StaffPermissions.viewInventory,
  Routes.INVENTORY_ITEM_FORM: StaffPermissions.manageInventory,
  Routes.MAINTENANCE_TASKS: StaffPermissions.viewTasks,
  Routes.TASK_DETAIL: StaffPermissions.viewTasks,
  Routes.ADD_TASK: StaffPermissions.manageTasks,
  Routes.EDIT_TASK: StaffPermissions.manageTasks,
  Routes.ALL_TENANTS: StaffPermissions.viewTenants,
  Routes.ADD_NEW_TENANT: StaffPermissions.manageTenants,
  Routes.SEND_SMS: StaffPermissions.messageGuest,
  Routes.RENT_CONCIERGE_INBOX: StaffPermissions.messageGuest,
  Routes.RENT_WHATSAPP_TEMPLATE_BUILDER: StaffPermissions.messageGuest,
  Routes.GUEST_ACCESS_CODES: StaffPermissions.checkInOut,
};

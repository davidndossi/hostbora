import '../../data/local/preference/preference_manager.dart';
import '../../routes/app_pages.dart';

/// Host Bora sales-agent login: `sales_agent` is issued by the API when the
/// signed-in user is an active [SalesAgent]. Admins who are also agents keep
/// the host/admin app; everyone else with this role only sees the agent shell.
class SalesAgentSession {
  static const roleName = 'sales_agent';

  static bool hasAgentRole(Iterable<String>? roles) =>
      (roles ?? const []).any((r) => r.toLowerCase() == roleName);

  static bool isAgentOnly({
    required Iterable<String>? roles,
    required bool isAdmin,
  }) {
    if (!hasAgentRole(roles)) return false;
    if (isAdmin) return false;
    if ((roles ?? const []).any((r) => r.toLowerCase() == 'admin')) {
      return false;
    }
    return true;
  }

  static Future<String> homeRoute(PreferenceManager prefs) async {
    try {
      final user = await prefs.getUser();
      final stored = await prefs.getStringList(
        PreferenceManager.keyRoles,
        defaultValue: const [],
      );
      final roles =
          (user.roles != null && user.roles!.isNotEmpty) ? user.roles! : stored;
      if (isAgentOnly(roles: roles, isAdmin: user.isAdmin)) {
        return Routes.SALES_AGENT_HOME;
      }
    } catch (_) {}
    return Routes.MAIN;
  }
}

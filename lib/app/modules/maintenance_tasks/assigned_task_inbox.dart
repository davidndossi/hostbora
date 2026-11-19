import 'dart:convert';

import 'package:get/get.dart';

import '../../data/local/db/rent_staff_local_data_source.dart';
import '../../data/local/preference/preference_manager.dart';
import 'model/maintenance_task.dart';

/// Tasks an owner assigned to a staff member.
///
/// Stored in secure preferences so they survive the account-data wipe that
/// runs when that staff member signs in on this device. The task API often
/// returns those rows only to the owner, so the staff Tasks list merges this
/// inbox for the signed-in name and phone.
class AssignedTaskInbox {
  AssignedTaskInbox._();

  static PreferenceManager get _prefs => Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );

  static Future<void> save(MaintenanceTask task) async {
    if (task.id.isEmpty || !_hasAssignee(task.assignee)) return;
    try {
      final all = await _readAll();
      final phone = await _phoneForName(task.assignee);
      all[task.id] = {
        ...task.toArguments(),
        'assigneePhone': phone,
      };
      await _prefs.setString(
        PreferenceManager.keyAssignedTaskInbox,
        jsonEncode(all),
      );
    } catch (_) {}
  }

  /// Assignments whose staff name or phone matches the signed-in user.
  static Future<List<MaintenanceTask>> forCurrentUser() async {
    var name = '';
    var phone = '';
    try {
      final user = await _prefs.getUser();
      name = (user.fullName ?? '').trim();
      phone = (user.msisdn ?? '').trim();
    } catch (_) {}
    if (phone.isEmpty) {
      phone = (await _prefs.getString(
        PreferenceManager.keyUsername,
        defaultValue: '',
      ))
          .trim();
    }
    if (name.isEmpty) {
      name = (await _prefs.getString(
        PreferenceManager.keyFullName,
        defaultValue: '',
      ))
          .trim();
    }
    return forStaff(name: name, phone: phone);
  }

  static Future<List<MaintenanceTask>> forStaff({
    required String name,
    required String phone,
  }) async {
    final wantedName = name.trim().toLowerCase();
    final wantedPhone = _phoneKey(phone);
    if (wantedName.isEmpty && wantedPhone.isEmpty) return const [];
    final all = await _readAll();
    final out = <MaintenanceTask>[];
    for (final entry in all.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final assignee = (map['assignee'] ?? '').toString().trim().toLowerCase();
      final assigneePhone = _phoneKey((map['assigneePhone'] ?? '').toString());
      final nameHit = wantedName.isNotEmpty &&
          assignee.isNotEmpty &&
          (assignee == wantedName ||
              assignee.split(RegExp(r'\s+')).first == wantedName ||
              wantedName.split(RegExp(r'\s+')).first == assignee);
      final phoneHit = wantedPhone.isNotEmpty &&
          assigneePhone.isNotEmpty &&
          assigneePhone == wantedPhone;
      if (!nameHit && !phoneHit) continue;
      final task = MaintenanceTask.fromArguments(map);
      if (task.id.isEmpty || task.title.trim().isEmpty) continue;
      out.add(task);
    }
    return out;
  }

  static Future<String> _phoneForName(String name) async {
    if (!Get.isRegistered<RentStaffLocalDataSource>()) return '';
    try {
      final wanted = name.trim().toLowerCase();
      if (wanted.isEmpty) return '';
      final rows =
          await Get.find<RentStaffLocalDataSource>().getAllNewestFirst();
      for (final row in rows) {
        if (row.name.trim().toLowerCase() == wanted) {
          return row.phone.trim();
        }
      }
    } catch (_) {}
    return '';
  }

  static String _phoneKey(String raw) {
    final normalized = RentStaffLocalDataSource.normalizePhone(raw);
    if (normalized != null && normalized.isNotEmpty) return normalized;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) return digits.substring(digits.length - 9);
    return '';
  }

  static bool _hasAssignee(String value) {
    final s = value.trim().toLowerCase();
    return s.isNotEmpty &&
        s != 'unassigned' &&
        s != '—' &&
        s != '-' &&
        s != 'null';
  }

  static Future<Map<String, dynamic>> _readAll() async {
    final raw = await _prefs.getString(
      PreferenceManager.keyAssignedTaskInbox,
      defaultValue: '',
    );
    if (raw.trim().isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }
}

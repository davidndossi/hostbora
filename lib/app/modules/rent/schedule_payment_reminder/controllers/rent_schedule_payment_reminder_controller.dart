import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';

class RentSchedulePaymentReminderController extends BaseController {
  final tenantName = ''.obs;
  final propertyLine = ''.obs;
  final balanceTsh = 400000.obs;

  final reminderDate = Rxn<DateTime>();
  final reminderTime = Rxn<TimeOfDay>();

  final pushEnabled = true.obs;
  final whatsappEnabled = true.obs;
  final emailEnabled = false.obs;

  static final NumberFormat _currency =
      NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0);
  static final DateFormat _dateDisplay = DateFormat('MM/dd/yyyy');

  @override
  void onInit() {
    super.onInit();
    tenantName.value = Get.parameters['name'] ?? '';
    propertyLine.value = Get.parameters['property'] ?? '';
    final b = Get.parameters['balance'];
    if (b != null && b.isNotEmpty) {
      final parsed = int.tryParse(b);
      if (parsed != null) balanceTsh.value = parsed;
    }
  }

  String get displayTenantName =>
      tenantName.value.isEmpty ? 'Amara Okafor' : tenantName.value;

  /// Short property label for caps line (e.g. SEA VIEW APARTMENT).
  String get displayPropertyCaps {
    final p = propertyLine.value;
    if (p.isEmpty) return 'SEA VIEW APARTMENT';
    final i = p.indexOf(',');
    final short = i > 0 ? p.substring(0, i).trim() : p.trim();
    return short.toUpperCase();
  }

  /// Title case for message body (e.g. Sea View Apartment).
  String get displayPropertyTitle {
    final p = propertyLine.value;
    if (p.isEmpty) return 'Sea View Apartment';
    final i = p.indexOf(',');
    final short = i > 0 ? p.substring(0, i).trim() : p.trim();
    if (short.isEmpty) return 'Sea View Apartment';
    return short
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get formattedBalance => _currency.format(balanceTsh.value);

  String get dateFieldLabel {
    final d = reminderDate.value;
    return d == null ? 'mm/dd/yyyy' : _dateDisplay.format(d);
  }

  String get timeFieldLabel {
    final t = reminderTime.value;
    if (t == null) return '-- : -- --';
    final dt = DateTime(2020, 1, 1, t.hour, t.minute);
    return DateFormat('hh : mm a').format(dt);
  }

  String get previewDateToken {
    final d = reminderDate.value;
    return d == null ? '[Date]' : _dateDisplay.format(d);
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: reminderDate.value ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) reminderDate.value = picked;
  }

  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime.value ?? TimeOfDay.now(),
    );
    if (picked != null) reminderTime.value = picked;
  }

  void scheduleReminder() {
    showSuccessMessage('Reminder scheduled');
    Get.back();
  }
}

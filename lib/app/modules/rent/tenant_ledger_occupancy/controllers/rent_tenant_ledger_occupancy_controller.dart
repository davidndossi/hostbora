import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/model/send_sms_request.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../../routes/app_pages.dart';

enum LedgerPaymentStatus { fullyPaid, notPaid, partialPaid }

class RentTenantLedgerOccupancyController extends BaseController {
  RentTenantLedgerOccupancyController()
    : _tenantLocal = Get.find<TenantLocalDataSource>(),
      _incomeLocal = Get.find<IncomeLocalDataSource>(),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      ),
      _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  static const reminderTemplateKey = 'tenant_whatsapp_reminder_template';
  static const _overdueReminderStampPrefix = 'tenant_overdue_reminder_sent_';

  final TenantLocalDataSource _tenantLocal;
  final IncomeLocalDataSource _incomeLocal;
  final PreferenceManager _preferenceManager;
  final AppRepository _repository;

  final totalPaidTshRx = 0.obs;

  final tenantName = ''.obs;
  final tenantId = 0.obs;
  final propertyLine = ''.obs;
  final tenantRecord = Rxn<TenantRecord>();
  String _sourceWorkspace = 'rent';
  String _sourcePropertyRef = '';
  String _sourcePropertyTitle = '';
  String _sourcePropertyLoc = '';
  String _sourcePropertySuite = '';

  final customReminderController = TextEditingController();
  final amountPaidController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    tenantId.value = int.tryParse(Get.parameters['id'] ?? '') ?? 0;
    tenantName.value = Get.parameters['name'] ?? '';
    propertyLine.value = Get.parameters['property'] ?? '';
    _captureSourceContext();
  }

  void _captureSourceContext() {
    final args = Get.arguments;
    var ws = Get.parameters['ws']?.trim() ?? '';
    if (ws.isEmpty && args is Map) {
      ws = (args['ws'] ?? args['workspace'] ?? '').toString().trim();
    }
    _sourceWorkspace = ws.trim().toLowerCase() == 'bnb' ? 'bnb' : 'rent';
    _sourcePropertyRef = Get.parameters['propertyRef']?.trim() ?? '';
    _sourcePropertyTitle = Get.parameters['propertyTitle']?.trim() ?? '';
    _sourcePropertyLoc = Get.parameters['propertyLoc']?.trim() ?? '';
    _sourcePropertySuite = Get.parameters['propertySuite']?.trim() ?? '';
  }

  void goBackToTenancyInsights() {
    Get.offNamed(
      Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
      parameters: {
        'ws': _sourceWorkspace,
        if (_sourcePropertyRef.isNotEmpty) 'propertyRef': _sourcePropertyRef,
        if (_sourcePropertyTitle.isNotEmpty)
          'propertyTitle': _sourcePropertyTitle,
        if (_sourcePropertyLoc.isNotEmpty) 'propertyLoc': _sourcePropertyLoc,
        if (_sourcePropertySuite.isNotEmpty)
          'propertySuite': _sourcePropertySuite,
      },
      arguments: {'ws': _sourceWorkspace},
    );
  }

  @override
  void onReady() {
    super.onReady();
    _loadTenantAndCheckPeriod();
  }

  String get displayTenantName => tenantName.value.trim().isEmpty
      ? (tenantRecord.value?.tenantName.trim().isNotEmpty == true
            ? tenantRecord.value!.tenantName
            : 'Tenant')
      : tenantName.value;

  /// Full line for residence card / subtitles.
  String get displayPropertyFull {
    final p = propertyLine.value;
    if (p.trim().isNotEmpty) return p;
    final fallback = tenantRecord.value?.propertyLabel ?? '';
    return fallback.trim().isEmpty ? 'Property not set' : fallback;
  }

  /// Bold fragment in overview copy (text before first comma if present).
  String get propertyShortPhrase {
    final full = displayPropertyFull;
    final i = full.indexOf(',');
    if (i > 0) return full.substring(0, i).trim();
    return full;
  }

  static const residencyCity = 'N/A';

  int get currentRentAmountTsh =>
      tenantRecord.value?.rentAmountValue.round() ?? 0;

  String get rentFrequency =>
      tenantRecord.value?.rentFrequency.trim().isNotEmpty == true
      ? tenantRecord.value!.rentFrequency
      : 'Per Month';

  int get totalDueTsh {
    final rec = tenantRecord.value;
    if (rec == null) return 1200000;
    final range = _leaseRangeDays(rec);
    if (range == null) return currentRentAmountTsh;
    final units = _billingUnitsBetween(
      rec.leaseStartIso,
      rec.leaseEndIso,
      rec.rentFrequency,
    );
    return (units * rec.rentAmountValue).round();
  }

  int get totalPaidTsh => totalPaidTshRx.value;

  int get remainingBalanceTsh =>
      (totalDueTsh - totalPaidTsh).clamp(0, totalDueTsh);

  LedgerPaymentStatus get ledgerPaymentStatus {
    final due = totalDueTsh;
    final paid = totalPaidTsh;
    if (due <= 0 || paid >= due) return LedgerPaymentStatus.fullyPaid;
    if (paid <= 0) return LedgerPaymentStatus.notPaid;
    return LedgerPaymentStatus.partialPaid;
  }

  String get ledgerPaymentStatusHeadline {
    final isSw = Get.locale?.languageCode == 'sw';
    switch (ledgerPaymentStatus) {
      case LedgerPaymentStatus.fullyPaid:
        return isSw ? 'MALIPO YAMEKAMILIKA' : 'FULLY PAID';
      case LedgerPaymentStatus.notPaid:
        return isSw ? 'HAKUNA MALIPO' : 'NOT PAID';
      case LedgerPaymentStatus.partialPaid:
        return isSw ? 'MALIPO YA SEHEMU' : 'PARTIAL PAID';
    }
  }

  bool _incomeRowMatchesTenant(IncomeRecord r, TenantRecord t) {
    final incomeTenant = r.tenantName.trim().toLowerCase();
    final tenantName = t.tenantName.trim().toLowerCase();
    final tenantMatches = incomeTenant.isNotEmpty && incomeTenant == tenantName;
    if (incomeTenant.isNotEmpty && !tenantMatches) {
      return false;
    }

    final tenantRef = t.propertyRef.trim();
    final incomeRef = r.propertyRef.trim();
    final refMatches =
        tenantRef.isNotEmpty && incomeRef.isNotEmpty && tenantRef == incomeRef;
    if (tenantRef.isNotEmpty && incomeRef.isNotEmpty && !refMatches) {
      return false;
    }

    final unitMatches = _incomeRowMatchesTenantUnit(r, t);
    if (refMatches && (tenantMatches || unitMatches)) return true;
    if (tenantMatches && unitMatches) return true;
    if (tenantMatches && _incomeRowMatchesTenantProperty(r, t)) return true;
    return !tenantMatches &&
        unitMatches &&
        _incomeRowMatchesTenantProperty(r, t);
  }

  static bool _incomeRowMatchesTenantUnit(IncomeRecord r, TenantRecord t) {
    final tenantUnitId = t.apartmentUnitId.trim().toLowerCase();
    final tenantUnit = t.unitLabel.trim().toLowerCase();
    final incomeUnit = r.apartmentUnit.trim().toLowerCase();
    final notes = r.notes.trim().toLowerCase();
    if (tenantUnitId.isNotEmpty && incomeUnit == tenantUnitId) return true;
    if (tenantUnit.isNotEmpty && incomeUnit == tenantUnit) return true;
    if (tenantUnit.isNotEmpty && notes.contains(tenantUnit)) return true;
    return false;
  }

  static bool _incomeRowMatchesTenantProperty(IncomeRecord r, TenantRecord t) {
    final pl = t.propertyLabel.trim().toLowerCase();
    if (pl.isEmpty) return true;
    final ap = r.apartment.trim().toLowerCase();
    final unit = r.apartmentUnit.trim().toLowerCase();
    final notes = r.notes.trim().toLowerCase();
    final blob = '$ap $unit $notes'.trim();
    return blob.contains(pl) ||
        (ap.isNotEmpty && pl.contains(ap)) ||
        (unit.isNotEmpty && pl.contains(unit));
  }

  Future<void> _refreshPaidTotalFromIncome() async {
    final rec = tenantRecord.value;
    if (rec == null) {
      totalPaidTshRx.value = 0;
      return;
    }
    final rows = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    var sum = 0.0;
    for (final r in rows) {
      if (_incomeRowMatchesTenant(r, rec)) sum += r.amountValue;
    }
    totalPaidTshRx.value = sum.round();
  }

  int get currentStayMonths {
    final rec = tenantRecord.value;
    if (rec == null) return 4;
    final start = _parseIsoDate(rec.leaseStartIso);
    if (start == null) return 4;
    return _monthsBetween(start, DateTime.now()).clamp(0, 1200);
  }

  int get currentLeaseMonths {
    final rec = tenantRecord.value;
    if (rec == null) return 6;
    return _billingUnitsBetween(
      rec.leaseStartIso,
      rec.leaseEndIso,
      'Per Month',
    ).clamp(1, 1200);
  }

  String get tenancyRangeLabel {
    final rec = tenantRecord.value;
    if (rec == null) return 'May 2024 - Present';
    final start = _parseIsoDate(rec.leaseStartIso);
    final end = _parseIsoDate(rec.leaseEndIso);
    if (start == null || end == null) return 'May 2024 - Present';
    final fmt = DateFormat('MMM yyyy');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  String get contractFileName =>
      tenantRecord.value?.contractFileName.trim().isNotEmpty == true
      ? tenantRecord.value!.contractFileName
      : 'No signed contract uploaded';

  bool get isTenancyFinished {
    final rec = tenantRecord.value;
    if (rec == null) return false;
    final end = _parseIsoDate(rec.leaseEndIso);
    if (end == null) return false;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    return end.isBefore(day);
  }

  void openPaymentReminder() {
    Get.toNamed(
      Routes.RENT_SCHEDULE_PAYMENT_REMINDER,
      parameters: {
        'name': displayTenantName,
        'property': displayPropertyFull,
        'balance': '$remainingBalanceTsh',
        'phone': tenantRecord.value?.phoneNumber.trim() ?? '',
      },
    );
  }

  void openSendSmsShortcut() {
    final rec = tenantRecord.value;
    final phone = rec?.phoneNumber.trim() ?? '';
    if (phone.isEmpty) {
      showErrorMessage('Tenant phone number not available');
      return;
    }
    Get.toNamed(
      Routes.SEND_SMS,
      arguments: {
        'phones': [phone],
        'tenantIds': [rec?.id ?? tenantId.value],
        'propertyRef': rec?.propertyRef ?? '',
        'contextLabel': 'Message ${displayTenantName.trim()}',
        'workspace': _sourceWorkspace,
      },
    );
  }

  Future<void> _loadTenantAndCheckPeriod() async {
    final byId = tenantId.value > 0
        ? await _tenantLocal.findById(tenantId.value)
        : null;
    final byRoute = await _tenantLocal.findByNameAndProperty(
      tenantName: displayTenantName,
      propertyLabel: displayPropertyFull,
    );
    tenantRecord.value = byId ?? byRoute ?? await _tenantLocal.findLatest();
    await _refreshPaidTotalFromIncome();
    if (isTenancyFinished) {
      await _autoSendOverdueReminderIfNeeded();
      _showTenancyFinishedDialog();
    }
  }

  static Future<void> refreshIfRegistered() async {
    if (Get.isRegistered<RentTenantLedgerOccupancyController>()) {
      await Get.find<RentTenantLedgerOccupancyController>()
          ._loadTenantAndCheckPeriod();
    }
  }

  Future<void> _autoSendOverdueReminderIfNeeded() async {
    final rec = tenantRecord.value;
    if (rec == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final stampKey = '$_overdueReminderStampPrefix${rec.id}';
    final last = await _preferenceManager.getString(stampKey, defaultValue: '');
    if (last == today) return;
    final autoMessage =
        'Hello ${rec.tenantName}, your tenancy period has finished. Please renew and clear outstanding rent payment.';
    try {
      await _repository.sendSms(
        SendSmsRequest(phoneNumber: rec.phoneNumber, message: autoMessage),
      );
      await _preferenceManager.setString(stampKey, today);
    } catch (_) {
      // Keep silent; user still gets the action dialog.
    }
  }

  void _showTenancyFinishedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Tenancy period finished'),
        content: Text(
          'The tenancy period for $displayTenantName has finished. Choose an action below.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              onRenewClicked();
            },
            child: const Text('Renew'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onRemindClicked();
            },
            child: const Text('Remind'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void onRenewClicked() {
    Get.toNamed(
      Routes.RENT_TENANT_LEDGER_OCCUPANCY,
      parameters: {
        'name': displayTenantName,
        'property': displayPropertyFull,
        'ws': _sourceWorkspace,
        if (_sourcePropertyRef.isNotEmpty) 'propertyRef': _sourcePropertyRef,
        if (_sourcePropertyTitle.isNotEmpty)
          'propertyTitle': _sourcePropertyTitle,
        if (_sourcePropertyLoc.isNotEmpty) 'propertyLoc': _sourcePropertyLoc,
        if (_sourcePropertySuite.isNotEmpty)
          'propertySuite': _sourcePropertySuite,
      },
      arguments: {'ws': _sourceWorkspace},
    );
    Future.delayed(const Duration(milliseconds: 250), () {
      _showRenewDialog();
    });
  }

  void _showRenewDialog() {
    amountPaidController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('Amount tenant has paid'),
        content: TextField(
          controller: amountPaidController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: submitRenewalAmount,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> submitRenewalAmount() async {
    final rec = tenantRecord.value;
    if (rec == null) {
      showErrorMessage('Tenant record not found');
      return;
    }
    final raw = amountPaidController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      showErrorMessage('Enter a valid amount');
      return;
    }
    final rent = rec.rentAmountValue;
    if (rent <= 0) {
      showErrorMessage('Rent amount is not configured');
      return;
    }
    final periodsPaid = (amount / rent).floor();
    if (periodsPaid <= 0) {
      showErrorMessage('Amount is less than one billing period');
      return;
    }
    final currentLeaseEnd = _parseIsoDate(rec.leaseEndIso) ?? DateTime.now();
    final nowDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final base = currentLeaseEnd.isAfter(nowDay) ? currentLeaseEnd : nowDay;
    final nextEnd = _advanceByFrequency(base, rec.rentFrequency, periodsPaid);

    final updatedStartIso = rec.leaseStartIso;
    final updatedEndIso = DateFormat('yyyy-MM-dd').format(nextEnd);
    await _tenantLocal.updateLeaseTerms(
      id: rec.id,
      rentAmountValue: rec.rentAmountValue,
      leaseStartIso: updatedStartIso,
      leaseEndIso: updatedEndIso,
    );
    tenantRecord.value =
        await _tenantLocal.findByNameAndProperty(
          tenantName: rec.tenantName,
          propertyLabel: rec.propertyLabel,
        ) ??
        rec;

    await _sendUpdatedLeaseDocumentMessage(
      tenant: tenantRecord.value ?? rec,
      updatedStartIso: updatedStartIso,
      updatedEndIso: updatedEndIso,
    );

    if (Get.isDialogOpen ?? false) Get.back();
    showSuccessMessage(
      'Tenant period updated by $periodsPaid ${_periodLabel(rec.rentFrequency)}',
    );
  }

  Future<void> pickAndUploadSignedContract() async {
    final rec = tenantRecord.value;
    if (rec == null) {
      showErrorMessage('Tenant record not found');
      return;
    }
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    final file = picked?.files.single;
    final path = file?.path ?? '';
    if (path.isEmpty) return;
    await _tenantLocal.updateContractFile(
      id: rec.id,
      contractFilePath: path,
      contractFileName: file?.name ?? path.split('/').last,
    );
    tenantRecord.value = await _tenantLocal.findById(rec.id) ?? rec;
    showSuccessMessage('Signed contract uploaded');
  }

  Future<void> openSignedContract() async {
    final rec = tenantRecord.value;
    final path = rec?.contractFilePath.trim() ?? '';
    if (path.isEmpty) {
      showErrorMessage('No contract file uploaded yet');
      return;
    }
    await OpenFile.open(path);
  }

  void openEditLeaseTermsDialog() {
    final rec = tenantRecord.value;
    if (rec == null) {
      showErrorMessage('Tenant record not found');
      return;
    }
    final amountController = TextEditingController(
      text: rec.rentAmountValue.round().toString(),
    );
    final startController = TextEditingController(text: rec.leaseStartIso);
    final endController = TextEditingController(text: rec.leaseEndIso);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit lease terms'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Rent amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: 'Lease start (yyyy-MM-dd)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'Lease end (yyyy-MM-dd)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              amountController.dispose();
              startController.dispose();
              endController.dispose();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(
                amountController.text.trim().replaceAll(',', ''),
              );
              final start = _parseIsoDate(startController.text.trim());
              final end = _parseIsoDate(endController.text.trim());
              if (amount == null || amount <= 0) {
                showErrorMessage('Enter valid rent amount');
                return;
              }
              if (start == null || end == null || !end.isAfter(start)) {
                showErrorMessage('Enter valid lease dates');
                return;
              }
              await _tenantLocal.updateLeaseTerms(
                id: rec.id,
                rentAmountValue: amount,
                leaseStartIso: DateFormat('yyyy-MM-dd').format(start),
                leaseEndIso: DateFormat('yyyy-MM-dd').format(end),
              );
              tenantRecord.value = await _tenantLocal.findById(rec.id) ?? rec;
              amountController.dispose();
              startController.dispose();
              endController.dispose();
              Get.back();
              showSuccessMessage('Lease terms updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> onRemindClicked() async {
    final template = await _preferenceManager.getString(
      reminderTemplateKey,
      defaultValue: '',
    );
    if (template.trim().isNotEmpty) {
      await _sendReminder(_resolveTemplate(template.trim()));
      return;
    }
    Get.toNamed(
      Routes.RENT_TENANT_LEDGER_OCCUPANCY,
      parameters: {
        'name': displayTenantName,
        'property': displayPropertyFull,
        'ws': _sourceWorkspace,
        if (_sourcePropertyRef.isNotEmpty) 'propertyRef': _sourcePropertyRef,
        if (_sourcePropertyTitle.isNotEmpty)
          'propertyTitle': _sourcePropertyTitle,
        if (_sourcePropertyLoc.isNotEmpty) 'propertyLoc': _sourcePropertyLoc,
        if (_sourcePropertySuite.isNotEmpty)
          'propertySuite': _sourcePropertySuite,
      },
      arguments: {'ws': _sourceWorkspace},
    );
    Future.delayed(const Duration(milliseconds: 250), () {
      _showCustomReminderDialog();
    });
  }

  void _showCustomReminderDialog() {
    customReminderController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('Send reminder to tenant'),
        content: TextField(
          controller: customReminderController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Type your reminder message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final msg = customReminderController.text.trim();
              if (msg.isEmpty) {
                showErrorMessage('Please enter a reminder message');
                return;
              }
              await _sendReminder(msg);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReminder(String message) async {
    final phone = tenantRecord.value?.phoneNumber.trim() ?? '';
    if (phone.isEmpty) {
      showErrorMessage('Tenant phone number not available');
      return;
    }
    try {
      await _repository.sendSms(
        SendSmsRequest(phoneNumber: phone, message: message),
      );
      if (Get.isDialogOpen ?? false) Get.back();
      showSuccessMessage('Reminder sent to tenant');
    } catch (_) {
      showErrorMessage('Failed to send reminder');
    }
  }

  Future<void> _sendUpdatedLeaseDocumentMessage({
    required TenantRecord tenant,
    required String updatedStartIso,
    required String updatedEndIso,
  }) async {
    final phone = tenant.phoneNumber.trim();
    if (phone.isEmpty) return;
    final amountLabel = tenant.rentAmountValue.round().toString();
    final contractName = tenant.contractFileName.trim().isEmpty
        ? 'Updated lease terms'
        : tenant.contractFileName.trim();
    final message =
        '''
UPDATED LEASE DOCUMENT
Tenant: ${tenant.tenantName}
Property: ${tenant.propertyLabel}
Rent Amount: Tsh $amountLabel (${tenant.rentFrequency})
Lease Start: $updatedStartIso
Lease End: $updatedEndIso
Reference: $contractName
'''
            .trim();
    try {
      await _repository.sendSms(
        SendSmsRequest(phoneNumber: phone, message: message),
      );
    } catch (_) {
      // Silent failure: lease update must still succeed.
    }
  }

  String _resolveTemplate(String template) {
    final rec = tenantRecord.value;
    return template
        .replaceAll('{tenantName}', displayTenantName)
        .replaceAll('{property}', displayPropertyFull)
        .replaceAll('{rentAmount}', currentRentAmountTsh.toString())
        .replaceAll('{rentFrequency}', rentFrequency)
        .replaceAll('{leaseEnd}', rec?.leaseEndIso ?? '')
        .replaceAll('{remainingBalance}', remainingBalanceTsh.toString());
  }

  DateTime? _parseIsoDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  Duration? _leaseRangeDays(TenantRecord rec) {
    final start = _parseIsoDate(rec.leaseStartIso);
    final end = _parseIsoDate(rec.leaseEndIso);
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  int _monthsBetween(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  int _billingUnitsBetween(String startIso, String endIso, String frequency) {
    final start = _parseIsoDate(startIso);
    final end = _parseIsoDate(endIso);
    if (start == null || end == null || !end.isAfter(start)) return 1;
    final days = end.difference(start).inDays;
    switch (frequency.trim().toLowerCase()) {
      case 'per day':
        return days.clamp(1, 36500);
      case 'per week':
        return (days / 7).ceil().clamp(1, 5200);
      case 'per year':
        return ((end.year - start.year) +
                ((end.month > start.month ||
                        (end.month == start.month && end.day >= start.day))
                    ? 0
                    : -1))
            .clamp(1, 300);
      case 'per month':
      default:
        return _monthsBetween(start, end).clamp(1, 1200);
    }
  }

  DateTime _advanceByFrequency(DateTime base, String frequency, int units) {
    switch (frequency.trim().toLowerCase()) {
      case 'per day':
        return base.add(Duration(days: units));
      case 'per week':
        return base.add(Duration(days: units * 7));
      case 'per year':
        return DateTime(base.year + units, base.month, base.day);
      case 'per month':
      default:
        return DateTime(base.year, base.month + units, base.day);
    }
  }

  String _periodLabel(String frequency) {
    switch (frequency.trim().toLowerCase()) {
      case 'per day':
        return 'day(s)';
      case 'per week':
        return 'week(s)';
      case 'per year':
        return 'year(s)';
      case 'per month':
      default:
        return 'month(s)';
    }
  }

  @override
  void onClose() {
    customReminderController.dispose();
    amountPaidController.dispose();
    super.onClose();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/end_tenancy_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/thousand_separator.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/contract_update_service.dart';
import '../../../../data/local/service/tenant_lease_remote_sync.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../data/model/send_sms_request.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../../routes/app_pages.dart';
import '../../../all_tenants/controllers/all_tenants_controller.dart';
import '../../../listing_details/controllers/listing_details_controller.dart';
import '../../tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import '../utils/tenant_ledger_document_store.dart';
import '../utils/tenant_ledger_finance.dart';
import '../../../../data/service/analytics_service.dart';

enum LedgerPaymentStatus { fullyPaid, notPaid, partialPaid }

class LedgerPaymentRowVm {
  const LedgerPaymentRowVm({
    required this.incomeId,
    required this.amountTsh,
    required this.dateLabel,
    required this.category,
    required this.notes,
  });

  final int incomeId;
  final int amountTsh;
  final String dateLabel;
  final String category;
  final String notes;
}

class LedgerExpenseRowVm {
  const LedgerExpenseRowVm({
    required this.item,
    required this.amountTsh,
    required this.dateLabel,
    required this.category,
  });

  final String item;
  final int amountTsh;
  final String dateLabel;
  final String category;
}

class RentTenantLedgerOccupancyController extends BaseController {
  RentTenantLedgerOccupancyController()
    : _tenantLocal = Get.find<TenantLocalDataSource>(),
      _incomeLocal = Get.find<IncomeLocalDataSource>(),
      _expenseLocal = Get.find<ExpenseLocalDataSource>(),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      ),
      _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  static const reminderTemplateKey = 'tenant_whatsapp_reminder_template';
  static const _overdueReminderStampPrefix = 'tenant_overdue_reminder_sent_';

  final TenantLocalDataSource _tenantLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final PreferenceManager _preferenceManager;
  final AppRepository _repository;

  final totalPaidTshRx = 0.obs;
  final paymentHistory = <LedgerPaymentRowVm>[].obs;
  final expenseHistory = <LedgerExpenseRowVm>[].obs;
  final documentHistory = <TenantLedgerDocument>[].obs;

  late final TenantLedgerDocumentStore _documentStore = TenantLedgerDocumentStore(
    _preferenceManager,
  );

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
    tenantId.value = int.tryParse(Get.parameters['id'] ?? '') ??
        int.tryParse(Get.parameters['tenantId'] ?? '') ??
        0;
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
    // Prefer the real previous route (listing details, Tenancy Insights, etc.).
    // Always using [Get.offNamed] replaced the stack and left light-theme
    // screens underneath misaligned after returning from activity → ledger.
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
      return;
    }
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

  /// Rent/month or BnB rate label for the overview card.
  String get rateLabel {
    final amount = currentRentAmountTsh;
    final freq = rentFrequency.trim().toLowerCase();
    final currency = Get.find<CurrencyService>().formatBase(amount);
    if (freq == 'per night' || freq == 'per day') {
      return _isSw ? '$currency / usiku' : '$currency / night';
    }
    if (freq == 'per week') {
      return _isSw ? '$currency / wiki' : '$currency / week';
    }
    if (freq == 'per year') {
      return _isSw ? '$currency / mwaka' : '$currency / year';
    }
    if (freq == 'per stay') {
      return _isSw ? '$currency / kukaa' : '$currency / stay';
    }
    return _isSw ? '$currency / mwezi' : '$currency / month';
  }

  String get rateCaption {
    final freq = rentFrequency.trim().toLowerCase();
    if (freq == 'per night' || freq == 'per day') {
      return _isSw ? 'Kiwango cha usiku (BnB)' : 'BnB rate per night';
    }
    if (_sourceWorkspace == 'bnb') {
      return _isSw ? 'Kiwango cha BnB' : 'BnB rate';
    }
    return _isSw ? 'Kodi kwa mwezi' : 'Rent / month';
  }

  TenantLedgerDocument? get lastRentInvoice {
    final invoices = documentHistory
        .where((d) => d.type == TenantLedgerDocumentType.invoice)
        .toList();
    if (invoices.isEmpty) return null;
    invoices.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return invoices.first;
  }

  String lastInvoiceDateLabel(TenantLedgerDocument doc) {
    return DateFormat('d MMM yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(doc.createdAtMs),
    );
  }

  int get totalDueTsh {
    final rec = tenantRecord.value;
    if (rec == null) return 0;
    return TenantLedgerFinance.totalDueTsh(rec);
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

  Future<void> _refreshPaidTotalFromIncome() async {
    final rec = tenantRecord.value;
    if (rec == null) {
      totalPaidTshRx.value = 0;
      paymentHistory.clear();
      return;
    }
    final rentRows = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    final bnbRows = await _incomeLocal.getAllNewestFirst(workspaceType: 'bnb');
    final rows = [...rentRows, ...bnbRows];
    var sum = 0.0;
    final history = <LedgerPaymentRowVm>[];
    final dateFmt = DateFormat('d MMM yyyy');
    for (final r in rows) {
      if (!TenantLedgerFinance.incomeMatchesTenant(r, rec)) continue;
      sum += r.amountValue;
      final paid = r.paidLocalCalendarOrCreated();
      history.add(
        LedgerPaymentRowVm(
          incomeId: r.id,
          amountTsh: r.amountValue.round(),
          dateLabel: dateFmt.format(paid),
          category: r.category.trim().isEmpty ? 'Payment' : r.category.trim(),
          notes: r.notes.trim(),
        ),
      );
    }
    history.sort((a, b) => b.incomeId.compareTo(a.incomeId));
    totalPaidTshRx.value = sum.round();
    paymentHistory.assignAll(history);
    await _syncPaymentStatusToTenant();
  }

  Future<void> _refreshExpensesForTenant() async {
    final rec = tenantRecord.value;
    if (rec == null) {
      expenseHistory.clear();
      return;
    }
    final rent = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
    final bnb = await _expenseLocal.getAllNewestFirst(workspaceType: 'bnb');
    final rows = [...rent, ...bnb];
    final dateFmt = DateFormat('d MMM yyyy');
    final matched = <LedgerExpenseRowVm>[];
    for (final e in rows) {
      if (!_expenseMatchesTenant(e, rec)) continue;
      final item = e.notes.trim().isNotEmpty
          ? e.notes.trim()
          : (e.category.trim().isNotEmpty ? e.category.trim() : 'Expense');
      matched.add(
        LedgerExpenseRowVm(
          item: item,
          amountTsh: e.amountValue.round(),
          dateLabel: dateFmt.format(e.paidLocalCalendarOrCreated()),
          category: e.category.trim().isEmpty ? 'Other' : e.category.trim(),
        ),
      );
    }
    expenseHistory.assignAll(matched);
  }

  bool _expenseMatchesTenant(ExpenseRecord expense, TenantRecord tenant) {
    final tenantName = tenant.tenantName.trim().toLowerCase();
    final expenseTenantName = expense.tenantName.trim().toLowerCase();
    if (expenseTenantName.isNotEmpty && expenseTenantName == tenantName) {
      return true;
    }
    final pl = tenant.propertyLabel.trim().toLowerCase();
    if (pl.isEmpty) return false;
    final ap = expense.apartment.trim().toLowerCase();
    final unit = expense.apartmentUnit.trim().toLowerCase();
    final notes = expense.notes.trim().toLowerCase();
    final blob = '$ap $unit $notes'.trim();
    return blob.contains(pl) ||
        (ap.isNotEmpty && pl.contains(ap)) ||
        ap == pl;
  }

  Future<void> _syncPaymentStatusToTenant() async {
    final rec = tenantRecord.value;
    if (rec == null) return;
    final status = TenantLedgerFinance.paymentStatusValue(
      totalDueTsh,
      totalPaidTsh,
    );
    await _tenantLocal.updatePaymentStatus(id: rec.id, paymentStatus: status);
  }

  Future<void> _loadDocumentHistory() async {
    final rec = tenantRecord.value;
    if (rec == null) {
      documentHistory.clear();
      return;
    }
    documentHistory.assignAll(await _documentStore.listForTenant(rec.id));
  }

  int get currentStayMonths {
    final rec = tenantRecord.value;
    if (rec == null) return 0;
    return TenantLedgerFinance.currentStayMonths(rec, DateTime.now());
  }

  String get currentStayLabel {
    final rec = tenantRecord.value;
    if (rec == null) return _isSw ? '—' : '—';
    return TenantLedgerFinance.currentStayLabel(
      rec,
      DateTime.now(),
      isSw: _isSw,
    );
  }

  int get currentLeaseMonths {
    final rec = tenantRecord.value;
    if (rec == null) return 0;
    return TenantLedgerFinance.leaseDurationUnits(rec);
  }

  String get leaseDurationLabel {
    final rec = tenantRecord.value;
    if (rec == null) return '';
    return TenantLedgerFinance.leaseDurationLabel(rec, isSw: _isSw);
  }

  String get tenancyRangeLabel {
    final rec = tenantRecord.value;
    if (rec == null) return _isSw ? '—' : '—';
    return TenantLedgerFinance.tenancyRangeLabel(rec, isSw: _isSw);
  }

  bool get _isSw => Get.locale?.languageCode == 'sw';

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
    Get.toNamed(Routes.RENT_RECURRING_REMINDERS, parameters: {
      'tenantId': '${tenantRecord.value?.id ?? tenantId.value}',
      'name': displayTenantName,
      'propertyRef': tenantRecord.value?.propertyRef ?? '',
    });
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

  // ── Tenant details ─────────────────────────────────────────────────────
  // Read straight off the loaded record. Each returns an empty string when
  // absent rather than a placeholder, so the details card can omit the row
  // instead of printing a dash the host might read as a stored value.

  String get tenantPhone => tenantRecord.value?.phoneNumber.trim() ?? '';

  String get tenantEmail => tenantRecord.value?.email.trim() ?? '';

  bool get tenantHasWhatsapp =>
      tenantHasPhone && (tenantRecord.value?.isWhatsapp ?? false);

  bool get tenantHasPhone => tenantPhone.isNotEmpty;

  String get tenantGender => tenantRecord.value?.gender.trim() ?? '';

  String get tenantUnitLabel => tenantRecord.value?.unitLabel.trim() ?? '';

  /// Dials the tenant. Separate from [openSendSmsShortcut] because a host
  /// chasing rent usually calls first and only texts when that fails.
  Future<void> callTenant() async {
    final phone = tenantPhone;
    if (phone.isEmpty) {
      showErrorMessage(
        _isSw ? 'Hakuna namba ya simu' : 'Tenant phone number not available',
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(
        _isSw ? 'Simu haikufunguka.' : 'Could not start the call.',
      );
    }
  }

  /// Opens WhatsApp on the tenant's number.
  Future<void> whatsappTenant() async {
    final phone = tenantPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      showErrorMessage(
        _isSw ? 'Hakuna namba ya simu' : 'Tenant phone number not available',
      );
      return;
    }
    final uri = Uri.parse('https://wa.me/$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(
        _isSw ? 'WhatsApp haikufunguka.' : 'Could not open WhatsApp.',
      );
    }
  }

  /// Copies the tenant's phone number, for pasting into a bank or mobile
  /// money app where a tap-to-dial link is no use.
  Future<void> copyTenantPhone() async {
    final phone = tenantPhone;
    if (phone.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: phone));
    showSuccessMessage(_isSw ? 'Namba imenakiliwa' : 'Phone number copied');
  }

  Future<void> _loadTenantAndCheckPeriod() async {
    final byId = tenantId.value > 0
        ? await _tenantLocal.findById(tenantId.value)
        : null;
    final byRoute = await _tenantLocal.findByNameAndProperty(
      tenantName: displayTenantName,
      propertyLabel: displayPropertyFull,
    );
    tenantRecord.value = byId ?? byRoute;
    await _refreshPaidTotalFromIncome();
    await _refreshExpensesForTenant();
    await _loadDocumentHistory();
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
    _showRenewDialog();
  }

  void _showRenewDialog() {
    amountPaidController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('Amount tenant has paid'),
        content: TextField(
          controller: amountPaidController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsSeparatorInputFormatter()],
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
    await TenantLeaseRemoteSync.push(
      tenant: rec,
      leaseEndIso: updatedEndIso,
    );
    final currency = rec.rentCurrency.trim().isEmpty
        ? CurrencyService.defaultBaseCurrency
        : rec.rentCurrency.trim();
    final baseAmount = Get.find<CurrencyService>().toBaseAmount(
      inputAmount: amount,
      inputCurrency: currency,
    );
    await _incomeLocal.insert(
      tenantName: rec.tenantName,
      amountValue: baseAmount,
      datePaidIso: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      category: 'rent',
      workspaceType: _sourceWorkspace,
      notes: TenantLedgerFinance.appendTenantIdNote(
        'Tenancy renewal',
        rec.id,
      ),
      apartment: rec.propertyLabel,
      apartmentUnit: rec.unitLabel.trim().isNotEmpty
          ? rec.unitLabel.trim()
          : rec.apartmentUnitId.trim(),
      propertyRef: rec.propertyRef,
      currencyCode: currency,
      inputAmountValue: amount,
      tenantId: rec.id,
    );
    tenantRecord.value =
        await _tenantLocal.findByNameAndProperty(
          tenantName: rec.tenantName,
          propertyLabel: rec.propertyLabel,
        ) ??
        rec;
    await _refreshPaidTotalFromIncome();
    await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();

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
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'jpg',
        'jpeg',
        'png',
        'heic',
        'webp',
      ],
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
    final nameController = TextEditingController(text: rec.tenantName);
    final phoneController = TextEditingController(text: rec.phoneNumber);
    final emailController = TextEditingController(text: rec.email);
    final amountController = TextEditingController(
      text: NumberFormat('#,##0.##').format(rec.rentAmountValue),
    );
    final startController = TextEditingController(text: rec.leaseStartIso);
    final endController = TextEditingController(text: rec.leaseEndIso);

    void disposeFields() {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      amountController.dispose();
      startController.dispose();
      endController.dispose();
    }

    Get.dialog(
      AlertDialog(
        title: Text(_isSw ? 'Hariri mpangaji' : 'Edit tenant'),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _isSw ? 'Jina' : 'Name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: _isSw ? 'Simu' : 'Phone',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _isSw ? 'Barua pepe' : 'Email',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                labelText: _isSw ? 'Kiasi cha kodi' : 'Rent amount',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: startController,
              decoration: InputDecoration(
                labelText: _isSw
                    ? 'Mwanzo wa mkataba (yyyy-MM-dd)'
                    : 'Lease start (yyyy-MM-dd)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endController,
              decoration: InputDecoration(
                labelText: _isSw
                    ? 'Mwisho wa mkataba (yyyy-MM-dd)'
                    : 'Lease end (yyyy-MM-dd)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              disposeFields();
              Get.back();
            },
            child: Text(_isSw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final email = emailController.text.trim();
              final amount = double.tryParse(
                amountController.text.trim().replaceAll(',', ''),
              );
              final start = _parseIsoDate(startController.text.trim());
              final end = _parseIsoDate(endController.text.trim());
              if (name.isEmpty) {
                showErrorMessage(_isSw ? 'Weka jina' : 'Enter a name');
                return;
              }
              if (email.isNotEmpty && !email.contains('@')) {
                showErrorMessage(
                  _isSw ? 'Weka barua pepe sahihi' : 'Enter a valid email',
                );
                return;
              }
              if (amount == null || amount <= 0) {
                showErrorMessage(
                  _isSw ? 'Weka kiasi sahihi cha kodi' : 'Enter valid rent amount',
                );
                return;
              }
              if (start == null || end == null || !end.isAfter(start)) {
                showErrorMessage(
                  _isSw
                      ? 'Weka tarehe sahihi za mkataba'
                      : 'Enter valid lease dates',
                );
                return;
              }
              final endIso = DateFormat('yyyy-MM-dd').format(end);
              await _tenantLocal.updateTenantDetails(
                id: rec.id,
                tenantName: name,
                phoneNumber: phone,
                email: email,
                rentAmountValue: amount,
                leaseStartIso: DateFormat('yyyy-MM-dd').format(start),
                leaseEndIso: endIso,
              );
              tenantName.value = name;
              tenantRecord.value = await _tenantLocal.findById(rec.id) ?? rec;
              final saved = tenantRecord.value;
              if (saved != null) {
                await TenantLeaseRemoteSync.push(
                  tenant: saved,
                  leaseEndIso: saved.leaseEndIso,
                );
              }
              await _refreshPaidTotalFromIncome();
              unawaited(AllTenantsController.refreshIfRegistered());
              unawaited(ListingDetailsController.refreshIfRegistered());
              disposeFields();
              Get.back();
              showSuccessMessage(
                _isSw ? 'Mpangaji amesasishwa' : 'Tenant updated',
              );
            },
            child: Text(_isSw ? 'Hifadhi' : 'Save'),
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
    _showCustomReminderDialog();
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
      analytics?.logReminderSent(
        channel: 'sms',
        automated: false,
        reminderType: 'tenant_ledger',
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
    final amountLabel =
        Get.find<CurrencyService>().formatBase(tenant.rentAmountValue.round());
    final contractName = tenant.contractFileName.trim().isEmpty
        ? 'Updated lease terms'
        : tenant.contractFileName.trim();
    final message =
        '''
UPDATED LEASE DOCUMENT
Tenant: ${tenant.tenantName}
Property: ${tenant.propertyLabel}
Rent Amount: $amountLabel (${tenant.rentFrequency})
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

  String get actionRecommendationText {
    final balance = remainingBalanceTsh;
    final currency = Get.find<CurrencyService>().formatBase(balance);
    if (ledgerPaymentStatus == LedgerPaymentStatus.fullyPaid) {
      return _isSw
          ? 'Malipo yamekamilika kwa kipindi hiki cha mkataba.'
          : 'Payments are up to date for this lease period.';
    }
    if (ledgerPaymentStatus == LedgerPaymentStatus.partialPaid) {
      return _isSw
          ? 'Salio la $currency linabaki — tuma ankara au ukumbusho wa malipo.'
          : 'Balance of $currency remains — send an invoice or payment reminder.';
    }
    return _isSw
        ? 'Hakuna malipo yaliyorekodiwa — tengeneza ankara na ufuatilie malipo.'
        : 'No payments recorded yet — generate an invoice and follow up.';
  }

  void openRecordPayment() {
    final rec = tenantRecord.value;
    Get.toNamed(
      Routes.RECORD_PAYMENT,
      parameters: {
        'tenantId': '${rec?.id ?? tenantId.value}',
        if (displayTenantName.isNotEmpty) 'tenant': displayTenantName,
        if (displayPropertyFull.isNotEmpty) 'property': displayPropertyFull,
        if (rec?.propertyRef.trim().isNotEmpty == true)
          'propertyRef': rec!.propertyRef.trim(),
      },
      arguments: {
        'prefillIncome': {
          'tenantName': displayTenantName,
          if (rec?.unitLabel.trim().isNotEmpty == true)
            'unitSelectionKey': rec!.unitLabel.trim(),
        },
        'property': displayPropertyFull,
      },
    )?.then((_) => _loadTenantAndCheckPeriod());
  }

  Future<void> generateInvoice() async {
    final rec = tenantRecord.value;
    if (rec == null) {
      showErrorMessage('Tenant record not found');
      return;
    }
    final now = DateTime.now();
    final id = 'inv_${rec.id}_${now.millisecondsSinceEpoch}';
    final currency = Get.find<CurrencyService>();
    final lines = [
      'Tenant: ${rec.tenantName}',
      'Property: ${rec.propertyLabel}',
      if (rec.unitLabel.trim().isNotEmpty) 'Unit: ${rec.unitLabel}',
      'Lease: $tenancyRangeLabel',
      'Rent: ${currency.formatBase(currentRentAmountTsh)} ($rentFrequency)',
      'Total due: ${currency.formatBase(totalDueTsh)}',
      'Total paid: ${currency.formatBase(totalPaidTsh)}',
      'Balance due: ${currency.formatBase(remainingBalanceTsh)}',
      'Generated: ${DateFormat('d MMM yyyy, HH:mm').format(now)}',
    ];
    final path = await TenantLedgerDocumentStore.writePdf(
      fileName: '$id.pdf',
      title: _isSw ? 'ANKARA YA MALIPO' : 'RENT INVOICE',
      lines: lines,
    );
    final doc = TenantLedgerDocument(
      id: id,
      tenantId: rec.id,
      type: TenantLedgerDocumentType.invoice,
      title: _isSw ? 'Ankara ${DateFormat('d MMM yyyy').format(now)}' : 'Invoice ${DateFormat('d MMM yyyy').format(now)}',
      summary: _isSw
          ? 'Salio ${currency.formatBase(remainingBalanceTsh)}'
          : 'Balance ${currency.formatBase(remainingBalanceTsh)}',
      amountTsh: remainingBalanceTsh,
      filePath: path,
      createdAtMs: now.millisecondsSinceEpoch,
    );
    await _documentStore.save(doc);
    await _loadDocumentHistory();
    showSuccessMessage(_isSw ? 'Ankara imetengenezwa' : 'Invoice generated');
  }

  Future<void> generateReceipt({LedgerPaymentRowVm? payment}) async {
    final rec = tenantRecord.value;
    if (rec == null) {
      showErrorMessage('Tenant record not found');
      return;
    }
    final now = DateTime.now();
    final amount = payment?.amountTsh ?? totalPaidTsh;
    if (amount <= 0) {
      showErrorMessage(_isSw ? 'Hakuna malipo ya kuthibitisha' : 'No payment to receipt');
      return;
    }
    final id = 'rcp_${rec.id}_${now.millisecondsSinceEpoch}';
    final currency = Get.find<CurrencyService>();
    final lines = [
      'Tenant: ${rec.tenantName}',
      'Property: ${rec.propertyLabel}',
      if (rec.unitLabel.trim().isNotEmpty) 'Unit: ${rec.unitLabel}',
      'Amount received: ${currency.formatBase(amount)}',
      if (payment != null) 'Payment date: ${payment.dateLabel}',
      'Total paid to date: ${currency.formatBase(totalPaidTsh)}',
      'Remaining balance: ${currency.formatBase(remainingBalanceTsh)}',
      'Generated: ${DateFormat('d MMM yyyy, HH:mm').format(now)}',
    ];
    final path = await TenantLedgerDocumentStore.writePdf(
      fileName: '$id.pdf',
      title: _isSw ? 'RISITI YA MALIPO' : 'PAYMENT RECEIPT',
      lines: lines,
    );
    final doc = TenantLedgerDocument(
      id: id,
      tenantId: rec.id,
      type: TenantLedgerDocumentType.receipt,
      title: payment == null
          ? (_isSw ? 'Risiti ${DateFormat('d MMM yyyy').format(now)}' : 'Receipt ${DateFormat('d MMM yyyy').format(now)}')
          : (_isSw ? 'Risiti ${payment.dateLabel}' : 'Receipt ${payment.dateLabel}'),
      summary: currency.formatBase(amount),
      amountTsh: amount,
      filePath: path,
      createdAtMs: now.millisecondsSinceEpoch,
      incomeId: payment?.incomeId,
    );
    await _documentStore.save(doc);
    await _loadDocumentHistory();
    showSuccessMessage(_isSw ? 'Risiti imetengenezwa' : 'Receipt generated');
  }

  Future<void> openDocument(TenantLedgerDocument doc) async {
    final path = doc.filePath.trim();
    if (path.isEmpty) {
      showErrorMessage(_isSw ? 'Faili haipatikani' : 'File not available');
      return;
    }
    await OpenFile.open(path);
  }

  Future<void> shareDocument(
    TenantLedgerDocument doc, {
    required bool viaWhatsApp,
  }) async {
    final path = doc.filePath.trim();
    if (path.isEmpty) {
      showErrorMessage(_isSw ? 'Faili haipatikani' : 'File not available');
      return;
    }
    final text = '${doc.title}\n${doc.summary}';
    if (viaWhatsApp) {
      await _shareViaWhatsApp(text, filePath: path);
    } else {
      await _shareViaEmail(
        subject: doc.title,
        body: text,
        filePath: path,
      );
    }
  }

  Future<void> shareLatestInvoiceViaWhatsApp() async {
    final doc = documentHistory
        .where((d) => d.type == TenantLedgerDocumentType.invoice)
        .firstOrNull;
    if (doc == null) {
      await generateInvoice();
      final latest = documentHistory
          .where((d) => d.type == TenantLedgerDocumentType.invoice)
          .firstOrNull;
      if (latest != null) {
        await shareDocument(latest, viaWhatsApp: true);
      }
      return;
    }
    await shareDocument(doc, viaWhatsApp: true);
  }

  Future<void> shareLatestInvoiceViaEmail() async {
    final doc = documentHistory
        .where((d) => d.type == TenantLedgerDocumentType.invoice)
        .firstOrNull;
    if (doc == null) {
      await generateInvoice();
      final latest = documentHistory
          .where((d) => d.type == TenantLedgerDocumentType.invoice)
          .firstOrNull;
      if (latest != null) {
        await shareDocument(latest, viaWhatsApp: false);
      }
      return;
    }
    await shareDocument(doc, viaWhatsApp: false);
  }

  Future<void> _shareViaWhatsApp(String text, {String? filePath}) async {
    final rec = tenantRecord.value;
    final phone = rec?.phoneNumber.trim() ?? '';
    final encoded = Uri.encodeComponent(text);
    final uri = phone.isNotEmpty
        ? Uri.parse('https://wa.me/${_normalizePhone(phone)}?text=$encoded')
        : Uri.parse('https://wa.me/?text=$encoded');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (filePath != null && filePath.isNotEmpty) {
      await Share.shareXFiles([XFile(filePath)], text: text);
    } else {
      await Share.share(text);
    }
  }

  Future<void> _shareViaEmail({
    required String subject,
    required String body,
    String? filePath,
  }) async {
    final rec = tenantRecord.value;
    final email = rec?.email.trim() ?? '';
    final mailto = email.isNotEmpty
        ? Uri.parse(
            'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
          )
        : Uri.parse(
            'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
          );
    try {
      if (await canLaunchUrl(mailto)) {
        await launchUrl(mailto, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (filePath != null && filePath.isNotEmpty) {
      await Share.shareXFiles([XFile(filePath)], subject: subject, text: body);
    } else {
      await Share.share(body, subject: subject);
    }
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length >= 10) {
      return '255${digits.substring(1)}';
    }
    return digits;
  }

  /// Generates an updated contract PDF from tenant data (replaces any
  /// previously uploaded contract) and shares it via WhatsApp.
  Future<void> updateContractAndSendViaWhatsApp() async {
    final rec = tenantRecord.value;
    if (rec == null) {
      showErrorMessage(
        _isSw ? 'Rekodi ya mpangaji haipatikani' : 'Tenant record not found',
      );
      return;
    }
    try {
      showSuccessMessage(
        _isSw ? 'Inatengeneza mkataba…' : 'Generating contract…',
      );
      final path = await ContractUpdateService.generateUpdatedContract(
        tenant: rec,
        existingContractPath: rec.contractFilePath.trim(),
      );

      // Update the stored contract path.
      await _tenantLocal.updateContractFile(
        id: rec.id,
        contractFilePath: path,
        contractFileName: path.split('/').last,
      );

      // Reload tenant so the new path is reflected.
      tenantRecord.value = await _tenantLocal.findById(rec.id) ?? rec;
      await _loadDocumentHistory();

      final isSw = _isSw;
      final message = isSw
          ? '📄 Mkataba uliosasishwa umetumwa kwa ajili ya kukagua na kutia sahihi.'
          : '📄 Updated lease contract is attached for your review and signature.';
      await _shareViaWhatsApp(message, filePath: path);
    } catch (e) {
      showErrorMessage(
        _isSw ? 'Imeshindwa kutengeneza mkataba' : 'Failed to generate contract',
      );
    }
  }

  void onEndTenancy(BuildContext context) {
    final record = tenantRecord.value;
    if (record == null) return;
    final balanceTsh = remainingBalanceTsh;
    EndTenancySheet.show(
      tenant: record,
      outstandingBalanceTsh: balanceTsh,
      workspace: _sourceWorkspace,
      onCompleted: (result) async {
        showSuccessMessage(
          result.shareConsent
              ? 'Tenancy ended. Rating will be published in 30 days.'
              : 'Tenancy ended successfully.',
        );
        await _loadTenantAndCheckPeriod();
      },
    );
  }

  void onViewStory() {
    final record = tenantRecord.value;
    if (record == null) return;
    Get.toNamed(
      Routes.CLIENT_STORY,
      parameters: {
        'tenantId': record.id.toString(),
        'name': record.tenantName,
        'phone': record.phoneNumber,
      },
      arguments: {
        'tenantId': record.id,
        'name': record.tenantName,
        'phone': record.phoneNumber,
        'workspace': _sourceWorkspace,
      },
    );
  }

  @override
  void onClose() {
    customReminderController.dispose();
    amountPaidController.dispose();
    super.onClose();
  }
}

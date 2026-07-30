import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../db/expense_local_data_source.dart';
import '../db/income_local_data_source.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../../model/add_expense_request.dart';
import '../../model/record_payment_request.dart';
import '../service/currency_service.dart';
import '../service/offline_sync_worker_service.dart';

/// A stateful, multi-turn conversational flow for recording an expense or
/// income entry via the AI Manager chat.
///
/// Call [handleTurn] for every user message while a flow is active.
/// When [isComplete] becomes true the caller should discard this instance.
class AiFinanceFlow {
  AiFinanceFlow({
    required this.type,          // 'expense' | 'income'
    required this.isSw,
    required List<PropertyRecord> properties,
  }) : _properties = List.unmodifiable(properties);

  /// 'expense' or 'income'
  final String type;
  final bool isSw;
  final List<PropertyRecord> _properties;

  bool get isExpense => type == 'expense';

  // ── Collected parameters ───────────────────────────────────────────────
  PropertyRecord? _property;
  String? _unitName;     // apartment unit (optional)
  double? _amount;
  String? _currency;
  String? _category;
  String? _payer;        // tenant / guest / vendor name (optional)
  String? _notes;
  DateTime? _date;

  // ── State machine ──────────────────────────────────────────────────────
  _Step _step = _Step.askProperty;
  bool get isComplete => _step == _Step.done;

  // ── Expense categories ─────────────────────────────────────────────────
  static const _expenseCategories = [
    'Supplies',
    'Maintenance',
    'Utilities',
    'Salary',
    'Yearly tax',
    'Other',
  ];

  static const _incomeCategories = [
    'Lease',
    'Service Charge',
    'Maintenance',
    'Other',
  ];

  List<String> get _categories =>
      isExpense ? _expenseCategories : _incomeCategories;

  // ── Public entry point ─────────────────────────────────────────────────

  /// Returns the assistant's next reply for this [userInput].
  /// When all data has been collected and saved, returns a confirmation
  /// message and sets [isComplete] = true.
  Future<String> handleTurn(String userInput) async {
    final text = userInput.trim();
    switch (_step) {
      case _Step.askProperty:
        return _handleProperty(text);
      case _Step.askUnit:
        return _handleUnit(text);
      case _Step.askAmount:
        return _handleAmount(text);
      case _Step.askCategory:
        return _handleCategory(text);
      case _Step.askPayer:
        return _handlePayer(text);
      case _Step.askDate:
        return _handleDate(text);
      case _Step.askNotes:
        return _handleNotes(text);
      case _Step.confirm:
        return _handleConfirm(text);
      case _Step.done:
        return '';
    }
  }

  /// The opening prompt the assistant sends before the user types anything.
  String get openingPrompt {
    if (_properties.isEmpty) {
      _step = _Step.done;
      return isSw
          ? 'Samahani, hakuna mali iliyorekodiwa kwenye akaunti yako.'
          : 'Sorry, no properties are recorded on your account yet.';
    }
    if (_properties.length == 1) {
      _property = _properties.first;
      _step = _Step.askAmount;
      return _promptAmount();
    }
    return _promptProperty();
  }

  // ── Step handlers ──────────────────────────────────────────────────────

  String _handleProperty(String text) {
    final match = _fuzzyMatchProperty(text);
    if (match == null) {
      return isSw
          ? '❓ Sikupata mali inayolingana na "${_truncate(text)}". '
            'Jaribu jina mfupi zaidi, au andika nambari ya chaguo kutoka kwenye orodha:\n'
            '${_propertyList()}'
          : '❓ No property matched "${_truncate(text)}". '
            'Try a shorter name, or type the option number:\n'
            '${_propertyList()}';
    }
    _property = match;
    final hasUnits = _unitChoices().isNotEmpty;
    if (hasUnits) {
      _step = _Step.askUnit;
      return _promptUnit();
    }
    _step = _Step.askAmount;
    return _promptAmount();
  }

  String _handleUnit(String text) {
    final lower = text.toLowerCase().trim();
    if (_isSkip(lower)) {
      _unitName = null;
      _step     = _Step.askAmount;
      return _promptAmount();
    }
    final units = _unitChoices();
    // Try index
    final idx = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= units.length) {
      _unitName = units[idx - 1].$1;
      _step     = _Step.askAmount;
      return _promptAmount();
    }
    // Fuzzy name match
    for (final u in units) {
      if (u.$1.toLowerCase().contains(lower) ||
          lower.contains(u.$1.toLowerCase())) {
        _unitName = u.$1;
        _step     = _Step.askAmount;
        return _promptAmount();
      }
    }
    return isSw
        ? '❓ Sikupata unit "${_truncate(text)}". Andika nambari au jina:\n'
          '${_unitList()}'
        : '❓ No unit matched "${_truncate(text)}". Type the number or name:\n'
          '${_unitList()}';
  }

  String _handleAmount(String text) {
    final parsed = _parseAmount(text);
    if (parsed == null) {
      return isSw
          ? '❓ Kiasi sio sahihi. Tafadhali andika kiasi kama "50000" au "50,000 TZS".'
          : '❓ I could not read that amount. Please type something like "50000" or "50,000 TZS".';
    }
    _amount   = parsed.$1;
    _currency = parsed.$2;
    _step     = _Step.askCategory;
    return _promptCategory();
  }

  String _handleCategory(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= _categories.length) {
      _category = _categories[idx - 1];
    } else {
      for (final cat in _categories) {
        if (cat.toLowerCase().contains(lower) ||
            lower.contains(cat.toLowerCase())) {
          _category = cat;
          break;
        }
      }
    }
    if (_category == null) {
      return isSw
          ? '❓ Aina haijulikani. Chagua nambari:\n${_categoryList()}'
          : '❓ Category not recognised. Choose a number:\n${_categoryList()}';
    }
    _step = _Step.askPayer;
    return _promptPayer();
  }

  String _handlePayer(String text) {
    if (!_isSkip(text.toLowerCase())) {
      _payer = text.trim();
    }
    _step = _Step.askDate;
    return _promptDate();
  }

  String _handleDate(String text) {
    final lower = text.toLowerCase().trim();
    if (_isSkip(lower) || lower == 'today' || lower == 'leo') {
      _date = DateTime.now();
    } else {
      _date = _parseDate(text);
      if (_date == null) {
        return isSw
            ? '❓ Tarehe haikutambuliwa. Andika muundo kama "2026-06-17", '
              '"17/06/2026" au "leo".'
            : '❓ Date not recognised. Try "2026-06-17", "17/06/2026" or "today".';
      }
    }
    _step = _Step.askNotes;
    return _promptNotes();
  }

  String _handleNotes(String text) {
    if (!_isSkip(text.toLowerCase())) {
      _notes = text.trim();
    }
    _step = _Step.confirm;
    return _promptConfirm();
  }

  Future<String> _handleConfirm(String text) async {
    final lower = text.toLowerCase().trim();
    final yes   = lower.startsWith('y') ||
        lower.startsWith('ndio') ||
        lower.startsWith('ndiyo') ||
        lower == 'yes' ||
        lower == 'confirm' ||
        lower == 'save' ||
        lower == 'hifadhi';
    final no = lower.startsWith('n') ||
        lower == 'no'  ||
        lower == 'hapana' ||
        lower == 'ghairi' ||
        lower == 'cancel';

    if (no) {
      _step = _Step.done;
      return isSw
          ? '❌ Imeghairiwa. Hakuna kitu kilichohifadhiwa.'
          : '❌ Cancelled. Nothing was saved.';
    }
    if (!yes) {
      return isSw
          ? 'Tafadhali andika **ndio** ili kuhifadhi au **hapana** kughairi.'
          : 'Please type **yes** to save or **no** to cancel.';
    }

    // ── Save ──────────────────────────────────────────────────────────
    try {
      final saved = isExpense
          ? await _saveExpense()
          : await _saveIncome();
      _step = _Step.done;
      return saved;
    } catch (e) {
      _step = _Step.done;
      return isSw
          ? '❌ Imeshindwa kuhifadhi: $e'
          : '❌ Failed to save: $e';
    }
  }

  // ── Save helpers ───────────────────────────────────────────────────────

  Future<String> _saveExpense() async {
    final expLocal  = _get<ExpenseLocalDataSource>();
    final syncQueue = _get<OfflineSyncQueueLocalDataSource>();
    final syncWorker = _get<OfflineSyncWorkerService>();
    if (expLocal == null) throw StateError('ExpenseLocalDataSource not found');

    final isoDate  = _isoDate(_date ?? DateTime.now());
    final prop     = _property!;
    final amount   = _amount!;
    final currency = _currency ?? 'TZS';
    final category = _category ?? 'Other';
    final vendor   = _payer?.trim() ?? prop.propertyName;
    final notes    = _notes ?? '';

    final localId = await expLocal.insert(
      tenantName: vendor,
      amountValue: amount,
      datePaidIso: isoDate,
      category: category,
      workspaceType: prop.workspaceType.isEmpty ? 'rent' : prop.workspaceType,
      notes: notes,
      apartment: prop.propertyName,
      apartmentUnit: _unitName ?? '',
      currencyCode: currency,
      inputAmountValue: amount,
    );

    // Queue for backend sync
    if (syncQueue != null && syncWorker != null) {
      final request = AddExpenseRequest(
        amount: amount,
        category: category,
        expenseDate: isoDate,
        vendor: vendor,
        taxDeductible: true,
        description: notes,
      );
      await syncQueue.enqueue(
        entityType: 'expense',
        operation: 'create',
        payloadJson: jsonEncode({
          ...request.toJson(),
          'localExpenseId': localId,
        }),
        dedupeKey: 'expense:create:$localId',
      );
      syncWorker.runNow(maxItems: 10);
    }

    final fmt = NumberFormat('#,##0.##');
    return isSw
        ? '✅ Gharama imehifadhiwa:\n'
          '• Mali: ${prop.propertyName}${_unitName != null ? ' · $_unitName' : ''}\n'
          '• Kiasi: $currency ${fmt.format(amount)}\n'
          '• Aina: $category\n'
          '• Tarehe: $isoDate'
        : '✅ Expense saved:\n'
          '• Property: ${prop.propertyName}${_unitName != null ? ' · $_unitName' : ''}\n'
          '• Amount: $currency ${fmt.format(amount)}\n'
          '• Category: $category\n'
          '• Date: $isoDate';
  }

  Future<String> _saveIncome() async {
    final incLocal   = _get<IncomeLocalDataSource>();
    final syncQueue  = _get<OfflineSyncQueueLocalDataSource>();
    final syncWorker = _get<OfflineSyncWorkerService>();
    if (incLocal == null) throw StateError('IncomeLocalDataSource not found');

    final isoDate  = _isoDate(_date ?? DateTime.now());
    final prop     = _property!;
    final amount   = _amount!;
    final currency = _currency ?? 'TZS';
    final category = _category ?? 'Lease';
    final payer    = _payer?.trim() ?? '';
    final notes    = _notes ?? '';

    final localId = await incLocal.insert(
      tenantName: payer,
      amountValue: amount,
      datePaidIso: isoDate,
      category: category,
      workspaceType: prop.workspaceType.isEmpty ? 'rent' : prop.workspaceType,
      notes: notes,
      apartment: prop.propertyName,
      apartmentUnit: _unitName ?? '',
      propertyRef: prop.propertyRef,
      currencyCode: currency,
      inputAmountValue: amount,
    );

    // Queue for backend sync using the same shape RecordPaymentController uses
    if (syncQueue != null && syncWorker != null) {
      final request = RecordPaymentRequest(
        amount: amount,
        paymentMethod: 'Cash',
        paymentDate: isoDate,
        status: 'PAID',
      );
      await syncQueue.enqueue(
        entityType: 'payment',
        operation: 'create',
        payloadJson: jsonEncode({
          ...request.toJson(),
          'localIncomeId': localId,
          'category': category,
          'tenantName': payer,
          'notes': notes,
        }),
        dedupeKey: 'payment:create:$localId',
      );
      syncWorker.runNow(maxItems: 10);
    }

    final fmt = NumberFormat('#,##0.##');
    return isSw
        ? '✅ Mapato yamehifadhiwa:\n'
          '• Mali: ${prop.propertyName}${_unitName != null ? ' · $_unitName' : ''}\n'
          '• Kiasi: $currency ${fmt.format(amount)}\n'
          '• Aina: $category\n'
          '• Tarehe: $isoDate'
        : '✅ Income saved:\n'
          '• Property: ${prop.propertyName}${_unitName != null ? ' · $_unitName' : ''}\n'
          '• Amount: $currency ${fmt.format(amount)}\n'
          '• Category: $category\n'
          '• Date: $isoDate';
  }

  // ── Prompt builders ────────────────────────────────────────────────────

  String _promptProperty() {
    final header = isSw
        ? '🏠 ${isExpense ? "Gharama" : "Mapato"} kwa mali ipi?\n'
        : '🏠 Which property is this ${isExpense ? "expense" : "income"} for?\n';
    return header + _propertyList();
  }

  String _propertyList() {
    final buf = StringBuffer();
    for (int i = 0; i < _properties.length; i++) {
      buf.writeln('${i + 1}. ${_properties[i].propertyName}');
    }
    return buf.toString().trimRight();
  }

  String _promptUnit() {
    final skip   = isSw ? '"ruka" kukosa unit' : '"skip" for no unit';
    final header = isSw
        ? '🏢 Ni unit gani? (au andika $skip)\n'
        : '🏢 Which unit? (or type $skip)\n';
    return header + _unitList();
  }

  String _unitList() {
    final buf = StringBuffer();
    final units = _unitChoices();
    for (int i = 0; i < units.length; i++) {
      buf.writeln('${i + 1}. ${units[i].$1}');
    }
    return buf.toString().trimRight();
  }

  String _promptAmount() {
    final prop    = _property?.propertyName ?? '';
    final propCtx = prop.isNotEmpty ? ' ($prop)' : '';
    return isSw
        ? '💰 Kiasi ni ngapi$propCtx? (k.m. 50000 TZS)'
        : '💰 What is the amount$propCtx? (e.g. 50000 TZS)';
  }

  String _promptCategory() {
    final header = isSw
        ? '📂 Chagua aina:\n'
        : '📂 Choose a category:\n';
    return header + _categoryList();
  }

  String _categoryList() {
    final buf = StringBuffer();
    for (int i = 0; i < _categories.length; i++) {
      buf.writeln('${i + 1}. ${_categories[i]}');
    }
    return buf.toString().trimRight();
  }

  String _promptPayer() {
    final skip = isSw ? '"ruka"' : '"skip"';
    return isExpense
        ? (isSw
            ? '🏷️ Jina la muuzaji au mtoaji huduma? (au $skip)'
            : '🏷️ Vendor or service provider name? (or type $skip)')
        : (isSw
            ? '👤 Jina la mpangaji au mgeni? (au $skip)'
            : '👤 Tenant or guest name? (or type $skip)');
  }

  String _promptDate() {
    final today = _isoDate(DateTime.now());
    return isSw
        ? '📅 Tarehe ya ${isExpense ? "malipo" : "mapato"}? '
          '(k.m. $today, au andika "leo")'
        : '📅 Date of this ${isExpense ? "expense" : "payment"}? '
          '(e.g. $today, or type "today")';
  }

  String _promptNotes() {
    final skip = isSw ? '"ruka"' : '"skip"';
    return isSw
        ? '📝 Maelezo ya ziada? (au $skip)'
        : '📝 Any additional notes? (or type $skip)';
  }

  String _promptConfirm() {
    final prop = _property?.propertyName ?? '';
    final unit = _unitName != null ? ' · $_unitName' : '';
    final amt = Get.isRegistered<CurrencyService>()
        ? Get.find<CurrencyService>().formatBase((_amount ?? 0).round())
        : '${_currency ?? CurrencyService.defaultBaseCurrency} ${NumberFormat('#,##0.##').format(_amount ?? 0)}';
    final cat  = _category ?? '';
    final date = _isoDate(_date ?? DateTime.now());
    final who  = _payer?.isNotEmpty == true ? '\n• ${isExpense ? (isSw ? "Muuzaji" : "Vendor") : (isSw ? "Mlipaji" : "Payer")}: $_payer' : '';
    final n    = _notes?.isNotEmpty == true ? '\n• ${isSw ? "Maelezo" : "Notes"}: $_notes' : '';

    return isSw
        ? '📋 Thibitisha kuhifadhi:\n'
          '• Mali: $prop$unit\n'
          '• Kiasi: $amt\n'
          '• Aina: $cat\n'
          '• Tarehe: $date'
          '$who$n\n\n'
          'Andika **ndio** kuhifadhi au **hapana** kughairi.'
        : '📋 Confirm saving:\n'
          '• Property: $prop$unit\n'
          '• Amount: $amt\n'
          '• Category: $cat\n'
          '• Date: $date'
          '$who$n\n\n'
          'Type **yes** to save or **no** to cancel.';
  }

  // ── Utilities ──────────────────────────────────────────────────────────

  List<(String, String)> _unitChoices() {
    final prop = _property;
    if (prop == null) return [];
    try {
      final decoded = jsonDecode(prop.unitsJson);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => (
                (m['unitName'] ?? m['name'] ?? '').toString().trim(),
                (m['unitId'] ?? m['id'] ?? '').toString().trim(),
              ))
          .where((t) => t.$1.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  PropertyRecord? _fuzzyMatchProperty(String text) {
    final lower = text.toLowerCase().trim();
    // Numeric index
    final idx = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= _properties.length) {
      return _properties[idx - 1];
    }
    // Name contains
    for (final p in _properties) {
      final n = p.propertyName.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return p;
    }
    return null;
  }

  /// Parses "50000", "50,000", "50000 TZS", "TZS 50,000", "50k".
  (double, String)? _parseAmount(String text) {
    final t = text.trim();
    // Extract currency code
    final currRe = RegExp(r'\b([A-Z]{3})\b', caseSensitive: false);
    final currMatch = currRe.firstMatch(t);
    final currency =
        (currMatch?.group(1)?.toUpperCase()) ?? 'TZS';

    // Remove currency, commas, spaces
    final clean = t
        .replaceAll(RegExp(r'[A-Za-z]+'), '')
        .replaceAll(',', '')
        .trim();

    // Handle "50k" shorthand
    final kMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*k$', caseSensitive: false)
        .firstMatch(clean);
    if (kMatch != null) {
      final v = double.tryParse(kMatch.group(1)!);
      if (v != null) return (v * 1000, currency);
    }

    final v = double.tryParse(clean);
    if (v == null || v <= 0) return null;
    return (v, currency);
  }

  DateTime? _parseDate(String text) {
    final t = text.trim();
    // ISO: 2026-06-17
    final isoRe =
        RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(t);
    if (isoRe != null) {
      return DateTime(
        int.parse(isoRe.group(1)!),
        int.parse(isoRe.group(2)!),
        int.parse(isoRe.group(3)!),
      );
    }
    // d/m/yyyy or d.m.yyyy
    final dmyRe =
        RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})$').firstMatch(t);
    if (dmyRe != null) {
      return DateTime(
        int.parse(dmyRe.group(3)!),
        int.parse(dmyRe.group(2)!),
        int.parse(dmyRe.group(1)!),
      );
    }
    // Relative: "yesterday" / "jana"
    final lower = t.toLowerCase();
    if (lower == 'yesterday' || lower == 'jana') {
      return DateTime.now().subtract(const Duration(days: 1));
    }
    try {
      return DateTime.parse(t);
    } catch (_) {
      return null;
    }
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static bool _isSkip(String lower) =>
      lower == 'skip'  ||
      lower == 'ruka'  ||
      lower == 'none'  ||
      lower == 'hapana'||
      lower == '-'     ||
      lower == 'n/a'   ||
      lower.isEmpty;

  static String _truncate(String s, [int max = 40]) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  static T? _get<T extends Object>() {
    try {
      return Get.isRegistered<T>() ? Get.find<T>() : null;
    } catch (_) {
      return null;
    }
  }
}

enum _Step {
  askProperty,
  askUnit,
  askAmount,
  askCategory,
  askPayer,
  askDate,
  askNotes,
  confirm,
  done,
}

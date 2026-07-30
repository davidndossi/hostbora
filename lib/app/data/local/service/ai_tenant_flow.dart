import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../db/client_event_local_data_source.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import '../service/currency_service.dart';
import '../service/offline_sync_worker_service.dart';
import '../../../modules/add_listing/models/apartment_unit_draft.dart';

/// Conversational AI flow for:
///   • Adding a long-term rent tenant
///   • Ending an existing tenancy (tenant not continuing)
class AiTenantFlow {
  AiTenantFlow({
    required this.isSw,
    required List<PropertyRecord> properties,
  }) : _properties = List.unmodifiable(properties);

  final bool isSw;
  final List<PropertyRecord> _properties;

  _TenantAction _action = _TenantAction.unknown;
  _Step _step = _Step.askAction;

  bool get isComplete => _step == _Step.done;

  // ── Add-tenant fields ──────────────────────────────────────────────────
  PropertyRecord? _property;
  ApartmentUnitDraft? _unit;
  String _tenantName = '';
  String _phone = '';
  String _leaseStartIso = '';
  String _leaseEndIso = '';
  double _rentAmount = 0;
  final String _rentFrequency = 'Per Month';
  String get _currency => Get.isRegistered<CurrencyService>()
      ? Get.find<CurrencyService>().baseCurrency.value
      : CurrencyService.defaultBaseCurrency;

  // ── Remove-tenant fields ───────────────────────────────────────────────
  List<TenantRecord> _activeTenants = [];
  TenantRecord? _targetTenant;

  String get openingPrompt => _promptAction();

  Future<String> handleTurn(String userInput) async {
    final text = userInput.trim();
    switch (_step) {
      case _Step.askAction:        return _handleAction(text);
      case _Step.askProperty:      return _handleProperty(text);
      case _Step.askUnit:          return _handleUnit(text);
      case _Step.askName:          return _handleName(text);
      case _Step.askPhone:         return _handlePhone(text);
      case _Step.askLeaseStart:    return _handleLeaseStart(text);
      case _Step.askLeaseEnd:      return _handleLeaseEnd(text);
      case _Step.askRentAmount:    return _handleRentAmount(text);
      case _Step.askActiveTenant:  return _handleActiveTenant(text);
      case _Step.confirm:          return _handleConfirm(text);
      case _Step.done:             return '';
    }
  }

  // ── Step handlers ──────────────────────────────────────────────────────

  String _handleAction(String text) {
    final lower = text.toLowerCase();
    final idx   = int.tryParse(lower.trim());

    if (idx == 1 || _containsAny(lower, [
      'add', 'new tenant', 'mpangaji mpya', 'ongeza mpangaji',
    ])) {
      _action = _TenantAction.add;
      _step = _Step.askProperty;
      return _promptProperty(forAdd: true);
    }
    if (idx == 2 || _containsAny(lower, [
      'remove', 'end', 'leaving', 'vacating', 'ondoa', 'acha',
      'anaondoka', 'kumaliza', 'end tenancy',
    ])) {
      _action = _TenantAction.remove;
      _step = _Step.askProperty;
      return _promptProperty(forAdd: false);
    }
    return isSw
        ? '❓ Chagua:\n${_actionList()}'
        : '❓ Please choose:\n${_actionList()}';
  }

  Future<String> _handleProperty(String text) async {
    final match = _matchProperty(text);
    if (match == null) {
      return isSw
          ? '❓ Mali haikupatikana. Chagua:\n${_propertyList()}'
          : '❓ Property not found. Choose:\n${_propertyList()}';
    }
    _property = match;

    if (_action == _TenantAction.remove) {
      return await _loadActiveTenantsForProperty(match);
    }

    // Add flow: check if apartment with units
    final units = _parseUnits(match.unitsJson);
    if (units.isNotEmpty) {
      _step = _Step.askUnit;
      return _promptUnit(units);
    }
    _step = _Step.askName;
    return isSw
        ? '👤 Jina la mpangaji ni nani?'
        : '👤 What is the tenant\'s full name?';
  }

  String _handleUnit(String text) {
    final units = _parseUnits(_property?.unitsJson ?? '');
    final match = _matchUnit(text, units);
    if (match == null) {
      return isSw
          ? '❓ Unit haikupatikana. Chagua:\n${_unitList(units)}'
          : '❓ Unit not found. Choose:\n${_unitList(units)}';
    }
    _unit = match;
    _step = _Step.askName;
    return isSw
        ? '👤 Jina la mpangaji ni nani?'
        : '👤 What is the tenant\'s full name?';
  }

  String _handleName(String text) {
    if (text.isEmpty) {
      return isSw
          ? '❓ Jina haliwezi kuwa tupu.'
          : '❓ Name cannot be empty.';
    }
    _tenantName = text;
    _step = _Step.askPhone;
    return isSw
        ? '📞 Nambari ya simu ya mpangaji ni nani?'
        : '📞 What is the tenant\'s phone number?';
  }

  String _handlePhone(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length < 7) {
      return isSw
          ? '❓ Nambari ya simu sio sahihi.'
          : '❓ Phone number looks invalid.';
    }
    _phone = text.trim();
    _step = _Step.askLeaseStart;
    return isSw
        ? '📅 Tarehe ya kuanza kukaa? (leo / yyyy-mm-dd)'
        : '📅 When does the lease start? (today / yyyy-mm-dd)';
  }

  String _handleLeaseStart(String text) {
    final d = _parseDate(text);
    if (d == null) {
      return isSw
          ? '❓ Tarehe sio sahihi. Andika "leo" au yyyy-mm-dd.'
          : '❓ Date not recognised. Type "today" or yyyy-mm-dd.';
    }
    _leaseStartIso = _fmtDate(d);
    _step = _Step.askLeaseEnd;

    // Suggest lease end based on rent frequency
    final suggested = _rentFrequency == 'Per Year'
        ? d.add(const Duration(days: 365))
        : d.add(const Duration(days: 30));
    return isSw
        ? '📅 Tarehe ya mwisho wa kukaa? (k.m. ${_fmtDate(suggested)})'
        : '📅 Lease end date? (e.g. ${_fmtDate(suggested)})';
  }

  String _handleLeaseEnd(String text) {
    final d = _parseDate(text);
    if (d == null) {
      return isSw
          ? '❓ Tarehe sio sahihi. Andika "leo" au yyyy-mm-dd.'
          : '❓ Date not recognised. Type "today" or yyyy-mm-dd.';
    }
    _leaseEndIso = _fmtDate(d);
    _step = _Step.askRentAmount;
    return isSw
        ? '💰 Kodi ya kila mwezi ni kiasi gani?'
        : '💰 What is the monthly rent amount?';
  }

  String _handleRentAmount(String text) {
    final parsed = _parseAmount(text);
    if (parsed == null) {
      return isSw
          ? '❓ Kiasi sio sahihi. Andika kama "500000".'
          : '❓ Invalid amount. Type something like "500000".';
    }
    _rentAmount = parsed;
    _step = _Step.confirm;
    return _promptConfirmAdd();
  }

  Future<String> _handleActiveTenant(String text) async {
    final lower = text.toLowerCase().trim();
    final idx = int.tryParse(lower);
    TenantRecord? match;
    if (idx != null && idx >= 1 && idx <= _activeTenants.length) {
      match = _activeTenants[idx - 1];
    } else {
      for (final t in _activeTenants) {
        final n = t.tenantName.toLowerCase();
        if (n.contains(lower) || lower.contains(n)) {
          match = t;
          break;
        }
      }
    }
    if (match == null) {
      return isSw
          ? '❓ Mpangaji hajakupatikana. Chagua:\n${_tenantList()}'
          : '❓ Tenant not found. Choose:\n${_tenantList()}';
    }
    _targetTenant = match;
    _step = _Step.confirm;
    return _promptConfirmRemove(match);
  }

  Future<String> _handleConfirm(String text) async {
    final lower = text.toLowerCase().trim();
    final yes = lower.startsWith('y') ||
        lower == 'ndio' ||
        lower == 'ndiyo' ||
        lower == 'confirm' ||
        lower == 'save';
    final no = lower.startsWith('n') ||
        lower == 'hapana' ||
        lower == 'cancel' ||
        lower == 'ghairi';

    if (no) {
      _step = _Step.done;
      return isSw
          ? '❌ Imeghairiwa. Hakuna kilichohifadhiwa.'
          : '❌ Cancelled. Nothing was saved.';
    }
    if (!yes) {
      return isSw
          ? 'Andika **ndio** kuhifadhi au **hapana** kughairi.'
          : 'Type **yes** to save or **no** to cancel.';
    }

    try {
      if (_action == _TenantAction.add) {
        return await _saveTenant();
      } else {
        return await _endTenancy();
      }
    } catch (e) {
      _step = _Step.done;
      return isSw ? '❌ Imeshindwa: $e' : '❌ Failed: $e';
    }
  }

  // ── Save helpers ───────────────────────────────────────────────────────

  Future<String> _saveTenant() async {
    final tenantLocal = _findOrThrow<TenantLocalDataSource>();
    final syncQueue   = _find<OfflineSyncQueueLocalDataSource>();
    final syncWorker  = _find<OfflineSyncWorkerService>();
    final eventLocal  = _find<ClientEventLocalDataSource>();

    final prop       = _property!;
    final unitLabel  = _unit?.unitName.trim() ?? '';
    final unitId     = _unit?.unitId.trim() ?? '';
    final propLabel  = prop.propertyName.trim().isNotEmpty
        ? prop.propertyName.trim()
        : prop.propertyLocation.trim();

    final localId = await tenantLocal.insert(
      propertyLabel: propLabel,
      propertyRef: prop.propertyRef,
      apartmentUnitId: unitId,
      unitLabel: unitLabel,
      tenantName: _tenantName,
      gender: 'Prefer not to say',
      rentAmountValue: _rentAmount,
      rentFrequency: _rentFrequency,
      phoneNumber: _phone,
      email: '',
      isWhatsapp: false,
      leaseStartIso: _leaseStartIso,
      leaseEndIso: _leaseEndIso,
      rentCurrency: _currency,
    );

    unawaited(eventLocal?.insert(
      tenantLocalId: localId,
      phoneNumber: _phone,
      clientName: _tenantName,
      propertyRef: prop.propertyRef,
      propertyLabel: propLabel,
      unitLabel: unitLabel,
      workspace: 'rent',
      eventType: ClientEventType.tenantAdded,
      metadata: {
        'leaseStart': _leaseStartIso,
        'leaseEnd': _leaseEndIso,
        'rentAmount': _rentAmount,
        'rentFrequency': _rentFrequency,
      },
    ));

    final payload = {
      'name': _tenantName,
      'phone': _phone,
      'email': '',
      'propertyRef': prop.propertyRef,
      'unitId': unitId,
      'unitName': unitLabel,
      'leaseStart': _leaseStartIso,
      'leaseEnd': _leaseEndIso,
      'rentAmount': _rentAmount,
      'rentFrequency': _rentFrequency,
      'operationMode': 'rent',
      'rentCurrency': _currency,
      'localTenantId': localId,
    };
    if (syncQueue != null && syncWorker != null) {
      await syncQueue.enqueue(
        entityType: 'tenant',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'tenant:create:${prop.propertyRef}:$_tenantName',
      );
      syncWorker.runNow();
    }

    _step = _Step.done;
    return isSw
        ? '✅ Mpangaji amehifadhiwa:\n'
          '• Mali: $propLabel\n'
          '${unitLabel.isNotEmpty ? "• Unit: $unitLabel\n" : ""}'
          '• Jina: $_tenantName\n'
          '• Simu: $_phone\n'
          '• Kodi: ${_formatRent(_rentAmount)} / ${_freqSw(_rentFrequency)}\n'
          '• Mkataba: $_leaseStartIso → $_leaseEndIso'
        : '✅ Tenant saved:\n'
          '• Property: $propLabel\n'
          '${unitLabel.isNotEmpty ? "• Unit: $unitLabel\n" : ""}'
          '• Name: $_tenantName\n'
          '• Phone: $_phone\n'
          '• Rent: ${_formatRent(_rentAmount)} / $_rentFrequency\n'
          '• Lease: $_leaseStartIso → $_leaseEndIso';
  }

  Future<String> _endTenancy() async {
    final tenantLocal = _findOrThrow<TenantLocalDataSource>();
    final syncQueue   = _find<OfflineSyncQueueLocalDataSource>();
    final syncWorker  = _find<OfflineSyncWorkerService>();
    final eventLocal  = _find<ClientEventLocalDataSource>();

    final t = _targetTenant!;
    final now = DateTime.now();
    final endIso = _fmtDate(now);
    final endMs  = now.millisecondsSinceEpoch;

    await tenantLocal.endTenancy(
      id: t.id,
      endedAtIso: endIso,
      endedAtMs: endMs,
    );

    unawaited(eventLocal?.insert(
      tenantLocalId: t.id,
      phoneNumber: t.phoneNumber,
      clientName: t.tenantName,
      propertyRef: t.propertyRef,
      propertyLabel: t.propertyLabel,
      unitLabel: t.unitLabel,
      workspace: 'rent',
      eventType: ClientEventType.leaseEnded,
      metadata: {'endedAt': endIso},
    ));

    if (syncQueue != null && syncWorker != null) {
      await syncQueue.enqueue(
        entityType: 'tenant',
        operation: 'end_tenancy',
        payloadJson: jsonEncode({
          'localTenantId': t.id,
          'backendTenantId': t.backendTenantId,
          'propertyRef': t.propertyRef,
          'endedAtIso': endIso,
          'endedAtMs': endMs,
        }),
        dedupeKey: 'tenant:end:${t.id}',
      );
      syncWorker.runNow();
    }

    _step = _Step.done;
    return isSw
        ? '✅ Kukaa kwa "${t.tenantName}" kumekwisha:\n'
          '• Mali: ${t.propertyLabel}\n'
          '${t.unitLabel.isNotEmpty ? "• Unit: ${t.unitLabel}\n" : ""}'
          '• Tarehe ya kumaliza: $endIso\n\n'
          'Kumbuka kurekodi urejesho wowote wa amana ikiwa unahitajika.'
        : '✅ Tenancy for "${t.tenantName}" has been ended:\n'
          '• Property: ${t.propertyLabel}\n'
          '${t.unitLabel.isNotEmpty ? "• Unit: ${t.unitLabel}\n" : ""}'
          '• End date: $endIso\n\n'
          'Remember to record any deposit refund if applicable.';
  }

  // ── Loaders ────────────────────────────────────────────────────────────

  Future<String> _loadActiveTenantsForProperty(PropertyRecord prop) async {
    final tenantLocal = _find<TenantLocalDataSource>();
    if (tenantLocal == null) {
      _step = _Step.done;
      return isSw
          ? '❌ Huduma ya mpangaji haipatikani.'
          : '❌ Tenant service unavailable.';
    }
    final all = await tenantLocal.getActiveTenants();
    _activeTenants = all
        .where((t) =>
            t.propertyRef == prop.propertyRef ||
            t.propertyLabel
                .toLowerCase()
                .contains(prop.propertyName.toLowerCase()))
        .toList();

    if (_activeTenants.isEmpty) {
      _step = _Step.done;
      return isSw
          ? 'ℹ️ Hakuna wapangaji wanaokaa sasa katika "${prop.propertyName}".'
          : 'ℹ️ No active tenants found for "${prop.propertyName}".';
    }
    _step = _Step.askActiveTenant;
    return (isSw
        ? '👥 Chagua mpangaji anayeondoka:\n'
        : '👥 Which tenant is leaving?\n') +
        _tenantList();
  }

  // ── Prompt builders ────────────────────────────────────────────────────

  String _promptAction() => isSw
      ? '🏠 Ungependa kufanya nini?\n${_actionList()}'
      : '🏠 What would you like to do?\n${_actionList()}';

  String _actionList() => isSw
      ? '1. Ongeza mpangaji mpya\n2. Maliza kukaa kwa mpangaji'
      : '1. Add a new tenant\n2. End a tenant\'s tenancy';

  String _promptProperty({required bool forAdd}) {
    if (_properties.isEmpty) {
      _step = _Step.done;
      return isSw
          ? 'Hakuna mali iliyopatikana. Ongeza mali kwanza.'
          : 'No properties found. Please add a property first.';
    }
    return (isSw
        ? (forAdd ? '🏠 Mpangaji ataishi kwenye mali ipi?\n' : '🏠 Mpangaji anaondoka kwenye mali ipi?\n')
        : (forAdd ? '🏠 Which property is the tenant moving into?\n' : '🏠 Which property is the tenant leaving?\n')) +
        _propertyList();
  }

  String _propertyList() {
    final buf = StringBuffer();
    for (int i = 0; i < _properties.length; i++) {
      buf.writeln('${i + 1}. ${_properties[i].propertyName}');
    }
    return buf.toString().trimRight();
  }

  String _promptUnit(List<ApartmentUnitDraft> units) {
    return (isSw
        ? '🔑 Ni unit ipi?\n'
        : '🔑 Which unit?\n') +
        _unitList(units);
  }

  String _unitList(List<ApartmentUnitDraft> units) {
    final buf = StringBuffer();
    for (int i = 0; i < units.length; i++) {
      final u = units[i];
      final rent = u.unitRent.trim();
      buf.writeln(rent.isNotEmpty
          ? '${i + 1}. ${u.unitName} (${u.unitRent} ${u.unitRentCurrency})'
          : '${i + 1}. ${u.unitName}');
    }
    return buf.toString().trimRight();
  }

  String _promptConfirmAdd() {
    final propName = _property?.propertyName ?? '';
    final unitLine = _unit != null
        ? (isSw ? '• Unit: ${_unit!.unitName}\n' : '• Unit: ${_unit!.unitName}\n')
        : '';
    return isSw
        ? '📋 Thibitisha:\n'
          '• Mali: $propName\n'
          '$unitLine'
          '• Mpangaji: $_tenantName\n'
          '• Simu: $_phone\n'
          '• Kodi: ${_formatRent(_rentAmount)} / $_rentFrequency\n'
          '• Mkataba: $_leaseStartIso → $_leaseEndIso\n\n'
          'Andika **ndio** kuhifadhi au **hapana** kughairi.'
        : '📋 Confirm:\n'
          '• Property: $propName\n'
          '$unitLine'
          '• Tenant: $_tenantName\n'
          '• Phone: $_phone\n'
          '• Rent: ${_formatRent(_rentAmount)} / $_rentFrequency\n'
          '• Lease: $_leaseStartIso → $_leaseEndIso\n\n'
          'Type **yes** to save or **no** to cancel.';
  }

  String _promptConfirmRemove(TenantRecord t) {
    return isSw
        ? '⚠️ Thibitisha kumalizia kukaa:\n'
          '• Mpangaji: ${t.tenantName}\n'
          '• Mali: ${t.propertyLabel}\n'
          '${t.unitLabel.isNotEmpty ? "• Unit: ${t.unitLabel}\n" : ""}'
          '• Kodi ya mkataba: ${_formatRentForCurrency(t.rentAmountValue, t.rentCurrency)}\n'
          '• Ilianza: ${t.leaseStartIso}\n\n'
          'Tarehe ya leo itawekwa kama tarehe ya kumaliza.\n'
          'Andika **ndio** kuthibitisha au **hapana** kughairi.'
        : '⚠️ Confirm ending tenancy:\n'
          '• Tenant: ${t.tenantName}\n'
          '• Property: ${t.propertyLabel}\n'
          '${t.unitLabel.isNotEmpty ? "• Unit: ${t.unitLabel}\n" : ""}'
          '• Contract rent: ${_formatRentForCurrency(t.rentAmountValue, t.rentCurrency)}\n'
          '• Started: ${t.leaseStartIso}\n\n'
          'Today\'s date will be set as the end date.\n'
          'Type **yes** to confirm or **no** to cancel.';
  }

  String _tenantList() {
    final buf = StringBuffer();
    for (int i = 0; i < _activeTenants.length; i++) {
      final t = _activeTenants[i];
      final unit = t.unitLabel.trim().isNotEmpty ? ' (${t.unitLabel})' : '';
      buf.writeln('${i + 1}. ${t.tenantName}$unit');
    }
    return buf.toString().trimRight();
  }

  // ── Parsing helpers ────────────────────────────────────────────────────

  PropertyRecord? _matchProperty(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= _properties.length) {
      return _properties[idx - 1];
    }
    for (final p in _properties) {
      final n = p.propertyName.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return p;
    }
    return null;
  }

  ApartmentUnitDraft? _matchUnit(String text, List<ApartmentUnitDraft> units) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= units.length) {
      return units[idx - 1];
    }
    for (final u in units) {
      final n = u.unitName.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return u;
    }
    return null;
  }

  List<ApartmentUnitDraft> _parseUnits(String json) {
    if (json.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(m)))
          .where((u) => u.unitName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  DateTime? _parseDate(String text) {
    final lower = text.toLowerCase().trim();
    if (lower == 'today' || lower == 'leo') return DateTime.now();
    if (lower == 'tomorrow' || lower == 'kesho') {
      return DateTime.now().add(const Duration(days: 1));
    }
    // yyyy-mm-dd
    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(lower);
    if (ymd != null) {
      final y = int.parse(ymd.group(1)!);
      final m = int.parse(ymd.group(2)!);
      final d = int.parse(ymd.group(3)!);
      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) return DateTime(y, m, d);
    }
    // dd/mm/yyyy or dd-mm-yyyy
    final dmy = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$')
        .firstMatch(lower);
    if (dmy != null) {
      final d = int.parse(dmy.group(1)!);
      final m = int.parse(dmy.group(2)!);
      final y = int.parse(dmy.group(3)!);
      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) return DateTime(y, m, d);
    }
    return null;
  }

  double? _parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[A-Za-z\s]'), '').replaceAll(',', '');
    final kMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*k$', caseSensitive: false)
        .firstMatch(text.trim());
    if (kMatch != null) {
      final v = double.tryParse(kMatch.group(1)!);
      if (v != null && v > 0) return v * 1000;
    }
    final v = double.tryParse(clean);
    return (v != null && v > 0) ? v : null;
  }

  String _formatRent(double amount) {
    if (Get.isRegistered<CurrencyService>()) {
      return Get.find<CurrencyService>().formatBase(amount.round());
    }
    return '${_fmt(amount)} $_currency';
  }

  static String _formatRentForCurrency(double amount, String currencyCode) {
    final code = currencyCode.trim().isEmpty
        ? CurrencyService.defaultBaseCurrency
        : currencyCode.trim().toUpperCase();
    return '${CurrencyService.symbolFor(code)}${_fmt(amount)}';
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(0);
  }

  static String _freqSw(String freq) {
    if (freq == 'Per Month') return 'mwezi';
    if (freq == 'Per Year')  return 'mwaka';
    return 'siku';
  }

  static bool _containsAny(String text, List<String> tokens) =>
      tokens.any(text.contains);

  T _findOrThrow<T extends Object>() {
    if (!Get.isRegistered<T>()) throw StateError('$T is not registered');
    return Get.find<T>();
  }

  T? _find<T extends Object>() {
    try {
      return Get.isRegistered<T>() ? Get.find<T>() : null;
    } catch (_) {
      return null;
    }
  }
}

enum _TenantAction { unknown, add, remove }

enum _Step {
  askAction,
  askProperty,
  askUnit,
  askName,
  askPhone,
  askLeaseStart,
  askLeaseEnd,
  askRentAmount,
  askActiveTenant,
  confirm,
  done,
}

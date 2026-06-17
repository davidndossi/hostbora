import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/bnb_stay_billing.dart';
import '../db/client_event_local_data_source.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import '../service/offline_sync_worker_service.dart';
import '../../../modules/add_listing/models/apartment_unit_draft.dart';

/// Conversational AI flow for BnB guest management:
///   • Check-in  — record a new guest arrival
///   • Check-out — mark an active guest as checked out
class AiBnbGuestFlow {
  AiBnbGuestFlow({
    required this.isSw,
    required List<PropertyRecord> bnbProperties,
  }) : _properties = List.unmodifiable(bnbProperties);

  final bool isSw;
  final List<PropertyRecord> _properties;

  _GuestAction _action = _GuestAction.unknown;
  _Step _step = _Step.askAction;

  bool get isComplete => _step == _Step.done;

  // ── Check-in fields ────────────────────────────────────────────────────
  PropertyRecord? _property;
  ApartmentUnitDraft? _unit;
  String _guestName = '';
  String _phone = '';
  String _checkInIso = '';
  String _checkOutIso = '';
  double _nightlyRate = 0;

  // ── Check-out fields ───────────────────────────────────────────────────
  List<TenantRecord> _activeGuests = [];
  TenantRecord? _targetGuest;
  String _actualCheckOutIso = '';

  String get openingPrompt => _promptAction();

  Future<String> handleTurn(String userInput) async {
    final text = userInput.trim();
    switch (_step) {
      case _Step.askAction:          return _handleAction(text);
      case _Step.askProperty:        return await _stepProperty(text);
      case _Step.askUnit:            return _handleUnit(text);
      case _Step.askGuestName:       return _handleGuestName(text);
      case _Step.askPhone:           return _handlePhone(text);
      case _Step.askCheckIn:         return _handleCheckIn(text);
      case _Step.askCheckOut:        return _handleCheckOut(text);
      case _Step.askNightlyRate:     return _handleNightlyRate(text);
      case _Step.askActiveGuest:     return await _handleActiveGuest(text);
      case _Step.askActualCheckOut:  return _handleActualCheckOut(text);
      case _Step.confirm:            return await _handleConfirm(text);
      case _Step.done:               return '';
    }
  }

  // ── Step handlers ──────────────────────────────────────────────────────

  String _handleAction(String text) {
    final lower = text.toLowerCase();
    final idx   = int.tryParse(lower.trim());

    if (idx == 1 || _containsAny(lower, [
      'check in', 'check-in', 'checkin', 'new guest', 'mgeni mpya',
      'kuweka mgeni', 'kufika', 'arrival', 'book',
    ])) {
      _action = _GuestAction.checkIn;
      _step = _Step.askProperty;
      return _promptPropertyList(
        isSw ? 'Mgeni anakaa kwenye mali ipi?' : 'Which property is the guest checking into?',
      );
    }
    if (idx == 2 || _containsAny(lower, [
      'check out', 'check-out', 'checkout', 'leaving', 'departure',
      'mgeni anaondoka', 'kutoka', 'ondoka',
    ])) {
      _action = _GuestAction.checkOut;
      _step = _Step.askProperty;
      return _promptPropertyList(
        isSw ? 'Mgeni anaondoka kwenye mali ipi?' : 'Which property is the guest checking out of?',
      );
    }
    return isSw
        ? '❓ Chagua:\n${_actionList()}'
        : '❓ Please choose:\n${_actionList()}';
  }

  Future<String> _stepProperty(String text) async {
    final match = _matchProperty(text);
    if (match == null) {
      return isSw
          ? '❓ Mali haikupatikana. Chagua:\n${_propertyList()}'
          : '❓ Property not found. Choose:\n${_propertyList()}';
    }
    _property = match;

    if (_action == _GuestAction.checkOut) {
      return await _loadActiveGuests(match);
    }

    // Check-in — ask unit if apartment
    final units = _parseUnits(match.unitsJson);
    if (units.isNotEmpty) {
      _step = _Step.askUnit;
      return _promptUnits(units);
    }
    _step = _Step.askGuestName;
    return _promptGuestName();
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
    _step = _Step.askGuestName;
    return _promptGuestName();
  }

  String _handleGuestName(String text) {
    if (text.isEmpty) {
      return isSw ? '❓ Jina haliwezi kuwa tupu.' : '❓ Name cannot be empty.';
    }
    _guestName = text;
    _step = _Step.askPhone;
    return isSw
        ? '📞 Nambari ya simu ya mgeni? (au andika "skip" kuruka)'
        : '📞 Guest\'s phone number? (or type "skip" to skip)';
  }

  String _handlePhone(String text) {
    final lower = text.toLowerCase().trim();
    if (lower == 'skip' || lower == 'ruka') {
      _phone = '';
    } else {
      _phone = text.trim();
    }
    _step = _Step.askCheckIn;
    return isSw
        ? '📅 Tarehe ya kuwasili? (leo / yyyy-mm-dd)'
        : '📅 Check-in date? (today / yyyy-mm-dd)';
  }

  String _handleCheckIn(String text) {
    final d = _parseDate(text);
    if (d == null) {
      return isSw
          ? '❓ Tarehe sio sahihi. Andika "leo" au yyyy-mm-dd.'
          : '❓ Date not recognised. Type "today" or yyyy-mm-dd.';
    }
    _checkInIso = _fmt(d);
    // Default check-out: 1 night later
    final nextDay = d.add(const Duration(days: 1));
    _step = _Step.askCheckOut;
    return isSw
        ? '📅 Tarehe ya kuondoka? (k.m. ${_fmt(nextDay)})'
        : '📅 Check-out date? (e.g. ${_fmt(nextDay)})';
  }

  String _handleCheckOut(String text) {
    final d = _parseDate(text);
    if (d == null) {
      return isSw
          ? '❓ Tarehe sio sahihi. Andika "kesho" au yyyy-mm-dd.'
          : '❓ Date not recognised. Type "tomorrow" or yyyy-mm-dd.';
    }
    final checkIn = _parseDate(_checkInIso);
    if (checkIn != null && !d.isAfter(checkIn)) {
      return isSw
          ? '❓ Tarehe ya kuondoka lazima iwe baada ya tarehe ya kuwasili.'
          : '❓ Check-out must be after check-in date.';
    }
    _checkOutIso = _fmt(d);
    _step = _Step.askNightlyRate;

    // Pre-fill from unit if available
    final unitRate = _unit?.unitRent.trim() ?? '';
    if (unitRate.isNotEmpty) {
      final n = double.tryParse(unitRate.replaceAll(',', ''));
      if (n != null && n > 0) {
        _nightlyRate = n;
        return isSw
            ? '💰 Bei ya kila usiku: ${_fmtNum(_nightlyRate)} ${_unit!.unitRentCurrency}. '
              'Thibitisha au andika kiasi kipya.'
            : '💰 Nightly rate: ${_fmtNum(_nightlyRate)} ${_unit!.unitRentCurrency}. '
              'Confirm or enter a different amount.';
      }
    }
    return isSw
        ? '💰 Bei ya kila usiku ni kiasi gani?'
        : '💰 What is the nightly rate?';
  }

  String _handleNightlyRate(String text) {
    final lower = text.toLowerCase().trim();
    // If user just confirmed the pre-filled amount
    if ((lower == 'ok' || lower == 'ndio' || lower == 'confirm' ||
        lower == 'yes') && _nightlyRate > 0) {
      _step = _Step.confirm;
      return _promptConfirmCheckIn();
    }
    final parsed = _parseAmount(text);
    if (parsed == null) {
      return isSw
          ? '❓ Kiasi sio sahihi. Andika kama "50000".'
          : '❓ Invalid amount. Type something like "50000".';
    }
    _nightlyRate = parsed;
    _step = _Step.confirm;
    return _promptConfirmCheckIn();
  }

  Future<String> _handleActiveGuest(String text) async {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    TenantRecord? match;
    if (idx != null && idx >= 1 && idx <= _activeGuests.length) {
      match = _activeGuests[idx - 1];
    } else {
      for (final g in _activeGuests) {
        final n = g.tenantName.toLowerCase();
        if (n.contains(lower) || lower.contains(n)) {
          match = g;
          break;
        }
      }
    }
    if (match == null) {
      return isSw
          ? '❓ Mgeni hajakupatikana. Chagua:\n${_guestList()}'
          : '❓ Guest not found. Choose:\n${_guestList()}';
    }
    _targetGuest = match;

    // Ask for actual check-out date (default today)
    final today = _fmt(DateTime.now());
    _actualCheckOutIso = today;
    _step = _Step.askActualCheckOut;
    return isSw
        ? '📅 Tarehe ya kweli ya kuondoka kwa "${match.tenantName}"?\n'
          'Bonyeza Enter au andika tarehe (k.m. $today)'
        : '📅 Actual check-out date for "${match.tenantName}"?\n'
          'Press Enter or type a date (e.g. $today)';
  }

  String _handleActualCheckOut(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.isEmpty || lower == 'today' || lower == 'leo' ||
        lower == 'enter' || lower == 'ok' || lower == 'yes' || lower == 'ndio') {
      _actualCheckOutIso = _fmt(DateTime.now());
    } else {
      final d = _parseDate(text);
      if (d == null) {
        return isSw
            ? '❓ Tarehe sio sahihi. Andika "leo" au yyyy-mm-dd.'
            : '❓ Date not recognised. Type "today" or yyyy-mm-dd.';
      }
      _actualCheckOutIso = _fmt(d);
    }
    _step = _Step.confirm;
    return _promptConfirmCheckOut();
  }

  Future<String> _handleConfirm(String text) async {
    final lower = text.toLowerCase().trim();
    final yes = lower.startsWith('y') || lower == 'ndio' || lower == 'ndiyo' ||
        lower == 'confirm' || lower == 'save';
    final no = lower.startsWith('n') || lower == 'hapana' ||
        lower == 'cancel' || lower == 'ghairi';

    if (no) {
      _step = _Step.done;
      return isSw ? '❌ Imeghairiwa.' : '❌ Cancelled.';
    }
    if (!yes) {
      return isSw
          ? 'Andika **ndio** kuhifadhi au **hapana** kughairi.'
          : 'Type **yes** to save or **no** to cancel.';
    }

    try {
      if (_action == _GuestAction.checkIn) {
        return await _saveCheckIn();
      } else {
        return await _saveCheckOut();
      }
    } catch (e) {
      _step = _Step.done;
      return isSw ? '❌ Imeshindwa: $e' : '❌ Failed: $e';
    }
  }

  // ── Save operations ────────────────────────────────────────────────────

  Future<String> _saveCheckIn() async {
    final tenantLocal = _findOrThrow<TenantLocalDataSource>();
    final syncQueue   = _find<OfflineSyncQueueLocalDataSource>();
    final syncWorker  = _find<OfflineSyncWorkerService>();
    final eventLocal  = _find<ClientEventLocalDataSource>();

    final prop      = _property!;
    final unitLabel = _unit?.unitName.trim() ?? '';
    final unitId    = _unit?.unitId.trim() ?? '';
    final currency  = _unit?.unitRentCurrency ?? 'TZS';
    final propLabel = prop.propertyName.trim().isNotEmpty
        ? prop.propertyName.trim()
        : prop.propertyLocation.trim();

    final checkIn  = _parseDate(_checkInIso)!;
    final checkOut = _parseDate(_checkOutIso)!;
    final stayTotal = BnbStayBilling.totalForStay(
      ratePerPeriod: _nightlyRate,
      frequency: 'Per Night',
      checkIn: checkIn,
      checkOut: checkOut,
    );

    final localId = await tenantLocal.insert(
      propertyLabel: propLabel,
      propertyRef: prop.propertyRef,
      apartmentUnitId: unitId,
      unitLabel: unitLabel,
      tenantName: _guestName,
      gender: 'Prefer not to say',
      rentAmountValue: stayTotal > 0 ? stayTotal : _nightlyRate,
      rentFrequency: 'Per Stay',
      phoneNumber: _phone,
      email: '',
      isWhatsapp: false,
      leaseStartIso: _checkInIso,
      leaseEndIso: _checkOutIso,
      rentCurrency: currency,
    );

    unawaited(eventLocal?.insert(
      tenantLocalId: localId,
      phoneNumber: _phone,
      clientName: _guestName,
      propertyRef: prop.propertyRef,
      propertyLabel: propLabel,
      unitLabel: unitLabel,
      workspace: 'bnb',
      eventType: ClientEventType.checkIn,
      metadata: {
        'checkIn': _checkInIso,
        'checkOut': _checkOutIso,
        'nightlyRate': _nightlyRate,
        'stayTotal': stayTotal,
      },
    ));

    final payload = {
      'name': _guestName,
      'phone': _phone,
      'email': '',
      'propertyRef': prop.propertyRef,
      'unitId': unitId,
      'unitName': unitLabel,
      'leaseStart': _checkInIso,
      'leaseEnd': _checkOutIso,
      'rentAmount': stayTotal > 0 ? stayTotal : _nightlyRate,
      'rentFrequency': 'Per Stay',
      'operationMode': 'bnb',
      'rentCurrency': currency,
      'localTenantId': localId,
    };
    if (syncQueue != null && syncWorker != null) {
      await syncQueue.enqueue(
        entityType: 'tenant',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'tenant:bnb:checkin:${prop.propertyRef}:$_guestName:$_checkInIso',
      );
      syncWorker.runNow();
    }

    _step = _Step.done;

    final nights = BnbStayBilling.billingUnitsBetween(
      checkIn, checkOut, 'Per Night',
    );
    final nightLabel = isSw ? (nights == 1 ? 'usiku' : 'usiku') : (nights == 1 ? 'night' : 'nights');
    final totalLine = stayTotal > 0
        ? (isSw
            ? '• Jumla ($nights $nightLabel): ${_fmtNum(stayTotal)} $currency'
            : '• Total ($nights $nightLabel): ${_fmtNum(stayTotal)} $currency')
        : '';
    return isSw
        ? '✅ Mgeni amewekwa:\n'
          '• Mali: $propLabel\n'
          '${unitLabel.isNotEmpty ? "• Unit: $unitLabel\n" : ""}'
          '• Jina: $_guestName\n'
          '• Kuwasili: $_checkInIso\n'
          '• Kuondoka: $_checkOutIso\n'
          '• Bei ya usiku: ${_fmtNum(_nightlyRate)} $currency\n'
          '$totalLine'
        : '✅ Guest checked in:\n'
          '• Property: $propLabel\n'
          '${unitLabel.isNotEmpty ? "• Unit: $unitLabel\n" : ""}'
          '• Name: $_guestName\n'
          '• Check-in: $_checkInIso\n'
          '• Check-out: $_checkOutIso\n'
          '• Nightly rate: ${_fmtNum(_nightlyRate)} $currency\n'
          '$totalLine';
  }

  Future<String> _saveCheckOut() async {
    final tenantLocal = _findOrThrow<TenantLocalDataSource>();
    final syncQueue   = _find<OfflineSyncQueueLocalDataSource>();
    final syncWorker  = _find<OfflineSyncWorkerService>();
    final eventLocal  = _find<ClientEventLocalDataSource>();

    final g   = _targetGuest!;
    final now = _parseDate(_actualCheckOutIso) ?? DateTime.now();
    final endMs = now.millisecondsSinceEpoch;

    await tenantLocal.endTenancy(
      id: g.id,
      endedAtIso: _actualCheckOutIso,
      endedAtMs: endMs,
    );

    unawaited(eventLocal?.insert(
      tenantLocalId: g.id,
      phoneNumber: g.phoneNumber,
      clientName: g.tenantName,
      propertyRef: g.propertyRef,
      propertyLabel: g.propertyLabel,
      unitLabel: g.unitLabel,
      workspace: 'bnb',
      eventType: ClientEventType.checkOut,
      metadata: {'checkOutDate': _actualCheckOutIso},
    ));

    if (syncQueue != null && syncWorker != null) {
      await syncQueue.enqueue(
        entityType: 'tenant',
        operation: 'check_out',
        payloadJson: jsonEncode({
          'localTenantId': g.id,
          'backendTenantId': g.backendTenantId,
          'propertyRef': g.propertyRef,
          'checkOutIso': _actualCheckOutIso,
          'checkOutMs': endMs,
        }),
        dedupeKey: 'tenant:checkout:${g.id}',
      );
      syncWorker.runNow();
    }

    _step = _Step.done;
    return isSw
        ? '✅ "${g.tenantName}" ameondoka tarehe $_actualCheckOutIso.\n'
          '• Mali: ${g.propertyLabel}\n'
          '${g.unitLabel.isNotEmpty ? "• Unit: ${g.unitLabel}\n" : ""}'
          '• Tarehe ya kuwasili: ${g.leaseStartIso}\n\n'
          'Kumbuka kurekodi malipo yoyote yanayosubiri.'
        : '✅ "${g.tenantName}" checked out on $_actualCheckOutIso.\n'
          '• Property: ${g.propertyLabel}\n'
          '${g.unitLabel.isNotEmpty ? "• Unit: ${g.unitLabel}\n" : ""}'
          '• Original check-in: ${g.leaseStartIso}\n\n'
          'Remember to record any outstanding payments.';
  }

  // ── Loaders ────────────────────────────────────────────────────────────

  Future<String> _loadActiveGuests(PropertyRecord prop) async {
    final tenantLocal = _find<TenantLocalDataSource>();
    if (tenantLocal == null) {
      _step = _Step.done;
      return isSw ? '❌ Huduma haipatikani.' : '❌ Tenant service unavailable.';
    }
    final all = await tenantLocal.getActiveTenants();
    _activeGuests = all
        .where((t) =>
            t.propertyRef == prop.propertyRef &&
            (t.rentFrequency == 'Per Stay' ||
             t.rentFrequency == 'Per Night'))
        .toList();

    if (_activeGuests.isEmpty) {
      _step = _Step.done;
      return isSw
          ? 'ℹ️ Hakuna wageni wa sasa katika "${prop.propertyName}".'
          : 'ℹ️ No active guests found in "${prop.propertyName}".';
    }
    _step = _Step.askActiveGuest;
    return (isSw
        ? '🛎️ Ni mgeni gani anayeondoka?\n'
        : '🛎️ Which guest is checking out?\n') +
        _guestList();
  }

  // ── Prompts ────────────────────────────────────────────────────────────

  String _promptAction() => isSw
      ? '🛎️ Ungependa kufanya nini?\n${_actionList()}'
      : '🛎️ What would you like to do?\n${_actionList()}';

  String _actionList() => isSw
      ? '1. Pokesha mgeni (Check-in)\n2. Shusha mgeni (Check-out)'
      : '1. Check in a guest\n2. Check out a guest';

  String _promptPropertyList(String question) {
    if (_properties.isEmpty) {
      _step = _Step.done;
      return isSw
          ? 'Hakuna mali ya BnB. Ongeza mali kwanza.'
          : 'No BnB properties found. Please add a property first.';
    }
    return '$question\n${_propertyList()}';
  }

  String _propertyList() {
    final buf = StringBuffer();
    for (int i = 0; i < _properties.length; i++) {
      buf.writeln('${i + 1}. ${_properties[i].propertyName}');
    }
    return buf.toString().trimRight();
  }

  String _promptUnits(List<ApartmentUnitDraft> units) {
    return (isSw ? '🔑 Ni unit ipi?\n' : '🔑 Which unit?\n') + _unitList(units);
  }

  String _unitList(List<ApartmentUnitDraft> units) {
    final buf = StringBuffer();
    for (int i = 0; i < units.length; i++) {
      final u = units[i];
      final r = u.unitRent.trim();
      buf.writeln(r.isNotEmpty
          ? '${i + 1}. ${u.unitName} (${u.unitRent} ${u.unitRentCurrency}/night)'
          : '${i + 1}. ${u.unitName}');
    }
    return buf.toString().trimRight();
  }

  String _promptGuestName() => isSw
      ? '👤 Jina la mgeni ni nani?'
      : '👤 What is the guest\'s name?';

  String _promptConfirmCheckIn() {
    final propName  = _property?.propertyName ?? '';
    final unitLine  = _unit != null ? (isSw ? '• Unit: ${_unit!.unitName}\n' : '• Unit: ${_unit!.unitName}\n') : '';
    final currency  = _unit?.unitRentCurrency ?? 'TZS';
    final checkIn   = _parseDate(_checkInIso);
    final checkOut  = _parseDate(_checkOutIso);
    final nights    = (checkIn != null && checkOut != null)
        ? BnbStayBilling.billingUnitsBetween(checkIn, checkOut, 'Per Night')
        : 0;
    final total = BnbStayBilling.totalForStay(
      ratePerPeriod: _nightlyRate,
      frequency: 'Per Night',
      checkIn: checkIn ?? DateTime.now(),
      checkOut: checkOut ?? DateTime.now(),
    );
    final nightLabel = isSw ? 'usiku' : nights == 1 ? 'night' : 'nights';
    return isSw
        ? '📋 Thibitisha check-in:\n'
          '• Mali: $propName\n'
          '$unitLine'
          '• Mgeni: $_guestName\n'
          '• Simu: ${_phone.isNotEmpty ? _phone : "—"}\n'
          '• Kuwasili: $_checkInIso\n'
          '• Kuondoka: $_checkOutIso ($nights $nightLabel)\n'
          '• Bei ya usiku: ${_fmtNum(_nightlyRate)} $currency\n'
          '• Jumla ya kukaa: ${_fmtNum(total)} $currency\n\n'
          'Andika **ndio** kuhifadhi au **hapana** kughairi.'
        : '📋 Confirm check-in:\n'
          '• Property: $propName\n'
          '$unitLine'
          '• Guest: $_guestName\n'
          '• Phone: ${_phone.isNotEmpty ? _phone : "—"}\n'
          '• Check-in: $_checkInIso\n'
          '• Check-out: $_checkOutIso ($nights $nightLabel)\n'
          '• Nightly rate: ${_fmtNum(_nightlyRate)} $currency\n'
          '• Stay total: ${_fmtNum(total)} $currency\n\n'
          'Type **yes** to save or **no** to cancel.';
  }

  String _promptConfirmCheckOut() {
    final g = _targetGuest!;
    return isSw
        ? '📋 Thibitisha check-out:\n'
          '• Mgeni: ${g.tenantName}\n'
          '• Mali: ${g.propertyLabel}\n'
          '${g.unitLabel.isNotEmpty ? "• Unit: ${g.unitLabel}\n" : ""}'
          '• Aliingia: ${g.leaseStartIso}\n'
          '• Anaondoka: $_actualCheckOutIso\n\n'
          'Andika **ndio** kuthibitisha au **hapana** kughairi.'
        : '📋 Confirm check-out:\n'
          '• Guest: ${g.tenantName}\n'
          '• Property: ${g.propertyLabel}\n'
          '${g.unitLabel.isNotEmpty ? "• Unit: ${g.unitLabel}\n" : ""}'
          '• Checked in: ${g.leaseStartIso}\n'
          '• Checking out: $_actualCheckOutIso\n\n'
          'Type **yes** to confirm or **no** to cancel.';
  }

  String _guestList() {
    final buf = StringBuffer();
    final fmt = DateFormat('MMM d');
    for (int i = 0; i < _activeGuests.length; i++) {
      final g = _activeGuests[i];
      final unit = g.unitLabel.trim().isNotEmpty ? ' (${g.unitLabel})' : '';
      final dates = g.leaseStartIso.isNotEmpty
          ? ' — ${_fmtShort(g.leaseStartIso, fmt)} → ${_fmtShort(g.leaseEndIso, fmt)}'
          : '';
      buf.writeln('${i + 1}. ${g.tenantName}$unit$dates');
    }
    return buf.toString().trimRight();
  }

  // ── Parsing & formatting helpers ───────────────────────────────────────

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
    if (idx != null && idx >= 1 && idx <= units.length) return units[idx - 1];
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
          .where((u) =>
              u.unitName.trim().isNotEmpty &&
              (u.operationMode == 'bnb' || u.operationMode == 'both'))
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
    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(lower);
    if (ymd != null) {
      final y = int.parse(ymd.group(1)!);
      final m = int.parse(ymd.group(2)!);
      final d = int.parse(ymd.group(3)!);
      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) return DateTime(y, m, d);
    }
    final dmy = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$').firstMatch(lower);
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
    final kMatch = RegExp(r'^(\d+(?:\.\d+)?)k$', caseSensitive: false)
        .firstMatch(text.trim().toLowerCase());
    if (kMatch != null) {
      final v = double.tryParse(kMatch.group(1)!);
      if (v != null && v > 0) return v * 1000;
    }
    final v = double.tryParse(clean);
    return (v != null && v > 0) ? v : null;
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtNum(double v) {
    if (v == v.roundToDouble()) {
      return NumberFormat('#,###').format(v.round());
    }
    return v.toStringAsFixed(0);
  }

  static String _fmtShort(String iso, DateFormat fmt) {
    try {
      return fmt.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
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

enum _GuestAction { unknown, checkIn, checkOut }

enum _Step {
  askAction,
  askProperty,
  askUnit,
  askGuestName,
  askPhone,
  askCheckIn,
  askCheckOut,
  askNightlyRate,
  askActiveGuest,
  askActualCheckOut,
  confirm,
  done,
}

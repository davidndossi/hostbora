import 'dart:convert';

import 'package:get/get.dart';

import '../../../modules/add_listing/models/apartment_unit_draft.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../preference/preference_manager.dart';
import '../service/offline_sync_worker_service.dart';

/// Multi-turn conversational flow for adding a new property or a unit to an
/// existing property, entirely inside the AI Manager chat.
class AiPropertyFlow {
  AiPropertyFlow({
    required this.isSw,
    required List<PropertyRecord> existingProperties,
  }) : _existingProperties = List.unmodifiable(existingProperties);

  final bool isSw;
  final List<PropertyRecord> _existingProperties;

  // ── State ──────────────────────────────────────────────────────────────
  _Step _step = _Step.askAction;
  bool get isComplete => _step == _Step.done;

  // Determines the top-level action
  bool _isNewProperty = true;

  // ── New-property fields ────────────────────────────────────────────────
  String? _propertyType;
  String? _propertyName;
  String? _propertyLocation;
  String? _workspaceType; // 'bnb' | 'rent' | 'both'
  String _rentAmount = '';
  String _rentFrequency = 'Per Month';

  // ── Unit collection ────────────────────────────────────────────────────
  final _units = <ApartmentUnitDraft>[];
  // Current-unit draft
  String? _currentUnitName;
  String? _currentUnitMode; // 'bnb' | 'rent'
  String _currentUnitRent = '';
  String _currentUnitFrequency = 'Per Day';

  // ── Add-unit-to-existing fields ────────────────────────────────────────
  PropertyRecord? _targetProperty;

  // ── Constants ─────────────────────────────────────────────────────────
  static const _propertyTypes = [
    'Apartment',
    'House',
    'Villa',
    'Cabin',
    'Studio',
    'Other',
  ];

  bool get _isApartment =>
      (_propertyType ?? '').trim().toLowerCase() == 'apartment';

  // ── Opening prompt ─────────────────────────────────────────────────────

  String get openingPrompt => _promptAction();

  // ── Public entry point ─────────────────────────────────────────────────

  Future<String> handleTurn(String userInput) async {
    final text = userInput.trim();
    switch (_step) {
      case _Step.askAction:
        return _handleAction(text);
      case _Step.askPropertyType:
        return _handlePropertyType(text);
      case _Step.askPropertyName:
        return _handlePropertyName(text);
      case _Step.askPropertyLocation:
        return _handlePropertyLocation(text);
      case _Step.askWorkspaceType:
        return _handleWorkspaceType(text);
      case _Step.askRentAmount:
        return _handleRentAmount(text);
      case _Step.askRentFrequency:
        return _handleRentFrequency(text);
      case _Step.askUnitName:
        return _handleUnitName(text);
      case _Step.askUnitMode:
        return _handleUnitMode(text);
      case _Step.askUnitRent:
        return _handleUnitRent(text);
      case _Step.askUnitFrequency:
        return _handleUnitFrequency(text);
      case _Step.askAnotherUnit:
        return _handleAnotherUnit(text);
      case _Step.askExistingProperty:
        return _handleExistingProperty(text);
      case _Step.confirm:
        return _handleConfirm(text);
      case _Step.done:
        return '';
    }
  }

  // ── Step handlers ──────────────────────────────────────────────────────

  String _handleAction(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);

    bool isNew = false;

    if (idx == 1) {
      isNew = true;
    } else if (idx == 2) {
      isNew = false;
    } else if (_containsAny(lower, ['new property', 'add property', 'mali mpya',
                                    'ongeza mali', 'nyumba mpya'])) {
      isNew = true;
    } else if (_containsAny(lower, ['unit', 'add unit', 'ongeza unit',
                                    'chumba', 'new unit'])) {
      isNew = false;
    } else {
      return isSw
          ? '❓ Tafadhali chagua:\n${_actionList()}'
          : '❓ Please choose:\n${_actionList()}';
    }

    if (isNew) {
      _isNewProperty = true;
      _step = _Step.askPropertyType;
      return _promptPropertyType();
    } else {
      _isNewProperty = false;
      if (_existingProperties.isEmpty) {
        _step = _Step.done;
        return isSw
            ? 'Hakuna mali iliyopatikana. Anza kwa kuongeza mali mpya.'
            : 'No properties found. Please add a new property first.';
      }
      if (_existingProperties.length == 1) {
        _targetProperty = _existingProperties.first;
        _workspaceType  = _targetProperty!.workspaceType;
        _step = _Step.askUnitName;
        return _promptUnitName(1);
      }
      _step = _Step.askExistingProperty;
      return _promptExistingProperty();
    }
  }

  String _handlePropertyType(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= _propertyTypes.length) {
      _propertyType = _propertyTypes[idx - 1];
    } else {
      for (final t in _propertyTypes) {
        if (t.toLowerCase().contains(lower) ||
            lower.contains(t.toLowerCase())) {
          _propertyType = t;
          break;
        }
      }
    }
    if (_propertyType == null) {
      return isSw
          ? '❓ Aina haijulikani. Chagua nambari:\n${_typeList()}'
          : '❓ Type not recognised. Choose a number:\n${_typeList()}';
    }
    _step = _Step.askPropertyName;
    return isSw
        ? '🏷️ Jina la mali ni nini?'
        : '🏷️ What is the property name?';
  }

  String _handlePropertyName(String text) {
    if (text.isEmpty) {
      return isSw
          ? '❓ Jina haliwezi kuwa tupu. Tafadhali weka jina.'
          : '❓ Name cannot be empty. Please enter a name.';
    }
    _propertyName = text;
    _step = _Step.askPropertyLocation;
    return isSw
        ? '📍 Anwani au eneo la mali iko wapi?'
        : '📍 What is the address or location?';
  }

  String _handlePropertyLocation(String text) {
    if (text.isEmpty) {
      return isSw
          ? '❓ Eneo haliwezi kuwa tupu.'
          : '❓ Location cannot be empty.';
    }
    _propertyLocation = text;
    _step = _Step.askWorkspaceType;
    return _promptWorkspaceType();
  }

  String _handleWorkspaceType(String text) {
    final mode = _parseMode(text);
    if (mode == null) {
      return isSw
          ? '❓ Chagua:\n${_modeList()}'
          : '❓ Please choose:\n${_modeList()}';
    }
    _workspaceType = mode;

    if (_isApartment) {
      // Jump straight to collecting units
      _step = _Step.askUnitName;
      return _promptUnitName(1);
    } else {
      _step = _Step.askRentAmount;
      return _promptRentAmount();
    }
  }

  String _handleRentAmount(String text) {
    final parsed = _parseAmount(text);
    if (parsed == null) {
      return isSw
          ? '❓ Kiasi sio sahihi. Andika kama "500000" au "500,000".'
          : '❓ Invalid amount. Type something like "500000" or "500,000".';
    }
    _rentAmount = parsed.toString();
    _step       = _Step.askRentFrequency;
    return _promptRentFrequency(isSw
        ? 'Mali nzima'
        : 'whole property');
  }

  String _handleRentFrequency(String text) {
    final freq = _parseFrequency(text);
    if (freq == null) {
      return isSw
          ? '❓ Chagua "kwa siku" au "kwa mwezi".'
          : '❓ Choose "per day" or "per month".';
    }
    _rentFrequency = freq;
    _step = _Step.confirm;
    return _promptConfirm();
  }

  String _handleUnitName(String text) {
    if (text.isEmpty) {
      return isSw
          ? '❓ Jina la unit haliwezi kuwa tupu.'
          : '❓ Unit name cannot be empty.';
    }
    _currentUnitName = text;

    // Only ask mode when property supports both
    final propMode = (_workspaceType ?? _targetProperty?.workspaceType ?? 'bnb').trim().toLowerCase();
    if (propMode == 'both') {
      _step = _Step.askUnitMode;
      return _promptUnitMode();
    }
    // Mode is fixed by the property
    _currentUnitMode = propMode == 'rent' ? 'rent' : 'bnb';
    _step = _Step.askUnitRent;
    return _promptUnitRentAmount();
  }

  String _handleUnitMode(String text) {
    final mode = _parseMode(text, allowBoth: false);
    if (mode == null) {
      return isSw
          ? '❓ Chagua:\n1. BnB (kwa usiku)\n2. Kukodisha muda mrefu'
          : '❓ Choose:\n1. BnB (nightly)\n2. Long-term rent';
    }
    _currentUnitMode = mode;
    _step = _Step.askUnitRent;
    return _promptUnitRentAmount();
  }

  String _handleUnitRent(String text) {
    final parsed = _parseAmount(text);
    if (parsed == null) {
      return isSw
          ? '❓ Kiasi sio sahihi. Andika kama "50000" au "50,000".'
          : '❓ Invalid amount. Type something like "50000" or "50,000".';
    }
    _currentUnitRent = parsed.toString();
    _step = _Step.askUnitFrequency;
    return _promptRentFrequency(_currentUnitName ?? 'unit');
  }

  String _handleUnitFrequency(String text) {
    final freq = _parseFrequency(text);
    if (freq == null) {
      return isSw
          ? '❓ Chagua "kwa siku" au "kwa mwezi".'
          : '❓ Choose "per day" or "per month".';
    }
    _currentUnitFrequency = freq;

    // Commit this unit draft
    _units.add(ApartmentUnitDraft(
      unitId: 'u_${DateTime.now().microsecondsSinceEpoch}_${_units.length}',
      unitName: _currentUnitName!,
      unitRent: _currentUnitRent,
      unitRentFrequency: _currentUnitFrequency,
      operationMode: _currentUnitMode ?? 'bnb',
      unitDescription: '',
    ));

    // Adding unit to existing property → go straight to confirm
    if (!_isNewProperty) {
      _step = _Step.confirm;
      return _promptConfirm();
    }

    // New apartment property → offer to add another unit
    _step = _Step.askAnotherUnit;
    return isSw
        ? '✔ Unit "${_currentUnitName!}" imeongezwa.\n\n'
          '➕ Je, ungependa kuongeza unit nyingine? (ndio / hapana)'
        : '✔ Unit "${_currentUnitName!}" added.\n\n'
          '➕ Add another unit? (yes / no)';
  }

  String _handleAnotherUnit(String text) {
    final lower = text.toLowerCase().trim();
    final yes   = lower.startsWith('y') || lower == 'ndio' || lower == 'ndiyo';
    final no    = lower.startsWith('n') || lower == 'hapana';

    if (yes) {
      _currentUnitName      = null;
      _currentUnitMode      = null;
      _currentUnitRent      = '';
      _currentUnitFrequency = 'Per Day';
      _step = _Step.askUnitName;
      return _promptUnitName(_units.length + 1);
    }
    if (no) {
      _step = _Step.confirm;
      return _promptConfirm();
    }
    return isSw
        ? 'Andika **ndio** kuongeza au **hapana** kuendelea.'
        : 'Type **yes** to add another or **no** to continue.';
  }

  String _handleExistingProperty(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    PropertyRecord? match;
    if (idx != null && idx >= 1 && idx <= _existingProperties.length) {
      match = _existingProperties[idx - 1];
    } else {
      for (final p in _existingProperties) {
        final n = p.propertyName.toLowerCase();
        if (n.contains(lower) || lower.contains(n)) {
          match = p;
          break;
        }
      }
    }
    if (match == null) {
      return isSw
          ? '❓ Sikupata mali inayolingana. Jaribu nambari:\n${_existingPropertyList()}'
          : '❓ No matching property. Try the number:\n${_existingPropertyList()}';
    }
    _targetProperty = match;
    _workspaceType  = match.workspaceType;
    _step = _Step.askUnitName;
    return _promptUnitName(_existingUnitCount(match) + 1);
  }

  Future<String> _handleConfirm(String text) async {
    final lower = text.toLowerCase().trim();
    final yes = lower.startsWith('y') ||
        lower.startsWith('ndio') ||
        lower == 'confirm' ||
        lower == 'save' ||
        lower == 'hifadhi';
    final no  = lower.startsWith('n') ||
        lower == 'hapana' ||
        lower == 'ghairi' ||
        lower == 'cancel';

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
      final result = _isNewProperty
          ? await _saveNewProperty()
          : await _saveUnitToExisting();
      _step = _Step.done;
      return result;
    } catch (e) {
      _step = _Step.done;
      return isSw ? '❌ Imeshindwa: $e' : '❌ Failed: $e';
    }
  }

  // ── Save operations ────────────────────────────────────────────────────

  Future<String> _saveNewProperty() async {
    final propLocal  = _findOrThrow<PropertyLocalDataSource>();
    final syncQueue  = _find<OfflineSyncQueueLocalDataSource>();
    final syncWorker = _find<OfflineSyncWorkerService>();

    final unitMaps = _units.map((u) => u.toJson()).toList();
    final unitsJson = unitMaps.isEmpty ? '' : jsonEncode(unitMaps);
    final propertyRef = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    String ownerUserId = '';
    try {
      if (Get.isRegistered<PreferenceManager>(
          tag: (PreferenceManager).toString())) {
        final pref =
            Get.find<PreferenceManager>(tag: (PreferenceManager).toString());
        ownerUserId = (await pref.getUser()).id ?? '';
      }
    } catch (_) {}

    final workspaceType = _workspaceType ?? 'bnb';
    final propType      = _propertyType ?? 'House';

    await propLocal.insert(
      PropertyRecord(
        id: 0,
        propertyName: _propertyName!,
        propertyType: propType,
        propertyLocation: _propertyLocation!,
        propertyRef: propertyRef,
        tenants: 0,
        units: _isApartment ? _units.length : 1,
        ownerUserId: ownerUserId,
        workspaceType: workspaceType,
        createdAtMs: nowMs,
        rentAmount: _isApartment ? '' : _rentAmount,
        rentFrequency: _isApartment ? '' : _rentFrequency,
        minRentalDuration: '1 Day',
        unitsJson: unitsJson,
        floorCount: 1,
        coverPhotoPath: '',
      ),
    );

    // Queue for backend sync
    if (syncQueue != null && syncWorker != null) {
      final payload = {
        'property_ref': propertyRef,
        'location': _propertyLocation,
        'name': _propertyName,
        'type': propType,
        'tenants': 0,
        'units': _isApartment ? _units.length : 1,
        'workspace_type': workspaceType,
        'created_at_ms': nowMs,
        'rent_amount': _isApartment ? '' : _rentAmount,
        'rent_frequency': _isApartment ? '' : _rentFrequency,
        'min_rental_duration': '1 Day',
        'units_json': unitsJson,
        'floor_count': 1,
        'owner_user_id': ownerUserId,
      };
      await syncQueue.enqueue(
        entityType: 'property',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'property:create:$propertyRef',
      );
      syncWorker.runNow(maxItems: 5);
    }

    final buf = StringBuffer();
    buf.writeln(isSw
        ? '✅ Mali imehifadhiwa:\n'
          '• Aina: $propType\n'
          '• Jina: ${_propertyName!}\n'
          '• Eneo: ${_propertyLocation!}\n'
          '• Aina ya ukodishaji: ${_modeLabelSw(workspaceType)}'
        : '✅ Property saved:\n'
          '• Type: $propType\n'
          '• Name: ${_propertyName!}\n'
          '• Location: ${_propertyLocation!}\n'
          '• Mode: ${_modeLabelEn(workspaceType)}');
    if (_units.isNotEmpty) {
      buf.writeln();
      buf.writeln(isSw ? '📦 Units (${_units.length}):' : '📦 Units (${_units.length}):');
      for (final u in _units) {
        buf.writeln(
          '• ${u.unitName} — ${_modeLabelEn(u.operationMode)} · '
          '${u.unitRent} ${u.unitRentFrequency}',
        );
      }
    } else if (_rentAmount.isNotEmpty) {
      buf.writeln(isSw
          ? '• Kodi: $_rentAmount ($_rentFrequency)'
          : '• Rent: $_rentAmount ($_rentFrequency)');
    }
    return buf.toString().trim();
  }

  Future<String> _saveUnitToExisting() async {
    final propLocal  = _findOrThrow<PropertyLocalDataSource>();
    final syncQueue  = _find<OfflineSyncQueueLocalDataSource>();
    final syncWorker = _find<OfflineSyncWorkerService>();

    final prop = _targetProperty!;
    final unit = _units.first; // always one unit in this branch

    // Parse existing units JSON
    List<Map<String, dynamic>> existing = [];
    if (prop.unitsJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(prop.unitsJson);
        if (decoded is List) {
          existing = decoded
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      } catch (_) {}
    }
    existing.add(unit.toJson());
    final newUnitsJson = jsonEncode(existing);

    final updated = PropertyRecord(
      id: prop.id,
      propertyName: prop.propertyName,
      propertyType: prop.propertyType,
      propertyLocation: prop.propertyLocation,
      propertyRef: prop.propertyRef,
      tenants: prop.tenants,
      units: existing.length,
      ownerUserId: prop.ownerUserId,
      workspaceType: prop.workspaceType,
      createdAtMs: prop.createdAtMs,
      rentAmount: prop.rentAmount,
      rentFrequency: prop.rentFrequency,
      minRentalDuration: prop.minRentalDuration,
      unitsJson: newUnitsJson,
      floorCount: prop.floorCount,
      coverPhotoPath: prop.coverPhotoPath,
    );
    await propLocal.update(updated);

    if (syncQueue != null && syncWorker != null) {
      final payload = {
        'property_ref': prop.propertyRef,
        'units_json': newUnitsJson,
        'units': existing.length,
      };
      await syncQueue.enqueue(
        entityType: 'property',
        operation: 'update',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'property:update:${prop.propertyRef}',
      );
      syncWorker.runNow(maxItems: 5);
    }

    return isSw
        ? '✅ Unit imehifadhiwa kwenye "${prop.propertyName}":\n'
          '• Jina: ${unit.unitName}\n'
          '• Aina: ${_modeLabelSw(unit.operationMode)}\n'
          '• Kodi: ${unit.unitRent} (${unit.unitRentFrequency})'
        : '✅ Unit added to "${prop.propertyName}":\n'
          '• Name: ${unit.unitName}\n'
          '• Mode: ${_modeLabelEn(unit.operationMode)}\n'
          '• Rent: ${unit.unitRent} (${unit.unitRentFrequency})';
  }

  // ── Prompt builders ────────────────────────────────────────────────────

  String _promptAction() {
    return isSw
        ? '🏠 Ungependa kufanya nini?\n'
          '1. Ongeza mali mpya\n'
          '2. Ongeza unit kwenye mali iliyopo'
        : '🏠 What would you like to do?\n'
          '1. Add a new property\n'
          '2. Add a unit to an existing property';
  }

  String _actionList() => isSw
      ? '1. Ongeza mali mpya\n2. Ongeza unit kwenye mali iliyopo'
      : '1. Add new property\n2. Add unit to existing property';

  String _promptPropertyType() {
    return (isSw
        ? '🏢 Ni aina gani ya mali?\n'
        : '🏢 What type of property?\n') +
        _typeList();
  }

  String _typeList() {
    final buf = StringBuffer();
    for (int i = 0; i < _propertyTypes.length; i++) {
      buf.writeln('${i + 1}. ${_propertyTypes[i]}');
    }
    return buf.toString().trimRight();
  }

  String _promptWorkspaceType() {
    return isSw
        ? '📋 Ni aina gani ya ukodishaji?\n${_modeList()}'
        : '📋 What is the rental mode?\n${_modeList()}';
  }

  String _modeList() => isSw
      ? '1. BnB (kwa usiku / wageni)\n'
        '2. Kukodisha muda mrefu\n'
        '3. Zote mbili'
      : '1. BnB (nightly / guests)\n'
        '2. Long-term rent\n'
        '3. Both';

  String _promptRentAmount() {
    return isSw
        ? '💰 Kodi ni kiasi gani? (k.m. 500000)'
        : '💰 What is the rent amount? (e.g. 500000)';
  }

  String _promptRentFrequency(String forLabel) {
    return isSw
        ? '📅 Kwa $forLabel — kodi ni kwa siku au kwa mwezi?\n'
          '1. Kwa siku\n'
          '2. Kwa mwezi'
        : '📅 For $forLabel — rent is per day or per month?\n'
          '1. Per day\n'
          '2. Per month';
  }

  String _promptUnitName(int unitNumber) {
    return isSw
        ? '🔑 Jina la unit #$unitNumber ni nini? (k.m. "Unit A", "101", "Ghorofa ya pili")'
        : '🔑 What is the name for unit #$unitNumber? (e.g. "Unit A", "101", "Second floor")';
  }

  String _promptUnitMode() {
    return isSw
        ? '📋 Unit hii itakuwa kwa:\n'
          '1. BnB (kwa usiku / wageni)\n'
          '2. Kukodisha muda mrefu'
        : '📋 This unit will be used for:\n'
          '1. BnB (nightly / guests)\n'
          '2. Long-term rent';
  }

  String _promptUnitRentAmount() {
    final mode = _currentUnitMode ?? 'bnb';
    final label = mode == 'rent'
        ? (isSw ? 'kodi ya kila mwezi' : 'monthly rent')
        : (isSw ? 'bei ya kila usiku' : 'nightly rate');
    return isSw
        ? '💰 Bei ya "${_currentUnitName!}" ($label) ni kiasi gani?'
        : '💰 What is the $label for "${_currentUnitName!}"?';
  }

  String _promptExistingProperty() {
    return (isSw
        ? '🏠 Unit inaenda kwenye mali ipi?\n'
        : '🏠 Which property should this unit be added to?\n') +
        _existingPropertyList();
  }

  String _existingPropertyList() {
    final buf = StringBuffer();
    for (int i = 0; i < _existingProperties.length; i++) {
      buf.writeln('${i + 1}. ${_existingProperties[i].propertyName}');
    }
    return buf.toString().trimRight();
  }

  String _promptConfirm() {
    if (_isNewProperty) {
      final mode = _workspaceType ?? 'bnb';
      final buf = StringBuffer();
      buf.writeln(isSw ? '📋 Thibitisha mali mpya:' : '📋 Confirm new property:');
      buf.writeln('• ${isSw ? "Aina" : "Type"}: ${_propertyType ?? "House"}');
      buf.writeln('• ${isSw ? "Jina" : "Name"}: ${_propertyName ?? ""}');
      buf.writeln('• ${isSw ? "Eneo" : "Location"}: ${_propertyLocation ?? ""}');
      buf.writeln('• ${isSw ? "Ukodishaji" : "Mode"}: ${isSw ? _modeLabelSw(mode) : _modeLabelEn(mode)}');
      if (_units.isNotEmpty) {
        buf.writeln(isSw ? '• Units (${_units.length}):' : '• Units (${_units.length}):');
        for (final u in _units) {
          buf.writeln('  – ${u.unitName} · ${_modeLabelEn(u.operationMode)} · ${u.unitRent} ${u.unitRentFrequency}');
        }
      } else if (_rentAmount.isNotEmpty) {
        buf.writeln('• ${isSw ? "Kodi" : "Rent"}: $_rentAmount ($_rentFrequency)');
      }
      buf.writeln();
      buf.writeln(isSw
          ? 'Andika **ndio** kuhifadhi au **hapana** kughairi.'
          : 'Type **yes** to save or **no** to cancel.');
      return buf.toString().trim();
    } else {
      final unit = _units.isNotEmpty ? _units.first : null;
      final prop = _targetProperty;
      return isSw
          ? '📋 Thibitisha unit mpya:\n'
            '• Mali: ${prop?.propertyName ?? ""}\n'
            '• Jina la unit: ${unit?.unitName ?? ""}\n'
            '• Aina: ${isSw ? _modeLabelSw(unit?.operationMode ?? "bnb") : _modeLabelEn(unit?.operationMode ?? "bnb")}\n'
            '• Kodi: ${unit?.unitRent ?? ""} (${unit?.unitRentFrequency ?? ""})\n\n'
            'Andika **ndio** kuhifadhi au **hapana** kughairi.'
          : '📋 Confirm new unit:\n'
            '• Property: ${prop?.propertyName ?? ""}\n'
            '• Unit name: ${unit?.unitName ?? ""}\n'
            '• Mode: ${_modeLabelEn(unit?.operationMode ?? "bnb")}\n'
            '• Rent: ${unit?.unitRent ?? ""} (${unit?.unitRentFrequency ?? ""})\n\n'
            'Type **yes** to save or **no** to cancel.';
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String? _parseMode(String text, {bool allowBoth = true}) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx == 1) return 'bnb';
    if (idx == 2) return 'rent';
    if (allowBoth && idx == 3) return 'both';
    if (_containsAny(lower, ['bnb', 'airbnb', 'nightly', 'guest', 'usiku', 'wageni'])) return 'bnb';
    if (_containsAny(lower, ['rent', 'long', 'month', 'mwezi', 'muda mrefu', 'kukodisha'])) return 'rent';
    if (allowBoth && _containsAny(lower, ['both', 'zote', 'zote mbili'])) return 'both';
    return null;
  }

  String? _parseFrequency(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx == 1) return 'Per Day';
    if (idx == 2) return 'Per Month';
    if (_containsAny(lower, ['day', 'daily', 'night', 'siku', 'usiku', 'per day'])) return 'Per Day';
    if (_containsAny(lower, ['month', 'monthly', 'mwezi', 'per month'])) return 'Per Month';
    return null;
  }

  double? _parseAmount(String text) {
    final clean = text
        .replaceAll(RegExp(r'[A-Za-z]+'), '')
        .replaceAll(',', '')
        .trim();
    final kMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*k$', caseSensitive: false)
        .firstMatch(clean);
    if (kMatch != null) {
      final v = double.tryParse(kMatch.group(1)!);
      if (v != null) return v * 1000;
    }
    final v = double.tryParse(clean);
    return (v != null && v > 0) ? v : null;
  }

  int _existingUnitCount(PropertyRecord prop) {
    try {
      final decoded = jsonDecode(prop.unitsJson);
      if (decoded is List) return decoded.length;
    } catch (_) {}
    return 0;
  }

  static bool _containsAny(String text, List<String> tokens) =>
      tokens.any(text.contains);

  static String _modeLabelEn(String mode) {
    switch (mode.toLowerCase()) {
      case 'rent':  return 'Long-term rent';
      case 'both':  return 'BnB + Rent';
      default:      return 'BnB';
    }
  }

  static String _modeLabelSw(String mode) {
    switch (mode.toLowerCase()) {
      case 'rent':  return 'Kukodisha muda mrefu';
      case 'both':  return 'BnB na Kukodisha';
      default:      return 'BnB';
    }
  }

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

enum _Step {
  askAction,
  askPropertyType,
  askPropertyName,
  askPropertyLocation,
  askWorkspaceType,
  askRentAmount,
  askRentFrequency,
  askUnitName,
  askUnitMode,
  askUnitRent,
  askUnitFrequency,
  askAnotherUnit,
  askExistingProperty,
  confirm,
  done,
}

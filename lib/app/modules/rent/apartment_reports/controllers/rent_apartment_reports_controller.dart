import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/values/property_unit_floor.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/property_unit_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';
import '../utils/apartment_report_pdf.dart';
import '../../../../data/service/analytics_service.dart';

enum ApartmentReportTab { rent, serviceCharge }

class RentApartmentReportsController extends BaseController {
  RentApartmentReportsController()
      : _tenantLocal = Get.find<TenantLocalDataSource>(),
        _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _prefs = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        );

  final TenantLocalDataSource _tenantLocal;
  final IncomeLocalDataSource _incomeLocal;
  final PropertyLocalDataSource _propertyLocal;
  final PreferenceManager _prefs;

  static const allUnitsKey = '__all__';

  final propertyRef = ''.obs;
  final propertyTitle = ''.obs;
  final selectedUnitKey = allUnitsKey.obs;
  final unitOptions = <MapEntry<String, String>>[].obs;
  final selectedTab = ApartmentReportTab.rent.obs;
  final loading = false.obs;
  final exporting = false.obs;

  final rentRows = <ApartmentRentReportRow>[].obs;
  final serviceChargeRows = <ApartmentServiceChargeReportRow>[].obs;

  final _date = DateFormat('dd/MM/yyyy');
  final _month = DateFormat('MMM yyyy');

  List<TenantRecord> _tenants = const [];
  List<IncomeRecord> _incomes = const [];
  String _defaultRecipient = '';

  /// Unit id and lower-cased unit name → floor index from units JSON or property_units.
  final Map<String, int> _unitFloors = {};

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String get unitFilterLabel {
    final key = selectedUnitKey.value;
    if (key == allUnitsKey) {
      return _isSw ? 'Vyumba vyote' : 'All units';
    }
    for (final e in unitOptions) {
      if (e.key == key) return e.value;
    }
    return key;
  }

  @override
  void onInit() {
    super.onInit();
    propertyRef.value = (Get.parameters['propertyRef'] ?? '').trim();
    propertyTitle.value = (Get.parameters['propertyTitle'] ??
            Get.parameters['propertyLabel'] ??
            '')
        .trim();
    final args = Get.arguments;
    if (args is Map) {
      if (propertyRef.value.isEmpty) {
        propertyRef.value = (args['propertyRef'] ?? '').toString().trim();
      }
      if (propertyTitle.value.isEmpty) {
        propertyTitle.value = (args['propertyTitle'] ??
                args['propertyLabel'] ??
                '')
            .toString()
            .trim();
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    try {
      _defaultRecipient = await _prefs.getString(
        PreferenceManager.keyUsername,
        defaultValue: '',
      );
      await _loadPropertyTitleIfNeeded();
      _tenants = await _loadScopedTenants();
      _incomes = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
      await _rebuildUnitOptions();
      rebuildRows();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadPropertyTitleIfNeeded() async {
    if (propertyTitle.value.isNotEmpty) return;
    final ref = propertyRef.value.trim();
    if (ref.isEmpty) return;
    final all = await _propertyLocal.getAllNewestFirst();
    for (final p in all) {
      if (p.workspaceType.trim().toLowerCase() == 'bnb') continue;
      final pref = p.propertyRef.trim();
      final local = 'local_${p.id}';
      if (pref == ref || local == ref) {
        final loc = p.propertyLocation.trim();
        final name = p.propertyName.trim();
        propertyTitle.value = loc.isNotEmpty
            ? (name.isNotEmpty ? '$loc · $name' : loc)
            : (name.isNotEmpty ? name : ref);
        return;
      }
    }
  }

  Future<List<TenantRecord>> _loadScopedTenants() async {
    final all = await _tenantLocal.getAllNewestFirstByWorkspace('rent');
    final ref = propertyRef.value.trim();
    if (ref.isEmpty) return all;
    return all.where((t) {
      final tr = t.propertyRef.trim();
      if (tr.isNotEmpty && (tr == ref || ref.contains(tr) || tr.contains(ref))) {
        return true;
      }
      final title = propertyTitle.value.trim().toLowerCase();
      if (title.isEmpty) return false;
      final pl = t.propertyLabel.trim().toLowerCase();
      return pl == title || pl.contains(title) || title.contains(pl);
    }).toList();
  }

  Future<void> _rebuildUnitOptions() async {
    _unitFloors.clear();
    final map = <String, String>{};
    for (final t in _tenants) {
      final id = t.apartmentUnitId.trim();
      final label = t.unitLabel.trim();
      if (id.isNotEmpty) {
        map[id] = label.isNotEmpty ? label : id;
      } else if (label.isNotEmpty) {
        map['label:$label'] = label;
      }
    }
    await _appendUnitsFromProperty(map);

    final entries = map.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    unitOptions.assignAll([
      MapEntry(
        allUnitsKey,
        _isSw ? 'Vyumba vyote' : 'All units',
      ),
      ...entries,
    ]);
    if (!unitOptions.any((e) => e.key == selectedUnitKey.value)) {
      selectedUnitKey.value = allUnitsKey;
    }
  }

  Future<void> _appendUnitsFromProperty(Map<String, String> map) async {
    final ref = propertyRef.value.trim();
    if (ref.isEmpty) return;
    final all = await _propertyLocal.getAllNewestFirst();
    for (final p in all) {
      final pref = p.propertyRef.trim();
      final local = 'local_${p.id}';
      final legacy = 'legacy_${p.id}';
      if (pref != ref && local != ref && legacy != ref) continue;
      final raw = p.unitsJson.trim();
      if (raw.isNotEmpty && raw != '[]') {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is! Map) continue;
              final name =
                  (item['unitName'] ?? item['name'] ?? '').toString().trim();
              final id = (item['unitId'] ?? item['id'] ?? name).toString().trim();
              if (name.isEmpty) continue;
              map.putIfAbsent(id.isNotEmpty ? id : 'label:$name', () => name);
              _rememberFloor(
                id,
                name,
                _floorOrNull(item['unitFloor'] ?? item['floor']),
              );
            }
          }
        } catch (_) {}
      }
      if (Get.isRegistered<PropertyUnitLocalDataSource>()) {
        final unitLocal = Get.find<PropertyUnitLocalDataSource>();
        final refs = <String>{pref, local, legacy, if (ref.isNotEmpty) ref};
        for (final unitRef in refs) {
          if (unitRef.isEmpty) continue;
          final rows = await unitLocal.getAllByPropertyRefNewestFirstChunked(
            propertyRef: unitRef,
          );
          for (final row in rows) {
            _rememberFloor(row.propertyUnitRef, row.unitName, row.floor);
          }
        }
      }
      return;
    }
  }

  void _rememberFloor(String id, String name, int? floor) {
    if (floor == null) return;
    final unitId = id.trim();
    if (unitId.isNotEmpty) {
      _unitFloors.putIfAbsent(unitId, () => floor);
    }
    final unitName = name.trim().toLowerCase();
    if (unitName.isNotEmpty) {
      _unitFloors.putIfAbsent('name:$unitName', () => floor);
    }
  }

  int? _floorOrNull(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  int? _floorForTenant(TenantRecord t) {
    final id = t.apartmentUnitId.trim();
    if (id.isNotEmpty && _unitFloors.containsKey(id)) return _unitFloors[id];
    final name = t.unitLabel.trim().toLowerCase();
    if (name.isNotEmpty && _unitFloors.containsKey('name:$name')) {
      return _unitFloors['name:$name'];
    }
    return null;
  }

  String _floorLabel(int? floor) {
    if (floor == null) return _isSw ? 'Bila ghorofa' : 'No floor';
    if (PropertyUnitFloor.indices.contains(floor)) {
      return PropertyUnitFloor.label(appLocalization, floor);
    }
    return _isSw ? 'Ghorofa $floor' : 'Floor $floor';
  }

  void selectUnit(String key) {
    selectedUnitKey.value = key;
    rebuildRows();
  }

  void selectTab(ApartmentReportTab tab) {
    selectedTab.value = tab;
  }

  List<TenantRecord> get _filteredTenants {
    final key = selectedUnitKey.value;
    if (key == allUnitsKey) return _tenants;
    return _tenants.where((t) {
      final id = t.apartmentUnitId.trim();
      final label = t.unitLabel.trim();
      if (key == id) return true;
      if (key == 'label:$label') return true;
      if (label.isNotEmpty && key.toLowerCase() == label.toLowerCase()) {
        return true;
      }
      return false;
    }).toList();
  }

  void rebuildRows() {
    final currency = Get.find<CurrencyService>();
    final tenants = _filteredTenants;
    final rent = <ApartmentRentReportRow>[];
    final service = <ApartmentServiceChargeReportRow>[];

    for (final t in tenants) {
      final apt = _aptNo(t);
      final matching = _incomes
          .where((r) => TenantLedgerFinance.incomeMatchesTenant(r, t))
          .toList();
      final rentPayments = matching.where(_isRentIncome).toList();
      final scPayments = matching.where(_isServiceChargeIncome).toList();

      final paid = rentPayments.fold<double>(0, (a, b) => a + b.amountValue);
      final due = TenantLedgerFinance.totalDueTsh(t).toDouble();
      final balance = (due - paid).clamp(0, due);
      final monthly = _monthlyRent(t);
      final periodMonths = TenantLedgerFinance.leaseDurationUnits(t);
      final latestPaid = rentPayments.isEmpty
          ? null
          : rentPayments
              .map((e) => e.paidLocalCalendarOrCreated())
              .reduce((a, b) => a.isAfter(b) ? a : b);
      final status = balance <= 0 && due > 0
          ? 'PAID'
          : (paid <= 0 ? 'NOT PAID' : 'PARTIAL');
      final recipient = _recipientFor(rentPayments) ??
          (_defaultRecipient.trim().isEmpty ? '—' : _defaultRecipient.trim());

      if (t.isActiveTenancy) {
        final floor = _floorForTenant(t);
        rent.add(
          ApartmentRentReportRow(
            date: _date.format(latestPaid ?? DateTime.now()),
            name: t.tenantName.trim().isEmpty ? '—' : t.tenantName.trim(),
            aptNo: apt,
            floorLabel: _floorLabel(floor),
            floorIndex: floor,
            rentPerMonth: currency.formatBase(monthly.round()),
            rentSixMonth: currency.formatBase((monthly * 6).round()),
            rentPeriod: '$periodMonths',
            amtPaid: currency.formatBase(paid.round()),
            balance: currency.formatBase(balance.round()),
            startDate: _fmtIso(t.leaseStartIso),
            expiryDate: _fmtIso(t.leaseEndIso),
            recipient: recipient,
            status: status,
            contractRemarks: _contractRemarks(t, status),
          ),
        );
      }

      for (final p in scPayments) {
        final paidAt = p.paidLocalCalendarOrCreated();
        service.add(
          ApartmentServiceChargeReportRow(
            name: t.tenantName.trim().isEmpty
                ? (p.tenantName.trim().isEmpty ? '—' : p.tenantName.trim())
                : t.tenantName.trim(),
            month: _month.format(paidAt),
            amount: currency.formatBase(p.amountValue.round()),
            aptNo: apt,
            datePaid: _date.format(paidAt),
          ),
        );
      }
    }

    // Service charge incomes that match unit/property but not a tenant row.
    if (selectedUnitKey.value != allUnitsKey || tenants.isEmpty) {
      for (final p in _incomes.where(_isServiceChargeIncome)) {
        if (!_incomeMatchesScope(p)) continue;
        final already = service.any(
          (r) =>
              r.datePaid == _date.format(p.paidLocalCalendarOrCreated()) &&
              r.amount ==
                  Get.find<CurrencyService>()
                      .formatBase(p.amountValue.round()) &&
              r.name.toLowerCase() == p.tenantName.trim().toLowerCase(),
        );
        if (already) continue;
        final paidAt = p.paidLocalCalendarOrCreated();
        service.add(
          ApartmentServiceChargeReportRow(
            name: p.tenantName.trim().isEmpty ? '—' : p.tenantName.trim(),
            month: _month.format(paidAt),
            amount: Get.find<CurrencyService>()
                .formatBase(p.amountValue.round()),
            aptNo: p.apartmentUnit.trim().isEmpty
                ? (selectedUnitKey.value == allUnitsKey
                    ? '—'
                    : unitFilterLabel)
                : p.apartmentUnit.trim(),
            datePaid: _date.format(paidAt),
          ),
        );
      }
    }

    service.sort((a, b) => b.datePaid.compareTo(a.datePaid));
    rent.sort((a, b) {
      final af = a.floorIndex ?? 1 << 20;
      final bf = b.floorIndex ?? 1 << 20;
      final byFloor = af.compareTo(bf);
      if (byFloor != 0) return byFloor;
      final byApt = a.aptNo.toLowerCase().compareTo(b.aptNo.toLowerCase());
      if (byApt != 0) return byApt;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    rentRows.assignAll(rent);
    serviceChargeRows.assignAll(service);
  }

  bool _incomeMatchesScope(IncomeRecord r) {
    final ref = propertyRef.value.trim();
    if (ref.isNotEmpty &&
        r.propertyRef.trim().isNotEmpty &&
        r.propertyRef.trim() != ref) {
      return false;
    }
    final key = selectedUnitKey.value;
    if (key == allUnitsKey) {
      final title = propertyTitle.value.trim().toLowerCase();
      if (title.isEmpty) return true;
      final blob =
          '${r.apartment} ${r.apartmentUnit} ${r.notes}'.toLowerCase();
      return blob.contains(title) ||
          r.propertyRef.trim() == ref ||
          ref.isEmpty;
    }
    final unit = r.apartmentUnit.trim().toLowerCase();
    final label = unitFilterLabel.trim().toLowerCase();
    return unit == key.toLowerCase() ||
        unit == label ||
        r.notes.toLowerCase().contains(label);
  }

  static bool _isServiceChargeIncome(IncomeRecord r) {
    final c = r.category.trim().toLowerCase();
    return c == 'service charge' || c.contains('service charge');
  }

  static bool _isRentIncome(IncomeRecord r) {
    if (_isServiceChargeIncome(r)) return false;
    final c = r.category.trim().toLowerCase();
    return c.isEmpty ||
        c == 'lease' ||
        c == 'rent' ||
        c.contains('rent') ||
        c == 'other';
  }

  String _aptNo(TenantRecord t) {
    final label = t.unitLabel.trim();
    if (label.isNotEmpty) return label;
    final id = t.apartmentUnitId.trim();
    if (id.isNotEmpty) return id;
    return '—';
  }

  double _monthlyRent(TenantRecord t) {
    final amount = t.rentAmountValue;
    final freq = t.rentFrequency.trim().toLowerCase();
    switch (freq) {
      case 'per day':
      case 'per night':
        return amount * 30;
      case 'per week':
        return amount * 4.345;
      case 'per year':
        return amount / 12;
      case 'per stay':
        final months = TenantLedgerFinance.leaseDurationUnits(t).clamp(1, 1200);
        return amount / months;
      case 'per month':
      default:
        return amount;
    }
  }

  String _fmtIso(String iso) {
    final d = TenantLedgerFinance.parseIsoDate(iso);
    if (d == null) return '—';
    return _date.format(d);
  }

  String _contractRemarks(TenantRecord t, String status) {
    final hasContract = t.contractFilePath.trim().isNotEmpty ||
        t.contractFileName.trim().isNotEmpty;
    final contractBit = hasContract
        ? (t.contractFileName.trim().isNotEmpty
            ? 'Contract: ${t.contractFileName.trim()}'
            : 'Contract: YES')
        : 'Contract: NO';
    final period = TenantLedgerFinance.leaseDurationUnits(t);
    final payBit = status == 'PAID'
        ? '$period months period paid fully'
        : (status == 'PARTIAL' ? 'Partial payment' : 'Not paid');
    return '$contractBit · $payBit';
  }

  String? _recipientFor(List<IncomeRecord> payments) {
    for (final p in payments) {
      final fromNotes = _parseRecipient(p.notes);
      if (fromNotes != null) return fromNotes;
    }
    return null;
  }

  static String? _parseRecipient(String notes) {
    final lines = notes.split('\n');
    for (final line in lines) {
      final t = line.trim();
      final lower = t.toLowerCase();
      for (final prefix in ['recipient:', 'receipient:', 'received by:']) {
        if (lower.startsWith(prefix)) {
          final v = t.substring(prefix.length).trim();
          if (v.isNotEmpty) return v;
        }
      }
    }
    return null;
  }

  Future<void> generatePdf() async {
    if (exporting.value) return;
    exporting.value = true;
    try {
      rebuildRows();
      if (selectedTab.value == ApartmentReportTab.rent) {
        if (rentRows.isEmpty) {
          showErrorMessage(
            _isSw
                ? 'Hakuna data ya ripoti ya kodi kwa chumba hiki.'
                : 'No rent report data for this apartment.',
          );
          return;
        }
        await ApartmentReportPdf.shareRentReport(
          propertyTitle: propertyTitle.value.isEmpty
              ? 'Property'
              : propertyTitle.value,
          unitFilterLabel: unitFilterLabel,
          rows: rentRows.toList(),
        );
      } else {
        if (serviceChargeRows.isEmpty) {
          showErrorMessage(
            _isSw
                ? 'Hakuna malipo ya tozo ya huduma kwa chumba hiki.'
                : 'No service charge payments for this apartment.',
          );
          return;
        }
        await ApartmentReportPdf.shareServiceChargeReport(
          propertyTitle: propertyTitle.value.isEmpty
              ? 'Property'
              : propertyTitle.value,
          unitFilterLabel: unitFilterLabel,
          rows: serviceChargeRows.toList(),
        );
      }
      analytics?.logReportExported(
        format: 'pdf',
        reportType: selectedTab.value == ApartmentReportTab.rent
            ? 'apartment_rent'
            : 'apartment_service_charge',
        module: 'rent',
      );
      showSuccessMessage(
        _isSw ? 'Ripoti ya PDF iko tayari.' : 'PDF report ready.',
      );
    } catch (e) {
      showErrorMessage(
        _isSw ? 'Imeshindikana kutengeneza PDF.' : 'Failed to generate PDF.',
      );
    } finally {
      exporting.value = false;
    }
  }
}

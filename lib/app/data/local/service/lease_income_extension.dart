import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../db/income_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import '../preference/preference_manager.dart';
import '../../../modules/rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';
import 'currency_service.dart';
import 'tenant_lease_remote_sync.dart';

/// Applies lease income that was saved before payments extended the tenancy.
///
/// A payment counts when it was recorded after the lease end, or its paid
/// date is after that end. Payments already applied are skipped, so opening
/// Home again does not add the same months twice.
class LeaseIncomeExtension {
  LeaseIncomeExtension._();

  static Future<void> _tail = Future<void>.value();

  static Future<void> applyMissed() {
    return _sync(_applyMissed);
  }

  static Future<void> markApplied(int incomeId) {
    if (incomeId <= 0) return Future<void>.value();
    return _sync(() async {
      final prefs = _prefs();
      final applied = await _appliedIds(prefs);
      if (applied.add(incomeId)) {
        await _saveAppliedIds(prefs, applied);
      }
    });
  }

  static Future<T> _sync<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  static PreferenceManager _prefs() =>
      Get.find<PreferenceManager>(tag: (PreferenceManager).toString());

  static Future<void> _applyMissed() async {
    if (!Get.isRegistered<TenantLocalDataSource>() ||
        !Get.isRegistered<IncomeLocalDataSource>() ||
        !Get.isRegistered<PropertyLocalDataSource>()) {
      return;
    }
    final prefs = _prefs();
    final applied = await _appliedIds(prefs);
    final tenants = Get.find<TenantLocalDataSource>();
    final incomeLocal = Get.find<IncomeLocalDataSource>();
    final properties = await _visibleProperties();
    if (properties.isEmpty) return;

    final incomeRows = await incomeLocal.getAllNewestFirst();
    final seenTenants = <int>{};
    var changed = false;

    for (final property in properties) {
      final key = property.propertyRef.trim().isNotEmpty
          ? property.propertyRef.trim()
          : 'local_${property.id}';
      final propertyTenants = await tenants.listByPropertyRef(key);
      for (final tenant in propertyTenants) {
        if (!seenTenants.add(tenant.id)) continue;
        final end = _parseDay(tenant.leaseEndIso);
        if (end == null) continue;
        final rate = _periodicRent(tenant, property);
        if (rate == null || rate.amount <= 0) continue;

        final missed = <IncomeRecord>[];
        for (final row in incomeRows) {
          if (applied.contains(row.id)) continue;
          if (!_isLeaseIncome(row.category)) continue;
          if (!_incomeMatches(row, tenant, property)) continue;
          if (!_isAfterLeaseEnd(row, end)) continue;
          missed.add(row);
        }
        if (missed.isEmpty) continue;

        var periods = 0;
        for (final row in missed) {
          final paidAmount = row.inputAmountValue > 0
              ? row.inputAmountValue
              : row.amountValue;
          periods += _periodsFor(
            paidAmount: paidAmount,
            paidCurrency: row.currencyCode,
            rentAmount: rate.amount,
            rentCurrency: rate.currency,
          );
        }
        if (periods <= 0) continue;

        final nextEnd = _advance(end, rate.frequency, periods);
        final nextEndIso = DateFormat('yyyy-MM-dd').format(nextEnd);
        await tenants.updateLeaseTerms(
          id: tenant.id,
          rentAmountValue: tenant.rentAmountValue,
          leaseStartIso: tenant.leaseStartIso,
          leaseEndIso: nextEndIso,
        );
        await TenantLeaseRemoteSync.push(
          tenant: tenant,
          leaseEndIso: nextEndIso,
        );
        for (final row in missed) {
          applied.add(row.id);
        }
        changed = true;
      }
    }

    if (changed) {
      await _saveAppliedIds(prefs, applied);
    }
  }

  static bool _incomeMatches(
    IncomeRecord row,
    TenantRecord tenant,
    PropertyRecord property,
  ) {
    if (TenantLedgerFinance.incomeMatchesTenant(row, tenant)) return true;
    final refs = <String>{
      if (property.propertyRef.trim().isNotEmpty) property.propertyRef.trim(),
      'local_${property.id}',
      'legacy_${property.id}',
    };
    final incomeRef = row.propertyRef.trim();
    if (incomeRef.isNotEmpty && !refs.contains(incomeRef)) return false;
    final name = tenant.tenantName.trim().toLowerCase();
    if (name.isNotEmpty && row.tenantName.trim().toLowerCase() == name) {
      return true;
    }
    final unit = tenant.unitLabel.trim().toLowerCase();
    final incomeUnit = row.apartmentUnit.trim().toLowerCase();
    return unit.isNotEmpty && incomeUnit.isNotEmpty && incomeUnit == unit;
  }

  static bool _isLeaseIncome(String category) {
    final value = category.trim().toLowerCase();
    return value == 'lease' || value == 'rent';
  }

  static bool _isAfterLeaseEnd(IncomeRecord row, DateTime leaseEnd) {
    final paid = row.paidLocalCalendarOrCreated();
    final paidDay = DateTime(paid.year, paid.month, paid.day);
    if (paidDay.isAfter(leaseEnd)) return true;
    if (row.createdAtMs <= 0) return false;
    final created = DateTime.fromMillisecondsSinceEpoch(row.createdAtMs);
    final createdDay = DateTime(created.year, created.month, created.day);
    return createdDay.isAfter(leaseEnd);
  }

  static Future<List<PropertyRecord>> _visibleProperties() async {
    final prefs = _prefs();
    var userId = '';
    try {
      userId = (await prefs.getUser()).id?.trim() ?? '';
    } catch (_) {}
    final local = Get.find<PropertyLocalDataSource>();
    final byId = <int, PropertyRecord>{};
    for (final workspace in const ['bnb', 'rent']) {
      final rows = await local.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: workspace,
      );
      for (final row in rows) {
        byId[row.id] = row;
      }
    }
    return byId.values.toList();
  }

  static ({double amount, String frequency, String currency})? _periodicRent(
    TenantRecord tenant,
    PropertyRecord property,
  ) {
    final freq = tenant.rentFrequency.trim();
    if (_isRepeating(freq) && tenant.rentAmountValue > 0) {
      return (
        amount: tenant.rentAmountValue,
        frequency: freq,
        currency: tenant.rentCurrency,
      );
    }
    final unit = _unitRent(tenant, property);
    if (unit == null) return null;
    return unit;
  }

  static ({double amount, String frequency, String currency})? _unitRent(
    TenantRecord tenant,
    PropertyRecord property,
  ) {
    final raw = property.unitsJson.trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      for (final entry in decoded.whereType<Map>()) {
        final unitId = (entry['unitId'] ?? entry['id'] ?? '').toString().trim();
        final unitName =
            (entry['unitName'] ?? entry['name'] ?? '').toString().trim();
        final tenantUnitId = tenant.apartmentUnitId.trim();
        final tenantUnitName = tenant.unitLabel.trim();
        final idMatches = tenantUnitId.isNotEmpty &&
            unitId.isNotEmpty &&
            tenantUnitId == unitId;
        final nameMatches = tenantUnitName.isNotEmpty &&
            unitName.isNotEmpty &&
            tenantUnitName.toLowerCase() == unitName.toLowerCase();
        if (!idMatches && !nameMatches) continue;
        final amount = double.tryParse(
          (entry['unitRent'] ?? entry['rent'] ?? '')
              .toString()
              .replaceAll(',', '')
              .trim(),
        );
        final frequency =
            (entry['unitRentFrequency'] ?? entry['rentFrequency'] ?? '')
                .toString()
                .trim();
        if (amount == null || amount <= 0 || !_isRepeating(frequency)) {
          continue;
        }
        final currency =
            (entry['unitRentCurrency'] ?? entry['rentCurrency'] ?? 'TZS')
                .toString()
                .trim();
        return (
          amount: amount,
          frequency: frequency,
          currency: currency.isEmpty ? 'TZS' : currency,
        );
      }
    } catch (_) {}
    return null;
  }

  static bool _isRepeating(String frequency) {
    final value = frequency.trim().toLowerCase();
    return value.contains('month') ||
        value.contains('week') ||
        value.contains('year') ||
        value.contains('day') ||
        value.contains('night');
  }

  static int _periodsFor({
    required double paidAmount,
    required String paidCurrency,
    required double rentAmount,
    required String rentCurrency,
  }) {
    if (rentAmount <= 0 || paidAmount <= 0) return 0;
    final paid = paidCurrency.trim().toUpperCase();
    final rent = rentCurrency.trim().toUpperCase();
    final ratio = paid.isEmpty || rent.isEmpty || paid == rent
        ? paidAmount / rentAmount
        : _baseRatio(paidAmount, paid, rentAmount, rent);
    if (ratio <= 0) return 0;
    return ratio.floor();
  }

  static double _baseRatio(
    double paidAmount,
    String paidCurrency,
    double rentAmount,
    String rentCurrency,
  ) {
    if (!Get.isRegistered<CurrencyService>()) return 0;
    final cs = Get.find<CurrencyService>();
    final paidBase = cs.toBaseAmount(
      inputAmount: paidAmount,
      inputCurrency: paidCurrency,
    );
    final rentBase = cs.toBaseAmount(
      inputAmount: rentAmount,
      inputCurrency: rentCurrency,
    );
    if (rentBase <= 0) return 0;
    return paidBase / rentBase;
  }

  static DateTime? _parseDay(String raw) {
    final text = raw.trim();
    if (text.length < 10) return null;
    final year = int.tryParse(text.substring(0, 4));
    final month = int.tryParse(text.substring(5, 7));
    final day = int.tryParse(text.substring(8, 10));
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  static DateTime _advance(DateTime base, String frequency, int units) {
    switch (frequency.trim().toLowerCase()) {
      case 'per day':
      case 'per night':
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

  static Future<Set<int>> _appliedIds(PreferenceManager prefs) async {
    final userId = await _userId(prefs);
    final raw = await prefs.getString(
      _keyForUser(userId),
      defaultValue: '',
    );
    if (raw.trim().isEmpty) return <int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <int>{};
      return decoded.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id > 0).toSet();
    } catch (_) {
      return <int>{};
    }
  }

  static Future<void> _saveAppliedIds(
    PreferenceManager prefs,
    Set<int> ids,
  ) async {
    final userId = await _userId(prefs);
    await prefs.setString(
      _keyForUser(userId),
      jsonEncode(ids.toList()..sort()),
    );
  }

  static Future<String> _userId(PreferenceManager prefs) async {
    try {
      return (await prefs.getUser()).id?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static String _keyForUser(String userId) =>
      '${PreferenceManager.keyLeaseExtensionAppliedIncome}_$userId';
}

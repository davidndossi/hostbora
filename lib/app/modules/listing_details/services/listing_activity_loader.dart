import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../models/listing_activity_vm.dart';

/// Property context used to filter income, expense, and maintenance into activity rows.
class ListingActivityScope {
  const ListingActivityScope({
    required this.propertyId,
    required this.propertyName,
    required this.propertyLocation,
    required this.isSw,
  });

  final String propertyId;
  final String propertyName;
  final String propertyLocation;
  final bool isSw;

  factory ListingActivityScope.fromRoute() {
    var propertyId = '';
    var propertyName = '';
    var propertyLocation = '';
    final args = Get.arguments;
    if (args is Map) {
      propertyId = (args['property_id'] ?? args['id'] ?? args['propertyRef'] ?? '')
          .toString()
          .trim();
      propertyName =
          (args['property_name'] ?? args['property'] ?? '').toString().trim();
      propertyLocation = (args['property_location'] ?? '').toString().trim();
    }
    if (propertyId.isEmpty) {
      propertyId = Get.parameters['id']?.trim() ?? '';
    }
    if (propertyName.isEmpty) {
      propertyName = Get.parameters['title']?.trim() ?? '';
    }
    return ListingActivityScope(
      propertyId: propertyId,
      propertyName: propertyName,
      propertyLocation: propertyLocation,
      isSw: Get.locale?.languageCode == 'sw',
    );
  }
}

class ListingActivityLoader {
  ListingActivityLoader({
    PropertyLocalDataSource? propertyLocal,
    IncomeLocalDataSource? incomeLocal,
    ExpenseLocalDataSource? expenseLocal,
    RentScheduledMaintenanceLocalDataSource? maintenanceLocal,
  })  : _propertyLocal = propertyLocal ?? Get.find<PropertyLocalDataSource>(),
        _incomeLocal = incomeLocal ?? Get.find<IncomeLocalDataSource>(),
        _expenseLocal = expenseLocal ?? Get.find<ExpenseLocalDataSource>(),
        _maintenanceLocal =
            maintenanceLocal ?? Get.find<RentScheduledMaintenanceLocalDataSource>();

  final PropertyLocalDataSource _propertyLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;

  Future<List<ListingActivityVm>> load({
    required ListingActivityScope scope,
    int? limit,
  }) async {
    final scopeRefs = await _listingPropertyRefs(scope);
    final candidates = <({int ts, ListingActivityVm vm})>[];

    try {
      final maintenanceRows = await _maintenanceLocal.getAllNewestFirst();
      for (final r in maintenanceRows) {
        if (!_maintenanceMatchesListing(r, scope, scopeRefs)) continue;
        DateTime? scheduled;
        try {
          scheduled = DateTime.parse(r.scheduledDateIso.trim());
        } catch (_) {
          scheduled = null;
        }
        final scheduledLabel = scheduled != null
            ? DateFormat('MMM d, yyyy').format(scheduled)
            : '—';
        final cat = r.category.trim();
        final desc = r.description.trim();
        final subtitle = desc.isEmpty
            ? cat
            : (desc.length > 72 ? '${desc.substring(0, 69)}…' : '$cat · $desc');
        candidates.add((
          ts: r.createdAtMs,
          vm: ListingActivityVm(
            title: scope.isSw ? 'Matengenezo yalipangwa' : 'Maintenance scheduled',
            subtitle: subtitle,
            trailing: scheduledLabel,
            timeLabel: _relativeDateFromMs(scope, r.createdAtMs),
            accentColor: const Color(0xFF6366F1),
          ),
        ));
      }
    } catch (_) {}

    final incomes = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    final expenses = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');

    for (final i in incomes) {
      if (!_rowMatchesListingScope(
        scope: scope,
        scopeRefs: scopeRefs,
        propertyRef: i.propertyRef,
        apartment: i.apartment,
        apartmentUnit: i.apartmentUnit,
        notes: i.notes,
      )) {
        continue;
      }
      candidates.add((
        ts: i.paidLocalCalendarOrCreated().millisecondsSinceEpoch,
        vm: ListingActivityVm(
          title: scope.isSw ? 'Malipo yamepokelewa' : 'Payment received',
          subtitle: i.notes.isEmpty ? i.category : i.notes,
          trailing: '+ ${Get.find<CurrencyService>().formatBase(i.amountValue.round())}',
          timeLabel: _relativeDate(scope, i.datePaidIso, i.createdAtMs),
          accentColor: const Color(0xFF0EA5A4),
        ),
      ));
    }
    for (final e in expenses) {
      if (!_rowMatchesListingScope(
        scope: scope,
        scopeRefs: scopeRefs,
        propertyRef: '',
        apartment: e.apartment,
        apartmentUnit: e.apartmentUnit,
        notes: e.notes,
      )) {
        continue;
      }
      candidates.add((
        ts: e.paidLocalCalendarOrCreated().millisecondsSinceEpoch,
        vm: ListingActivityVm(
          title: scope.isSw ? 'Gharama imerekodiwa' : 'Expense logged',
          subtitle: e.notes.isEmpty ? e.category : e.notes,
          trailing: Get.find<CurrencyService>().formatBase(e.amountValue.round()),
          timeLabel: _relativeDate(scope, e.datePaidIso, e.createdAtMs),
          accentColor: const Color(0xFFF59E0B),
          expenseId: e.id,
        ),
      ));
    }

    candidates.sort((a, b) => b.ts.compareTo(a.ts));
    final rows = candidates.map((e) => e.vm).toList();
    if (limit != null && limit > 0 && rows.length > limit) {
      return rows.take(limit).toList();
    }
    return rows;
  }

  Future<Set<String>> _listingPropertyRefs(ListingActivityScope scope) async {
    final refs = <String>{};
    if (scope.propertyId.isNotEmpty) refs.add(scope.propertyId);
    final row = await _findLocalPropertyRow(scope);
    if (row != null) {
      if (row.propertyRef.trim().isNotEmpty) refs.add(row.propertyRef.trim());
      refs.add('local_${row.id}');
      refs.add('legacy_${row.id}');
    }
    return refs;
  }

  Future<PropertyRecord?> _findLocalPropertyRow(ListingActivityScope scope) async {
    try {
      final rows = await _propertyLocal.getAllNewestFirst();
      if (rows.isEmpty) return null;
      PropertyRecord? target;
      if (scope.propertyId.isNotEmpty) {
        for (final r in rows) {
          final localId = 'local_${r.id}';
          final legacyId = 'legacy_${r.id}';
          if (r.propertyRef.trim() == scope.propertyId ||
              localId == scope.propertyId ||
              legacyId == scope.propertyId) {
            target = r;
            break;
          }
        }
      }
      target ??= rows.firstWhereOrNull(
        (r) =>
            scope.propertyName.isNotEmpty &&
            r.apartmentSuite.trim() == scope.propertyName,
      );
      target ??= rows.firstWhereOrNull(
        (r) =>
            scope.propertyName.isNotEmpty &&
            r.propertyLocation.trim() == scope.propertyName,
      );
      return target;
    } catch (_) {
      return null;
    }
  }

  bool _rowMatchesListingScope({
    required ListingActivityScope scope,
    required Set<String> scopeRefs,
    required String propertyRef,
    required String apartment,
    required String apartmentUnit,
    required String notes,
  }) {
    final pr = propertyRef.trim();
    if (pr.isNotEmpty && scopeRefs.isNotEmpty && scopeRefs.contains(pr)) {
      return true;
    }
    final apt = apartment.trim().toLowerCase();
    final unit = apartmentUnit.trim().toLowerCase();
    final notesLc = notes.trim().toLowerCase();
    final name = scope.propertyName.toLowerCase();
    final loc = scope.propertyLocation.toLowerCase();
    if (name.isEmpty && loc.isEmpty) {
      return false;
    }
    if (name.isNotEmpty &&
        (apt.contains(name) || unit.contains(name) || notesLc.contains(name))) {
      return true;
    }
    if (loc.isNotEmpty &&
        (apt.contains(loc) || unit.contains(loc) || notesLc.contains(loc))) {
      return true;
    }
    return false;
  }

  bool _maintenanceMatchesListing(
    RentScheduledMaintenanceRecord r,
    ListingActivityScope scope,
    Set<String> scopeRefs,
  ) {
    final pref = r.propertyRef.trim();
    if (pref.isNotEmpty && scopeRefs.contains(pref)) return true;
    final label = r.propertyLabel.trim().toLowerCase();
    if (label.isEmpty) return false;
    final nameLc = scope.propertyName.toLowerCase();
    final locLc = scope.propertyLocation.toLowerCase();
    if (nameLc.isNotEmpty &&
        (label == nameLc || label.contains(nameLc) || nameLc.contains(label))) {
      return true;
    }
    if (locLc.isNotEmpty &&
        (label == locLc || label.contains(locLc) || locLc.contains(label))) {
      return true;
    }
    return false;
  }

  String _relativeDate(ListingActivityScope scope, String iso, int ms) {
    DateTime d;
    try {
      d = DateTime.parse(iso);
    } catch (_) {
      d = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    final day = DateTime(d.year, d.month, d.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return scope.isSw ? 'Leo' : 'Today';
    if (day == today.subtract(const Duration(days: 1))) {
      return scope.isSw ? 'Jana' : 'Yesterday';
    }
    return DateFormat('MMM d').format(day);
  }

  String _relativeDateFromMs(ListingActivityScope scope, int ms) {
    final iso = DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String();
    return _relativeDate(scope, iso, ms);
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/repository/app_repository.dart';

/// Period preset for BnB reports (local calendar).
enum ReportsPeriodKind { weekly, monthly, yearly, custom }

class _DateBucket {
  _DateBucket({
    required this.startInclusive,
    required this.endInclusive,
    required this.label,
  });

  final DateTime startInclusive;
  final DateTime endInclusive;
  final String label;
}

/// BnB host reports: occupancy, financials, expenses with exports.
///
/// **Occupancy** matches the host dashboard: each calendar day counts
/// overlapping stays on `[checkIn, checkOut)` (checkout excluded); inactive
/// (checked-out / cancelled) bookings are ignored; occupancy % is
/// `occupiedBookings / totalBnbUnits * 100` capped at 100.
class ReportsController extends BaseController with GetTickerProviderStateMixin {
  ReportsController()
      : _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _expenseLocal = Get.find<ExpenseLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final PropertyLocalDataSource _propertyLocal;
  final AppRepository _repository;
  final PendingBookingsStore _pendingBookings = PendingBookingsStore();
  late final BnbBookingMerge _merge =
      BnbBookingMerge(pending: _pendingBookings);

  late TabController tabController;

  final periodKind = ReportsPeriodKind.weekly.obs;
  final customStart = Rxn<DateTime>();
  final customEnd = Rxn<DateTime>();

  final rangeStart = DateTime.now().obs;
  final rangeEnd = DateTime.now().obs;

  final bnbProperties = <PropertyRecord>[].obs;
  /// `null` = all properties.
  final selectedPropertyRef = Rxn<String>();

  final isLoading = false.obs;

  final bucketLabels = <String>[].obs;
  final occupancyPct = <double>[].obs;
  final revenuePerBucket = <double>[].obs;
  final expensePerBucket = <double>[].obs;
  final expenseCategoryLabels = <String>[].obs;
  final expenseCategoryAmounts = <double>[].obs;

  List<CheckInItem> _mergedBookings = const [];
  List<IncomeRecord> _bnbIncomes = const [];
  List<ExpenseRecord> _bnbExpenses = const [];
  int _allBnbUnits = 0;

  static final _money = NumberFormat('#,###', 'en_US');
  static final _month = DateFormat('MMM yyyy');
  static final _day = DateFormat('MMM d');

  @override
  void onInit() {
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_onTabChanged);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    customStart.value ??= today.subtract(const Duration(days: 30));
    customEnd.value ??= today;
    super.onInit();
    _recomputeCalendarRange();
    refreshAll();
  }

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      update(['reports_tabs']);
    }
  }

  @override
  void onClose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    super.onClose();
  }

  void goBack() => Get.back();

  void setPeriod(ReportsPeriodKind k) {
    periodKind.value = k;
    _recomputeCalendarRange();
    refreshAll();
  }

  void _recomputeCalendarRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (periodKind.value) {
      case ReportsPeriodKind.weekly:
        final monday = today.subtract(Duration(days: today.weekday - DateTime.monday));
        rangeStart.value = monday;
        rangeEnd.value = monday.add(const Duration(days: 6));
        break;
      case ReportsPeriodKind.monthly:
        rangeStart.value = DateTime(now.year, now.month, 1);
        rangeEnd.value = DateTime(now.year, now.month + 1, 0);
        break;
      case ReportsPeriodKind.yearly:
        rangeStart.value = DateTime(now.year, 1, 1);
        rangeEnd.value = DateTime(now.year, 12, 31);
        break;
      case ReportsPeriodKind.custom:
        var a = _dateOnly(customStart.value ?? today.subtract(const Duration(days: 30)));
        var b = _dateOnly(customEnd.value ?? today);
        if (a.isAfter(b)) {
          final t = a;
          a = b;
          b = t;
        }
        rangeStart.value = a;
        rangeEnd.value = b;
        break;
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> pickCustomStart(BuildContext context) async {
    final initial = customStart.value ?? rangeStart.value;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      customStart.value = _dateOnly(d);
      if (customEnd.value != null &&
          customStart.value!.isAfter(customEnd.value!)) {
        showErrorMessage(appLocalization.reportsInvalidDateRange);
      }
      periodKind.value = ReportsPeriodKind.custom;
      _recomputeCalendarRange();
      refreshAll();
    }
  }

  Future<void> pickCustomEnd(BuildContext context) async {
    final initial = customEnd.value ?? rangeEnd.value;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      customEnd.value = _dateOnly(d);
      if (customStart.value != null &&
          customEnd.value!.isBefore(customStart.value!)) {
        showErrorMessage(appLocalization.reportsInvalidDateRange);
      }
      periodKind.value = ReportsPeriodKind.custom;
      _recomputeCalendarRange();
      refreshAll();
    }
  }

  void setPropertyFilter(String? propertyRef) {
    selectedPropertyRef.value = propertyRef;
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    try {
      await _loadProperties();
      await _loadBookingsAndUnits();
      await _loadIncomeExpense();
      _rebuildBucketsAndSeries();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadProperties() async {
    final rows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: '',
      workspaceType: 'bnb',
    );
    bnbProperties.assignAll(rows);
    final sel = selectedPropertyRef.value?.trim();
    if (sel != null && sel.isNotEmpty) {
      final ok = rows.any((p) => p.propertyRef.trim() == sel);
      if (!ok) selectedPropertyRef.value = null;
    }
  }

  Future<void> _loadBookingsAndUnits() async {
    final merged = <String, CheckInItem>{};
    try {
      final res = await _repository.getAllBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (res.responseCode == '0' && data is Map && data['bookings'] is List) {
        rows = data['bookings'] as List;
      } else if (res.responseCode == '0' && data is List) {
        rows = data;
      }
      for (final e in rows.whereType<Map>()) {
        final item = _merge.fromApiMap(Map<String, dynamic>.from(e));
        merged[item.bookingKey] = item;
      }
    } catch (_) {}

    try {
      final properties = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: 'bnb',
      );
      for (final m in _pendingBookings.load()) {
        final listingId = (m['listingId'] ?? '').toString().trim();
        final checkIn = (m['checkIn'] ?? '').toString();
        final checkOut = (m['checkOut'] ?? '').toString();
        if (listingId.isEmpty || checkIn.isEmpty || checkOut.isEmpty) {
          continue;
        }
        final property = properties.firstWhereOrNull(
          (p) =>
              p.propertyRef.trim() == listingId ||
              'local_${p.id}' == listingId,
        );
        final propertyLabel = property?.propertyName.trim().isNotEmpty == true
            ? property!.propertyName.trim()
            : (property?.propertyLocation ?? 'Property');
        final localId = 'local_${m['createdAt'] ?? '${listingId}_$checkIn'}';
        merged[localId] = _merge.fromPendingMap(
          m,
          propertyLabel: propertyLabel,
          localId: localId,
        );
      }

      var unitsTotal = 0;
      for (final p in properties) {
        unitsTotal += _bnbUnitCountForProperty(p);
      }
      _allBnbUnits = unitsTotal;
    } catch (_) {
      _allBnbUnits = 0;
    }

    _mergedBookings = merged.values.toList();
  }

  Future<void> _loadIncomeExpense() async {
    _bnbIncomes = await _incomeLocal.getAllNewestFirst(workspaceType: 'bnb');
    _bnbExpenses = await _expenseLocal.getAllNewestFirst(workspaceType: 'bnb');
  }

  int _unitsForFilter() {
    final ref = selectedPropertyRef.value?.trim();
    if (ref == null || ref.isEmpty) return _allBnbUnits;
    final p = bnbProperties.firstWhereOrNull((x) => x.propertyRef.trim() == ref);
    if (p == null) return _allBnbUnits;
    return _bnbUnitCountForProperty(p);
  }

  Iterable<CheckInItem> _bookingsForFilter() {
    final ref = selectedPropertyRef.value?.trim();
    if (ref == null || ref.isEmpty) return _mergedBookings;
    final p = bnbProperties.firstWhereOrNull((x) => x.propertyRef.trim() == ref);
    if (p == null) return _mergedBookings;
    return _mergedBookings.where((b) => _bookingMatchesProperty(b, p));
  }

  static bool _bookingMatchesProperty(CheckInItem b, PropertyRecord p) {
    final lid = (b.listingId ?? '').trim();
    if (lid.isEmpty) return false;
    return lid == p.propertyRef.trim() || lid == 'local_${p.id}';
  }

  void _rebuildBucketsAndSeries() {
    final buckets = _buildBuckets(rangeStart.value, rangeEnd.value);
    bucketLabels.assignAll(buckets.map((e) => e.label));

    final units = _unitsForFilter();
    final bookings = _bookingsForFilter().toList();

    final occ = <double>[];
    for (final b in buckets) {
      occ.add(_occupancyForBucket(b, bookings, units));
    }
    occupancyPct.assignAll(occ);

    final rev = <double>[];
    final exp = <double>[];
    for (final b in buckets) {
      rev.add(_sumIncomeInBucket(b, _bnbIncomes));
      exp.add(_sumExpenseInBucket(b, _bnbExpenses));
    }
    revenuePerBucket.assignAll(rev);
    expensePerBucket.assignAll(exp);

    final byCat = <String, double>{};
    final rs = rangeStart.value;
    final re = rangeEnd.value;
    for (final row in _bnbExpenses) {
      final d = _parseExpenseDate(row);
      if (d.isBefore(rs) || d.isAfter(re)) continue;
      final key = row.category.trim().isEmpty ? 'Other' : row.category.trim();
      byCat[key] = (byCat[key] ?? 0) + row.amountValue;
    }
    final sorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    expenseCategoryLabels.assignAll(sorted.map((e) => e.key));
    expenseCategoryAmounts.assignAll(sorted.map((e) => e.value));
  }

  List<_DateBucket> _buildBuckets(DateTime start, DateTime end) {
    final a = _dateOnly(start);
    final b = _dateOnly(end);
    final days = b.difference(a).inDays + 1;
    if (days <= 31) {
      final out = <_DateBucket>[];
      for (var d = a; !d.isAfter(b); d = d.add(const Duration(days: 1))) {
        out.add(_DateBucket(
          startInclusive: d,
          endInclusive: d,
          label: _day.format(d),
        ));
      }
      return out;
    }
    if (days <= 150) {
      return _weekBuckets(a, b);
    }
    return _monthBuckets(a, b);
  }

  List<_DateBucket> _weekBuckets(DateTime rangeA, DateTime rangeB) {
    final out = <_DateBucket>[];
    var weekStart =
        rangeA.subtract(Duration(days: (rangeA.weekday - DateTime.monday) % 7));
    while (!weekStart.isAfter(rangeB)) {
      final segEnd = weekStart.add(const Duration(days: 6));
      final clipStart = weekStart.isBefore(rangeA) ? rangeA : weekStart;
      final clipEnd = segEnd.isAfter(rangeB) ? rangeB : segEnd;
      if (!clipStart.isAfter(clipEnd)) {
        out.add(
          _DateBucket(
            startInclusive: clipStart,
            endInclusive: clipEnd,
            label: '${_day.format(clipStart)} – ${_day.format(clipEnd)}',
          ),
        );
      }
      weekStart = weekStart.add(const Duration(days: 7));
    }
    return out;
  }

  List<_DateBucket> _monthBuckets(DateTime rangeA, DateTime rangeB) {
    final out = <_DateBucket>[];
    var cursor = DateTime(rangeA.year, rangeA.month, 1);
    while (!cursor.isAfter(rangeB)) {
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
      final clipStart = cursor.isBefore(rangeA) ? rangeA : cursor;
      final clipEnd = monthEnd.isAfter(rangeB) ? rangeB : monthEnd;
      if (!clipStart.isAfter(clipEnd)) {
        out.add(
          _DateBucket(
            startInclusive: clipStart,
            endInclusive: clipEnd,
            label: _month.format(cursor),
          ),
        );
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return out;
  }

  /// Same overlap rule as the host dashboard occupancy chart.
  static bool _bookingOccupiesCalendarDay(CheckInItem item, DateTime day) {
    if (item.isInactive) return false;
    final ci = _parseCalendarDay(item.checkInIso);
    final co = _parseCalendarDay(item.checkOutIso);
    if (ci == null || co == null) return false;
    return !day.isBefore(ci) && day.isBefore(co);
  }

  static DateTime? _parseCalendarDay(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.length >= 10 && t[4] == '-' && t[7] == '-') {
      final y = int.tryParse(t.substring(0, 4));
      final m = int.tryParse(t.substring(5, 7));
      final d = int.tryParse(t.substring(8, 10));
      if (y != null &&
          m != null &&
          d != null &&
          m >= 1 &&
          m <= 12 &&
          d >= 1 &&
          d <= 31) {
        return DateTime(y, m, d);
      }
    }
    final p = DateTime.tryParse(t);
    if (p == null) return null;
    return DateTime(p.year, p.month, p.day);
  }

  double _occupancyForBucket(
    _DateBucket bucket,
    List<CheckInItem> bookings,
    int units,
  ) {
    if (units <= 0) return 0;
    var sum = 0.0;
    var n = 0;
    for (var d = bucket.startInclusive;
        !d.isAfter(bucket.endInclusive);
        d = d.add(const Duration(days: 1))) {
      var occ = 0;
      for (final b in bookings) {
        if (_bookingOccupiesCalendarDay(b, d)) occ++;
      }
      sum += ((occ / units) * 100).clamp(0.0, 100.0);
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }

  double _sumIncomeInBucket(_DateBucket bucket, List<IncomeRecord> rows) {
    var s = 0.0;
    for (final r in rows) {
      final d = r.paidLocalCalendarOrCreated();
      if (!_dayInRange(d, bucket.startInclusive, bucket.endInclusive)) continue;
      s += r.amountValue;
    }
    return s;
  }

  double _sumExpenseInBucket(_DateBucket bucket, List<ExpenseRecord> rows) {
    var s = 0.0;
    for (final r in rows) {
      final d = _parseExpenseDate(r);
      if (!_dayInRange(d, bucket.startInclusive, bucket.endInclusive)) continue;
      s += r.amountValue;
    }
    return s;
  }

  static bool _dayInRange(DateTime d, DateTime start, DateTime end) {
    final day = _dateOnly(d);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static DateTime _parseExpenseDate(ExpenseRecord r) {
    final iso = r.datePaidIso.trim();
    if (iso.length >= 10 && iso[4] == '-' && iso[7] == '-') {
      final y = int.tryParse(iso.substring(0, 4));
      final m = int.tryParse(iso.substring(5, 7));
      final d = int.tryParse(iso.substring(8, 10));
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    try {
      return _dateOnly(DateTime.parse(iso));
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(r.createdAtMs);
    }
  }

  static int _bnbUnitCountForProperty(PropertyRecord p) {
    final raw = p.unitsJson.trim();
    if (raw.isNotEmpty && raw != '[]') {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) return decoded.length;
      } catch (_) {}
    }
    if (p.units > 0) return p.units;
    return 1;
  }

  // ——— Exports ———

  Future<void> exportPdf() async {
    final tab = tabController.index;
    final title = _exportTitle(tab);
    final rows = _exportRows(tab);
    final headers = rows.isEmpty ? <String>[] : rows.first.keys.toList();
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(28)),
        build: (ctx) => [
          pw.Header(level: 0, text: title),
          pw.Text(
            '${DateFormat.yMMMd().format(rangeStart.value)} – ${DateFormat.yMMMd().format(rangeEnd.value)}',
          ),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text(appLocalization.reportsNoData)
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows
                  .map((m) => headers.map((h) => m[h]?.toString() ?? '').toList())
                  .toList(),
            ),
        ],
      ),
    );
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: _fileBase(tab, 'pdf'));
    showSuccessMessage(appLocalization.reportsExportDone);
  }

  Future<void> exportCsv() async {
    final tab = tabController.index;
    final rows = _exportRows(tab);
    final buf = StringBuffer('\uFEFF');
    if (rows.isEmpty) {
      buf.writeln(appLocalization.reportsNoData);
    } else {
      final headers = rows.first.keys.toList();
      buf.writeln(headers.map(_csvEscape).join(','));
      for (final m in rows) {
        buf.writeln(headers.map((h) => _csvEscape('${m[h] ?? ''}')).join(','));
      }
    }
    final path = await _writeTemp(_fileBase(tab, 'csv'), buf.toString());
    await Share.shareXFiles([XFile(path, mimeType: 'text/csv')]);
    showSuccessMessage(appLocalization.reportsExportDone);
  }

  Future<void> exportExcel() async {
    final tab = tabController.index;
    final rows = _exportRows(tab);
    final excelLib = Excel.createExcel();
    final sheet = excelLib['Report'];
    if (rows.isEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
          TextCellValue(appLocalization.reportsNoData);
    } else {
      final headers = rows.first.keys.toList();
      for (var c = 0; c < headers.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).value =
            TextCellValue(headers[c]);
      }
      for (var r = 0; r < rows.length; r++) {
        for (var c = 0; c < headers.length; c++) {
          final v = rows[r][headers[c]];
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
          );
          if (v is num) {
            cell.value = DoubleCellValue(v.toDouble());
          } else {
            cell.value = TextCellValue(v?.toString() ?? '');
          }
        }
      }
    }
    final bytes = excelLib.save(fileName: _fileBase(tab, 'xlsx'));
    if (bytes == null) {
      showErrorMessage('Excel');
      return;
    }
    final path = await _writeTempBytes(_fileBase(tab, 'xlsx'), bytes);
    await Share.shareXFiles([
      XFile(
        path,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    ]);
    showSuccessMessage(appLocalization.reportsExportDone);
  }

  String _fileBase(int tab, String ext) {
    final slug = switch (tab) {
      0 => 'occupancy',
      1 => 'financial',
      _ => 'expenses',
    };
    return 'paa_yangu_bnb_${slug}_${DateFormat('yyyyMMdd').format(DateTime.now())}.$ext';
  }

  String _exportTitle(int tab) {
    switch (tab) {
      case 0:
        return appLocalization.reportsTabOccupancy;
      case 1:
        return appLocalization.reportsTabFinancial;
      default:
        return appLocalization.reportsTabExpenses;
    }
  }

  List<Map<String, Object?>> _exportRows(int tab) {
    switch (tab) {
      case 0:
        return List.generate(bucketLabels.length, (i) {
          return {
            'Period': bucketLabels[i],
            'Occupancy %': (occupancyPct[i] * 10).roundToDouble() / 10,
          };
        });
      case 1:
        return List.generate(bucketLabels.length, (i) {
          final net = revenuePerBucket[i] - expensePerBucket[i];
          return {
            'Period': bucketLabels[i],
            'Revenue TZS': revenuePerBucket[i].round(),
            'Expenses TZS': expensePerBucket[i].round(),
            'Net TZS': net.round(),
          };
        });
      default:
        return List.generate(expenseCategoryLabels.length, (i) {
          return {
            'Category': expenseCategoryLabels[i],
            'Amount TZS': expenseCategoryAmounts[i].round(),
          };
        });
    }
  }

  static String _csvEscape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  Future<String> _writeTemp(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$name');
    await f.writeAsString(content, encoding: utf8);
    return f.path;
  }

  Future<String> _writeTempBytes(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  String formatTzs(double v) => 'TZS ${_money.format(v.round())}';

  double netAt(int i) => revenuePerBucket[i] - expensePerBucket[i];

  bool get hasExpenseSignal =>
      _bnbExpenses.any((e) => _dayInRange(_parseExpenseDate(e), rangeStart.value, rangeEnd.value));
}

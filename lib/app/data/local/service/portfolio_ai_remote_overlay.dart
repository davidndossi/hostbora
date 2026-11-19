import '../../model/general_response.dart';
import '../../repository/app_repository.dart';
import '../db/expense_local_data_source.dart';
import '../db/income_local_data_source.dart';

/// Live backend rows that are not already in the local DB.
class PortfolioAiRemoteOverlay {
  const PortfolioAiRemoteOverlay({
    this.extraIncomes = const [],
    this.extraExpenses = const [],
    this.remoteActiveBookings,
  });

  final List<IncomeRecord> extraIncomes;
  final List<ExpenseRecord> extraExpenses;
  final int? remoteActiveBookings;

  bool get isEmpty =>
      extraIncomes.isEmpty &&
      extraExpenses.isEmpty &&
      remoteActiveBookings == null;
}

/// Pulls payments, expenses, and home overview without writing the local DB.
class PortfolioAiRemoteOverlayLoader {
  PortfolioAiRemoteOverlayLoader(this._repository);

  final AppRepository _repository;

  static const _timeout = Duration(seconds: 3);

  Future<PortfolioAiRemoteOverlay> load({
    required Set<String> localPaymentIds,
    required Set<String> localExpenseIds,
  }) async {
    List<IncomeRecord> extrasIn = const [];
    List<ExpenseRecord> extrasEx = const [];
    int? bookings;

    final paymentsF = _safe(() => _repository.getPayments());
    final expensesF = _safe(() => _repository.getExpenses());
    final homeF = _safe(() => _repository.getHomeOverview());

    final results = await Future.wait([paymentsF, expensesF, homeF]);
    extrasIn = _parsePayments(results[0], localPaymentIds);
    extrasEx = _parseExpenses(results[1], localExpenseIds);
    bookings = _parseActiveBookings(results[2]);

    return PortfolioAiRemoteOverlay(
      extraIncomes: extrasIn,
      extraExpenses: extrasEx,
      remoteActiveBookings: bookings,
    );
  }

  Future<GeneralResponse?> _safe(Future<GeneralResponse> Function() call) async {
    try {
      final res = await call().timeout(_timeout);
      if (res.responseCode != null &&
          res.responseCode != '0' &&
          res.responseCode != '201') {
        return null;
      }
      return res;
    } catch (_) {
      return null;
    }
  }

  static List<IncomeRecord> _parsePayments(
    GeneralResponse? res,
    Set<String> localIds,
  ) {
    if (res == null) return const [];
    final out = <IncomeRecord>[];
    var seq = -1;
    for (final map in _extractMaps(res.data, const ['payments', 'content', 'items'])) {
      final id = _firstText(map, const ['id', 'paymentId', 'payment_id']);
      if (id.isNotEmpty && localIds.contains(id)) continue;
      final amount = _amount(map);
      if (amount <= 0) continue;
      out.add(
        IncomeRecord(
          id: seq--,
          tenantName: _firstText(map, const ['tenantName', 'guestName', 'name']),
          amountValue: amount,
          datePaidIso: _day(
            _firstText(map, const ['paymentDate', 'datePaid', 'date', 'createdAt']),
          ),
          category: _firstText(map, const ['paymentMethod', 'category', 'method']),
          notes: _firstText(map, const ['notes', 'description']),
          apartment: _firstText(map, const ['propertyName', 'apartment', 'location']),
          apartmentUnit: _firstText(map, const ['unitName', 'apartmentUnit']),
          propertyRef: _firstText(map, const ['propertyRef', 'property_ref', 'listingId']),
          bookingId: _firstText(map, const ['bookingId', 'booking_id']),
          workspaceType: _firstText(map, const ['workspaceType', 'workspace_type'])
              .ifEmpty('rent'),
          currencyCode: _firstText(map, const ['currency', 'currencyCode'])
              .ifEmpty('TZS'),
          inputAmountValue: amount,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          backendPaymentId: id,
        ),
      );
    }
    return out;
  }

  static List<ExpenseRecord> _parseExpenses(
    GeneralResponse? res,
    Set<String> localIds,
  ) {
    if (res == null) return const [];
    final out = <ExpenseRecord>[];
    var seq = -1;
    for (final map in _extractMaps(res.data, const ['expenses', 'content', 'items'])) {
      final id = _firstText(map, const ['id', 'expenseId', 'expense_id']);
      if (id.isNotEmpty && localIds.contains(id)) continue;
      final amount = _amount(map);
      if (amount <= 0) continue;
      out.add(
        ExpenseRecord(
          id: seq--,
          tenantName: _firstText(map, const ['vendor', 'tenantName', 'name']),
          amountValue: amount,
          datePaidIso: _day(
            _firstText(map, const ['expenseDate', 'date', 'datePaid', 'createdAt']),
          ),
          category: _firstText(map, const ['category']).ifEmpty('Other'),
          notes: _firstText(map, const ['description', 'notes']),
          apartment: _firstText(map, const ['propertyName', 'apartment', 'location']),
          apartmentUnit: _firstText(map, const ['unitName', 'apartmentUnit']),
          workspaceType: _firstText(map, const ['workspaceType', 'workspace_type'])
              .ifEmpty('rent'),
          currencyCode: _firstText(map, const ['currency', 'currencyCode'])
              .ifEmpty('TZS'),
          inputAmountValue: amount,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          backendExpenseId: id,
        ),
      );
    }
    return out;
  }

  static int? _parseActiveBookings(GeneralResponse? res) {
    final data = res?.data;
    if (data is! Map) return null;
    final n = data['activeBookings'];
    if (n is num) return n.toInt();
    return int.tryParse(n?.toString() ?? '');
  }

  static List<Map<String, dynamic>> _extractMaps(
    dynamic data,
    List<String> keys,
  ) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      for (final key in keys) {
        final nested = data[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
  }

  static String _firstText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static double _amount(Map<String, dynamic> map) {
    for (final key in const ['amount', 'amountValue', 'total']) {
      final value = map[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static String _day(String raw) {
    final text = raw.trim();
    if (text.length >= 10) return text.substring(0, 10);
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

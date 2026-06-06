import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.tenantName,
    required this.amountValue,
    required this.datePaidIso,
    required this.category,
    required this.notes,
    required this.apartment,
    required this.apartmentUnit,
    required this.workspaceType,
    required this.currencyCode,
    required this.inputAmountValue,
    required this.createdAtMs,
  });

  final int id;
  final String tenantName;
  final double amountValue;
  final String datePaidIso;
  final String category;
  final String notes;

  /// Selected property location (building / listing line).
  final String apartment;

  /// Unit name when expense is allocated to a specific unit.
  final String apartmentUnit;
  final String workspaceType;
  final String currencyCode;
  final double inputAmountValue;
  final int createdAtMs;

  factory ExpenseRecord.fromMap(Map<String, Object?> m) {
    return ExpenseRecord(
      id: m['id']! as int,
      tenantName: m['tenant_name'] as String? ?? '',
      amountValue: (m['amount_value'] as num?)?.toDouble() ?? 0,
      datePaidIso: m['date_paid_iso'] as String? ?? '',
      category: m['category'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      apartment: m['apartment'] as String? ?? '',
      apartmentUnit: m['apartment_unit'] as String? ?? '',
      workspaceType: m['workspace_type'] as String? ?? 'rent',
      currencyCode: m['currency_code'] as String? ?? 'TZS',
      inputAmountValue: (m['input_amount_value'] as num?)?.toDouble() ?? 0,
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }

  /// Interprets [datePaidIso] as a local calendar day when it is `yyyy-MM-dd`.
  DateTime paidLocalCalendarOrCreated() {
    final raw = datePaidIso.trim();
    if (raw.length >= 10 && raw[4] == '-' && raw[7] == '-') {
      final y = int.tryParse(raw.substring(0, 4));
      final m = int.tryParse(raw.substring(5, 7));
      final d = int.tryParse(raw.substring(8, 10));
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
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    }
  }
}

/// Offline expense rows stored in the shared [AppLocalDatabase.expenseTable].
class ExpenseLocalDataSource {
  static const _table = AppLocalDatabase.expenseTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  static String _normalizeWorkspace(String w) =>
      w.trim().toLowerCase() == 'bnb' ? 'bnb' : 'rent';

  Future<int> insert({
    required String tenantName,
    required double amountValue,
    required String datePaidIso,
    required String category,
    required String workspaceType,
    String notes = '',
    String apartment = '',
    String apartmentUnit = '',
    String currencyCode = 'TZS',
    double inputAmountValue = 0,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'tenant_name': tenantName,
      'amount_value': amountValue,
      'currency_code': currencyCode.trim().isEmpty
          ? 'TZS'
          : currencyCode.trim().toUpperCase(),
      'input_amount_value': inputAmountValue <= 0
          ? amountValue
          : inputAmountValue,
      'date_paid_iso': datePaidIso,
      'category': category,
      'notes': notes,
      'apartment': apartment,
      'apartment_unit': apartmentUnit,
      'workspace_type': _normalizeWorkspace(workspaceType),
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<ExpenseRecord?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExpenseRecord.fromMap(maps.first);
  }

  Future<int> update({
    required int id,
    required String tenantName,
    required double amountValue,
    required String datePaidIso,
    required String category,
    required String workspaceType,
    String notes = '',
    String apartment = '',
    String apartmentUnit = '',
    String currencyCode = 'TZS',
    double inputAmountValue = 0,
  }) async {
    final db = await database;
    return db.update(
      _table,
      {
        'tenant_name': tenantName,
        'amount_value': amountValue,
        'currency_code': currencyCode.trim().isEmpty
            ? 'TZS'
            : currencyCode.trim().toUpperCase(),
        'input_amount_value': inputAmountValue <= 0
            ? amountValue
            : inputAmountValue,
        'date_paid_iso': datePaidIso,
        'category': category,
        'notes': notes,
        'apartment': apartment,
        'apartment_unit': apartmentUnit,
        'workspace_type': _normalizeWorkspace(workspaceType),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// See [RentIncomeLocalDataSource.getAllNewestFirst].
  Future<List<ExpenseRecord>> getAllNewestFirst({String? workspaceType}) async {
    final db = await database;
    if (workspaceType == null) {
      final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
      return maps.map(ExpenseRecord.fromMap).toList();
    }
    final w = _normalizeWorkspace(workspaceType);
    final maps = await db.query(
      _table,
      where:
          "lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
      whereArgs: [w],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(ExpenseRecord.fromMap).toList();
  }
}

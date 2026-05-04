import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class IncomeRecord {
  const IncomeRecord({
    required this.id,
    required this.tenantName,
    required this.amountValue,
    required this.datePaidIso,
    required this.category,
    required this.notes,
    required this.apartment,
    required this.apartmentUnit,
    required this.workspaceType,
    required this.createdAtMs,
  });

  final int id;
  final String tenantName;
  final double amountValue;
  final String datePaidIso;
  final String category;
  final String notes;
  final String apartment;
  final String apartmentUnit;
  /// `rent` or `bnb` — matches [WorkspaceContextService] persistence.
  final String workspaceType;
  final int createdAtMs;

  factory IncomeRecord.fromMap(Map<String, Object?> m) {
    return IncomeRecord(
      id: m['id']! as int,
      tenantName: m['tenant_name'] as String? ?? '',
      amountValue: (m['amount_value'] as num?)?.toDouble() ?? 0,
      datePaidIso: m['date_paid_iso'] as String? ?? '',
      category: m['category'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      apartment: m['apartment'] as String? ?? '',
      apartmentUnit: m['apartment_unit'] as String? ?? '',
      workspaceType: m['workspace_type'] as String? ?? 'rent',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

/// Offline income rows stored in the shared [AppLocalDatabase.incomeTable].
class IncomeLocalDataSource {
  static const _table = AppLocalDatabase.incomeTable;

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
  }) async {
    final db = await database;
    return db.insert(_table, {
      'tenant_name': tenantName,
      'amount_value': amountValue,
      'date_paid_iso': datePaidIso,
      'category': category,
      'notes': notes,
      'apartment': apartment,
      'apartment_unit': apartmentUnit,
      'workspace_type': _normalizeWorkspace(workspaceType),
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// When [workspaceType] is null, returns rows for all workspaces (e.g. home
  /// overview filters BnB rows in Dart). Otherwise filters `income` by
  /// normalized `rent` / `bnb` (blank/null stored values count as `rent`).
  Future<List<IncomeRecord>> getAllNewestFirst({String? workspaceType}) async {
    final db = await database;
    if (workspaceType == null) {
      final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
      return maps.map(IncomeRecord.fromMap).toList();
    }
    final w = _normalizeWorkspace(workspaceType);
    final maps = await db.query(
      _table,
      where:
          "lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
      whereArgs: [w],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(IncomeRecord.fromMap).toList();
  }
}

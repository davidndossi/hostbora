import 'package:sqflite/sqflite.dart';

import '../../../core/utils/sync_freshness.dart';
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
    this.backendExpenseId = '',
    this.updatedAtMs = 0,
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

  /// UUID returned by the backend after a successful sync; empty if not yet synced.
  final String backendExpenseId;

  /// Last local or applied remote edit. `0` means "use [createdAtMs]".
  final int updatedAtMs;

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
      backendExpenseId: m['backend_expense_id'] as String? ?? '',
      updatedAtMs: (m['updated_at_ms'] as num?)?.toInt() ?? 0,
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

  Future<Database> get database => AppLocalDatabase.database;

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
    final now = DateTime.now().millisecondsSinceEpoch;
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
      'created_at_ms': now,
      'updated_at_ms': now,
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
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveBackendExpenseId({
    required int localId,
    required String backendId,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {'backend_expense_id': backendId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<String?> getBackendExpenseId(int localId) async {
    final db = await database;
    final rows = await db.query(
      _table,
      columns: ['backend_expense_id'],
      where: 'id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final val = rows.first['backend_expense_id'] as String? ?? '';
    return val.isEmpty ? null : val;
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

  /// Merges a server expense. The phone row is kept when it was edited later.
  Future<RemoteRowMerge<ExpenseRecord>> upsertFromRemote({
    required String backendExpenseId,
    required String tenantName,
    required double amountValue,
    required String datePaidIso,
    required String category,
    required String notes,
    required String apartment,
    required String workspaceType,
    required String currencyCode,
    required int remoteUpdatedAtMs,
  }) async {
    final backendId = backendExpenseId.trim();
    final rows = await getAllNewestFirst();
    ExpenseRecord? existing;
    if (backendId.isNotEmpty) {
      for (final row in rows) {
        if (row.backendExpenseId.trim() == backendId) {
          existing = row;
          break;
        }
      }
    }
    existing ??= _matchExpense(
      rows,
      amountValue: amountValue,
      datePaidIso: datePaidIso,
      category: category,
      tenantName: tenantName,
    );
    if (existing != null &&
        SyncFreshness.phoneIsNewer(
          localUpdatedMs: existing.updatedAtMs,
          localCreatedMs: existing.createdAtMs,
          remoteUpdatedMs: remoteUpdatedAtMs,
        )) {
      if (backendId.isNotEmpty && existing.backendExpenseId.trim().isEmpty) {
        await saveBackendExpenseId(localId: existing.id, backendId: backendId);
        existing = await getById(existing.id) ?? existing;
      }
      return RemoteRowMerge(record: existing, keptLocal: true);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final appliedUpdated = remoteUpdatedAtMs > 0
        ? remoteUpdatedAtMs
        : (existing != null
            ? (existing.updatedAtMs > 0
                ? existing.updatedAtMs
                : existing.createdAtMs)
            : now);
    final db = await database;
    final data = <String, Object?>{
      'tenant_name': tenantName.trim().isNotEmpty
          ? tenantName.trim()
          : (existing?.tenantName ?? ''),
      'amount_value': amountValue > 0 ? amountValue : (existing?.amountValue ?? 0),
      'currency_code': currencyCode.trim().isNotEmpty
          ? currencyCode.trim().toUpperCase()
          : (existing?.currencyCode ?? 'TZS'),
      'input_amount_value': amountValue > 0
          ? amountValue
          : (existing?.inputAmountValue ?? 0),
      'date_paid_iso': datePaidIso.trim().isNotEmpty
          ? datePaidIso.trim()
          : (existing?.datePaidIso ?? ''),
      'category': category.trim().isNotEmpty
          ? category.trim()
          : (existing?.category ?? ''),
      'notes': notes.trim().isNotEmpty ? notes.trim() : (existing?.notes ?? ''),
      'apartment': apartment.trim().isNotEmpty
          ? apartment.trim()
          : (existing?.apartment ?? ''),
      'apartment_unit': existing?.apartmentUnit ?? '',
      'workspace_type': workspaceType.trim().isNotEmpty
          ? _normalizeWorkspace(workspaceType)
          : (existing?.workspaceType ?? 'rent'),
      'backend_expense_id': backendId.isNotEmpty
          ? backendId
          : (existing?.backendExpenseId ?? ''),
      'created_at_ms': existing?.createdAtMs ?? now,
      'updated_at_ms': appliedUpdated,
    };
    if (existing != null) {
      await db.update(_table, data, where: 'id = ?', whereArgs: [existing.id]);
      final saved = await getById(existing.id);
      return RemoteRowMerge(record: saved ?? existing, keptLocal: false);
    }
    final id = await db.insert(_table, data);
    final saved = await getById(id);
    return RemoteRowMerge(record: saved!, keptLocal: false);
  }

  ExpenseRecord? _matchExpense(
    List<ExpenseRecord> rows, {
    required double amountValue,
    required String datePaidIso,
    required String category,
    required String tenantName,
  }) {
    final day = datePaidIso.trim().length >= 10
        ? datePaidIso.trim().substring(0, 10)
        : datePaidIso.trim();
    final name = tenantName.trim().toLowerCase();
    final cat = category.trim().toLowerCase();
    for (final row in rows) {
      if (row.backendExpenseId.trim().isNotEmpty) continue;
      if ((row.amountValue - amountValue).abs() > 0.01) continue;
      final rowDay = row.datePaidIso.trim().length >= 10
          ? row.datePaidIso.trim().substring(0, 10)
          : row.datePaidIso.trim();
      if (day.isNotEmpty && rowDay != day) continue;
      if (name.isNotEmpty && row.tenantName.trim().toLowerCase() != name) {
        continue;
      }
      if (cat.isNotEmpty && row.category.trim().toLowerCase() != cat) continue;
      return row;
    }
    return null;
  }
}

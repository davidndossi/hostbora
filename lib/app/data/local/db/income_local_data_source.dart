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
    this.propertyRef = '',
    this.bookingId = '',
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
  /// Hub id / [PropertyRecord.propertyRef] / `local_<id>` for listing-scoped totals.
  final String propertyRef;
  /// BnB booking key ([CheckInItem.bookingKey]) when payment is linked to a stay.
  final String bookingId;
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
      propertyRef: m['property_ref'] as String? ?? '',
      bookingId: m['booking_id'] as String? ?? '',
      workspaceType: m['workspace_type'] as String? ?? 'rent',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }

  /// Interprets [datePaidIso] as a local calendar day when it is `yyyy-MM-dd`,
  /// so month rollups are not shifted by UTC parsing of date-only strings.
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
    String propertyRef = '',
    String bookingId = '',
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
      'property_ref': propertyRef.trim(),
      'booking_id': bookingId.trim(),
      'workspace_type': _normalizeWorkspace(workspaceType),
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Income rows linked to a BnB booking ([CheckInItem.bookingKey]).
  Future<List<IncomeRecord>> getAllByBookingId(
    String bookingId, {
    String? workspaceType,
  }) async {
    final key = bookingId.trim();
    if (key.isEmpty) return const [];

    final db = await database;
    final where = StringBuffer('trim(booking_id) = ?');
    final args = <Object>[key];
    if (workspaceType != null) {
      where.write(
        " AND lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
      );
      args.add(_normalizeWorkspace(workspaceType));
    }
    final maps = await db.query(
      _table,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(IncomeRecord.fromMap).toList();
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

  /// Loads income rows whose property (joined by `property_ref`) is in BnB workspace.
  Future<List<IncomeRecord>> getAllForBnbWorkspaceByPropertyRefJoin() async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT i.*
      FROM ${AppLocalDatabase.incomeTable} i
      INNER JOIN ${AppLocalDatabase.propertiesTable} p
        ON p.property_ref = i.property_ref
      WHERE lower(trim(coalesce(nullif(trim(p.workspace_type), ''), 'rent'))) = ?
      ORDER BY i.created_at_ms DESC
      ''',
      ['bnb'],
    );
    return maps.map(IncomeRecord.fromMap).toList();
  }

  /// Returns income rows for a specific [propertyRef] and [workspaceType].
  ///
  /// Workspace is normalized to `rent` / `bnb` and sorted newest first.
  Future<List<IncomeRecord>> getAllByPropertyRefAndWorkspace({
    required String propertyRef,
    required String workspaceType,
  }) async {
    final db = await database;
    final ref = propertyRef.trim();
    if (ref.isEmpty) return const [];

    final w = _normalizeWorkspace(workspaceType);
    final maps = await db.query(
      _table,
      where:
          "trim(property_ref) = ? AND lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
      whereArgs: [ref, w],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(IncomeRecord.fromMap).toList();
  }
}

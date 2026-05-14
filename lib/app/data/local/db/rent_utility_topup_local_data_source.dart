import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

/// Kind values stored in [RentUtilityTopUpRecord.kind].
class RentUtilityKind {
  static const luku = 'luku';
  static const water = 'water';
}

class RentUtilityTopUpRecord {
  const RentUtilityTopUpRecord({
    required this.id,
    required this.kind,
    required this.unitsAdded,
    required this.amountTsh,
    required this.provider,
    required this.notes,
    required this.propertyLabel,
    required this.propertyRef,
    required this.dateIso,
    required this.createdAtMs,
  });

  final int id;

  /// One of [RentUtilityKind.luku] or [RentUtilityKind.water].
  final String kind;

  /// kWh for LUKU, liters for water.
  final double unitsAdded;
  final double amountTsh;
  final String provider;
  final String notes;
  final String propertyLabel;
  final String propertyRef;
  final String dateIso;
  final int createdAtMs;

  factory RentUtilityTopUpRecord.fromMap(Map<String, Object?> m) {
    return RentUtilityTopUpRecord(
      id: m['id']! as int,
      kind: m['kind'] as String? ?? '',
      unitsAdded: (m['units_added'] as num?)?.toDouble() ?? 0,
      amountTsh: (m['amount_tsh'] as num?)?.toDouble() ?? 0,
      provider: m['provider'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      propertyLabel: m['property_label'] as String? ?? '',
      propertyRef: m['property_ref'] as String? ?? '',
      dateIso: m['date_iso'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class RentUtilityTopUpLocalDataSource {
  static const _table = AppLocalDatabase.rentUtilityTopupTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String kind,
    required double unitsAdded,
    required double amountTsh,
    String provider = '',
    String notes = '',
    String propertyLabel = '',
    String propertyRef = '',
    required String dateIso,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'kind': kind,
      'units_added': unitsAdded,
      'amount_tsh': amountTsh,
      'provider': provider,
      'notes': notes,
      'property_label': propertyLabel,
      'property_ref': propertyRef.trim(),
      'date_iso': dateIso,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<RentUtilityTopUpRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentUtilityTopUpRecord.fromMap).toList();
  }

  Future<List<RentUtilityTopUpRecord>> getByKind(String kind) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'kind = ?',
      whereArgs: [kind],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(RentUtilityTopUpRecord.fromMap).toList();
  }

  /// Total `units_added` for a given kind (kWh for LUKU, liters for water).
  Future<double> sumUnits(String kind) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(units_added), 0) AS total FROM $_table WHERE kind = ?',
      [kind],
    );
    final total = rows.first['total'];
    return (total is num) ? total.toDouble() : 0;
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}

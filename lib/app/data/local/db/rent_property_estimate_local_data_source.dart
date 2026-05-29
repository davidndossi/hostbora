import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RentPropertyEstimateRecord {
  const RentPropertyEstimateRecord({
    required this.id,
    required this.propertyRef,
    required this.propertyLabel,
    required this.purchaseCost,
    required this.renovationCost,
    required this.expectedMonthlyIncome,
    required this.expectedMonthlyExpense,
    required this.targetOccupancyPercent,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final int id;
  final String propertyRef;
  final String propertyLabel;
  final double purchaseCost;
  final double renovationCost;
  final double expectedMonthlyIncome;
  final double expectedMonthlyExpense;
  final double targetOccupancyPercent;
  final int createdAtMs;
  final int updatedAtMs;

  factory RentPropertyEstimateRecord.fromMap(Map<String, Object?> map) {
    return RentPropertyEstimateRecord(
      id: map['id'] as int? ?? 0,
      propertyRef: map['property_ref'] as String? ?? '',
      propertyLabel: map['property_label'] as String? ?? '',
      purchaseCost: (map['purchase_cost'] as num?)?.toDouble() ?? 0,
      renovationCost: (map['renovation_cost'] as num?)?.toDouble() ?? 0,
      expectedMonthlyIncome: (map['expected_monthly_income'] as num?)?.toDouble() ?? 0,
      expectedMonthlyExpense: (map['expected_monthly_expense'] as num?)?.toDouble() ?? 0,
      targetOccupancyPercent: (map['target_occupancy_percent'] as num?)?.toDouble() ?? 0,
      createdAtMs: map['created_at_ms'] as int? ?? 0,
      updatedAtMs: map['updated_at_ms'] as int? ?? 0,
    );
  }
}

class RentPropertyEstimateLocalDataSource {
  static const _table = AppLocalDatabase.rentPropertyEstimateTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<void> upsert({
    required String propertyRef,
    required String propertyLabel,
    required double purchaseCost,
    required double renovationCost,
    required double expectedMonthlyIncome,
    required double expectedMonthlyExpense,
    required double targetOccupancyPercent,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      _table,
      {
        'property_ref': propertyRef,
        'property_label': propertyLabel,
        'purchase_cost': purchaseCost,
        'renovation_cost': renovationCost,
        'expected_monthly_income': expectedMonthlyIncome,
        'expected_monthly_expense': expectedMonthlyExpense,
        'target_occupancy_percent': targetOccupancyPercent,
        'created_at_ms': now,
        'updated_at_ms': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RentPropertyEstimateRecord>> getAllNewestFirst() async {
    final db = await database;
    final rows = await db.query(
      _table,
      orderBy: 'updated_at_ms DESC',
    );
    return rows.map(RentPropertyEstimateRecord.fromMap).toList();
  }

  Future<RentPropertyEstimateRecord?> findByPropertyRef(String propertyRef) async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'property_ref = ?',
      whereArgs: [propertyRef],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RentPropertyEstimateRecord.fromMap(rows.first);
  }
}

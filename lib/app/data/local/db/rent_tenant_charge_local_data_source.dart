import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RentTenantChargeRecord {
  const RentTenantChargeRecord({
    required this.id,
    required this.propertyLabel,
    required this.chargeType,
    required this.amountTsh,
    required this.description,
    required this.createdAtMs,
  });

  final int id;
  final String propertyLabel;
  final String chargeType;
  final double amountTsh;
  final String description;
  final int createdAtMs;

  factory RentTenantChargeRecord.fromMap(Map<String, Object?> m) {
    return RentTenantChargeRecord(
      id: m['id']! as int,
      propertyLabel: m['property_label'] as String? ?? '',
      chargeType: m['charge_type'] as String? ?? '',
      amountTsh: (m['amount_tsh'] as num?)?.toDouble() ?? 0,
      description: m['description'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class RentTenantChargeLocalDataSource {
  static const _table = AppLocalDatabase.rentTenantChargeTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String propertyLabel,
    required String chargeType,
    required double amountTsh,
    required String description,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'property_label': propertyLabel,
      'charge_type': chargeType,
      'amount_tsh': amountTsh,
      'description': description,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<RentTenantChargeRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentTenantChargeRecord.fromMap).toList();
  }
}

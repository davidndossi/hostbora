import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RentExpenseRecord {
  const RentExpenseRecord({
    required this.id,
    required this.tenantName,
    required this.amountValue,
    required this.datePaidIso,
    required this.category,
    required this.notes,
    required this.apartment,
    required this.apartmentUnit,
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
  final int createdAtMs;

  factory RentExpenseRecord.fromMap(Map<String, Object?> m) {
    return RentExpenseRecord(
      id: m['id']! as int,
      tenantName: m['tenant_name'] as String? ?? '',
      amountValue: (m['amount_value'] as num?)?.toDouble() ?? 0,
      datePaidIso: m['date_paid_iso'] as String? ?? '',
      category: m['category'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      apartment: m['apartment'] as String? ?? '',
      apartmentUnit: m['apartment_unit'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class RentExpenseLocalDataSource {
  static const _table = AppLocalDatabase.rentExpenseTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String tenantName,
    required double amountValue,
    required String datePaidIso,
    required String category,
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
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<RentExpenseRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentExpenseRecord.fromMap).toList();
  }
}

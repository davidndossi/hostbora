import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RentLoyaltyOfferRecord {
  const RentLoyaltyOfferRecord({
    required this.id,
    required this.minStayMonths,
    required this.revenueThresholdTsh,
    required this.offerType,
    required this.terms,
    required this.createdAtMs,
  });

  final int id;
  final int minStayMonths;
  final double revenueThresholdTsh;
  final String offerType;
  final String terms;
  final int createdAtMs;

  factory RentLoyaltyOfferRecord.fromMap(Map<String, Object?> m) {
    return RentLoyaltyOfferRecord(
      id: m['id']! as int,
      minStayMonths: m['min_stay_months'] as int? ?? 0,
      revenueThresholdTsh: (m['revenue_threshold_tsh'] as num?)?.toDouble() ?? 0,
      offerType: m['offer_type'] as String? ?? '',
      terms: m['terms'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class RentLoyaltyOfferLocalDataSource {
  static const _table = AppLocalDatabase.rentLoyaltyOfferTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required int minStayMonths,
    required double revenueThresholdTsh,
    required String offerType,
    required String terms,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'min_stay_months': minStayMonths,
      'revenue_threshold_tsh': revenueThresholdTsh,
      'offer_type': offerType,
      'terms': terms,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<RentLoyaltyOfferRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentLoyaltyOfferRecord.fromMap).toList();
  }

  Future<void> update({
    required int id,
    required int minStayMonths,
    required double revenueThresholdTsh,
    required String offerType,
    required String terms,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'min_stay_months': minStayMonths,
        'revenue_threshold_tsh': revenueThresholdTsh,
        'offer_type': offerType,
        'terms': terms,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}

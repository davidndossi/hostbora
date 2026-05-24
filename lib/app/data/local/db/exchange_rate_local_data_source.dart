import 'package:sqflite/sqflite.dart';

import '../../model/exchange_rate.dart';
import 'app_local_database.dart';

class ExchangeRateLocalDataSource {
  static const _table = AppLocalDatabase.exchangeRatesTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<void> replaceAll(List<ExchangeRate> rates) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_table);
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final r in rates) {
        await txn.insert(_table, {
          'currency': r.currency,
          'buying': r.buying,
          'selling': r.selling,
          'updated_at_ms': now,
        });
      }
    });
  }

  Future<List<ExchangeRate>> getAll() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'currency ASC');
    return maps
        .map(
          (m) => ExchangeRate(
            currency: m['currency'] as String? ?? '',
            buying: (m['buying'] as num?)?.toDouble() ?? 0,
            selling: (m['selling'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((r) => r.currency.isNotEmpty)
        .toList();
  }
}

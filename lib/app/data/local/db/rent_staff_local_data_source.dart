import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '/app/modules/rent/staff_management/utils/rent_staff_pay_format.dart';

class RentStaffRecord {
  const RentStaffRecord({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.payAmountLabel,
    required this.payDayLabel,
    required this.createdAtMs,
    this.paymentType = RentStaffPayFormat.monthly,
    this.amountValue = 0,
  });

  final int id;
  final String name;
  final String jobTitle;
  /// Legacy display string when [amountValue] is 0 (pre-migration rows).
  final String payAmountLabel;
  final String payDayLabel;
  final int createdAtMs;
  final String paymentType;
  final double amountValue;

  String get displayAmountLine {
    if (amountValue > 0) {
      return RentStaffPayFormat.amountLine(amountValue, paymentType);
    }
    return payAmountLabel.isNotEmpty ? payAmountLabel : '—';
  }

  factory RentStaffRecord.fromMap(Map<String, Object?> m) {
    return RentStaffRecord(
      id: m['id']! as int,
      name: m['name'] as String? ?? '',
      jobTitle: m['job_title'] as String? ?? '',
      payAmountLabel: m['pay_amount_label'] as String? ?? '',
      payDayLabel: m['pay_day_label'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      paymentType: m['payment_type'] as String? ?? RentStaffPayFormat.monthly,
      amountValue: (m['amount_value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RentStaffLocalDataSource {
  static const _dbName = 'rent_staff.db';
  static const _table = 'rent_staff';
  static const _version = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            job_title TEXT NOT NULL DEFAULT '',
            pay_amount_label TEXT NOT NULL DEFAULT '',
            pay_day_label TEXT NOT NULL DEFAULT '',
            created_at_ms INTEGER NOT NULL,
            payment_type TEXT NOT NULL DEFAULT 'monthly',
            amount_value REAL NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN payment_type TEXT NOT NULL DEFAULT 'monthly'",
          );
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN amount_value REAL NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  Future<int> insert({
    required String name,
    required String jobTitle,
    required String payDayLabel,
    required String paymentType,
    required double amountValue,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'name': name,
      'job_title': jobTitle,
      'pay_amount_label': '',
      'pay_day_label': payDayLabel,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      'payment_type': paymentType,
      'amount_value': amountValue,
    });
  }

  Future<List<RentStaffRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentStaffRecord.fromMap).toList();
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}

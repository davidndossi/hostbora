import 'package:sqflite/sqflite.dart';

import '/app/modules/rent/staff_management/utils/rent_staff_pay_format.dart';
import 'app_local_database.dart';

class StaffRemoteUpsert {
  const StaffRemoteUpsert({
    required this.backendId,
    required this.name,
    required this.jobTitle,
    required this.payDayLabel,
    required this.paymentType,
    required this.amountValue,
    this.phone = '',
    this.notes = '',
    this.propertyRef = '',
    this.status = 'active',
  });

  final String backendId;
  final String name;
  final String jobTitle;
  final String payDayLabel;
  final String paymentType;
  final double amountValue;
  final String phone;
  final String notes;
  final String propertyRef;
  final String status;
}

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
  static const _table = AppLocalDatabase.rentStaffTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    return AppLocalDatabase.database;
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

  Future<RentStaffRecord?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RentStaffRecord.fromMap(maps.first);
  }

  Future<void> updateById({
    required int id,
    required String name,
    required String jobTitle,
    required String payDayLabel,
    required String paymentType,
    required double amountValue,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'name': name,
        'job_title': jobTitle,
        'pay_day_label': payDayLabel,
        'payment_type': paymentType,
        'amount_value': amountValue,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Re-inserts a deleted row with the same local id (and optional backend id).
  /// Idempotent: no-op if [record.id] already exists.
  Future<bool> restore(
    RentStaffRecord record, {
    String? backendStaffId,
  }) async {
    if (await getById(record.id) != null) return false;
    final db = await database;
    final map = <String, Object?>{
      'id': record.id,
      'name': record.name,
      'job_title': record.jobTitle,
      'pay_amount_label': record.payAmountLabel,
      'pay_day_label': record.payDayLabel,
      'created_at_ms': record.createdAtMs,
      'payment_type': record.paymentType,
      'amount_value': record.amountValue,
    };
    final backend = backendStaffId?.trim() ?? '';
    if (backend.isNotEmpty) {
      map['backend_staff_id'] = backend;
    }
    await db.insert(
      _table,
      map,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return true;
  }

  Future<RentStaffRecord?> getByBackendId(String backendId) async {
    final id = backendId.trim();
    if (id.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'backend_staff_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RentStaffRecord.fromMap(maps.first);
  }

  Future<void> saveBackendId(int localId, String backendId) async {
    final id = backendId.trim();
    if (id.isEmpty) return;
    final db = await database;
    await db.update(
      _table,
      {'backend_staff_id': id},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<String?> backendIdForLocal(int localId) async {
    final row = await getById(localId);
    if (row == null) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      columns: ['backend_staff_id'],
      where: 'id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final value = maps.first['backend_staff_id']?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  Future<void> upsertFromRemote(StaffRemoteUpsert remote) async {
    if (remote.name.trim().isEmpty) return;
    RentStaffRecord? existing;
    if (remote.backendId.isNotEmpty) {
      existing = await getByBackendId(remote.backendId);
    }
    if (existing == null) {
      final rows = await getAllNewestFirst();
      final lower = remote.name.trim().toLowerCase();
      for (final row in rows) {
        if (row.name.trim().toLowerCase() == lower) {
          existing = row;
          break;
        }
      }
    }
    if (existing != null) {
      await updateById(
        id: existing.id,
        name: remote.name,
        jobTitle: remote.jobTitle,
        payDayLabel: remote.payDayLabel,
        paymentType: remote.paymentType,
        amountValue: remote.amountValue,
      );
      if (remote.backendId.isNotEmpty) {
        await saveBackendId(existing.id, remote.backendId);
      }
      return;
    }
    final localId = await insert(
      name: remote.name,
      jobTitle: remote.jobTitle,
      payDayLabel: remote.payDayLabel,
      paymentType: remote.paymentType,
      amountValue: remote.amountValue,
    );
    if (remote.backendId.isNotEmpty) {
      await saveBackendId(localId, remote.backendId);
    }
  }
}

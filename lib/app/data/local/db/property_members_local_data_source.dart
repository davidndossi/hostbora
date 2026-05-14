import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class PropertyMemberRecord {
  const PropertyMemberRecord({
    required this.id,
    required this.propertyRef,
    required this.userId,
    required this.workspaceType,
    required this.role,
    required this.createdAtMs,
  });

  final int id;
  final String propertyRef;
  final String userId;
  final String workspaceType;
  final String role;
  final int createdAtMs;

  factory PropertyMemberRecord.fromMap(Map<String, Object?> m) {
    return PropertyMemberRecord(
      id: m['id'] as int? ?? 0,
      propertyRef: m['property_ref'] as String? ?? '',
      userId: m['user_id'] as String? ?? '',
      workspaceType: m['workspace_type'] as String? ?? 'rent',
      role: m['role'] as String? ?? 'co_host',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class PropertyMembersLocalDataSource {
  static const _table = AppLocalDatabase.propertyMembersTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<void> upsertMember({
    required String propertyRef,
    required String userId,
    required String workspaceType,
    String role = 'co_host',
  }) async {
    final db = await database;
    await db.insert(
      _table,
      {
        'property_ref': propertyRef,
        'user_id': userId,
        'workspace_type': workspaceType,
        'role': role,
        'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeMember({
    required String propertyRef,
    required String userId,
    required String workspaceType,
  }) async {
    final db = await database;
    await db.delete(
      _table,
      where: 'property_ref = ? AND user_id = ? AND workspace_type = ?',
      whereArgs: [propertyRef, userId, workspaceType],
    );
  }

  Future<List<PropertyMemberRecord>> listMembers({
    required String propertyRef,
    required String workspaceType,
  }) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'property_ref = ? AND workspace_type = ?',
      whereArgs: [propertyRef, workspaceType],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(PropertyMemberRecord.fromMap).toList();
  }

  /// Removes all membership rows for [propertyRef] (any workspace).
  Future<int> deleteAllForPropertyRef(String propertyRef) async {
    final r = propertyRef.trim();
    if (r.isEmpty) return 0;
    final db = await database;
    return db.delete(_table, where: 'property_ref = ?', whereArgs: [r]);
  }
}


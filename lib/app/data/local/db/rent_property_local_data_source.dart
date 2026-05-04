// import 'package:sqflite/sqflite.dart';
//
// import 'app_local_database.dart';
//
// /// Local rent listing row persisted for the Rent hub (offline-first).
// class RentPropertyRecord {
//   const RentPropertyRecord({
//     required this.id,
//     required this.propertyLocation,
//     required this.apartmentSuite,
//     required this.propertyType,
//     required this.rentAmount,
//     required this.rentFrequency,
//     required this.minRentalDuration,
//     this.propertyRef = '',
//     this.ownerUserId = '',
//     this.workspaceType = 'rent',
//     required this.createdAtMs,
//     this.unitsJson = '',
//   });
//
//   final int id;
//   final String propertyLocation;
//   final String apartmentSuite;
//   final String propertyType;
//   final String rentAmount;
//   final String rentFrequency;
//   final String minRentalDuration;
//   final String propertyRef;
//   final String ownerUserId;
//   final String workspaceType;
//   final int createdAtMs;
//   /// JSON array of apartment units when `propertyType` is Apartment.
//   final String unitsJson;
//
//   factory RentPropertyRecord.fromMap(Map<String, Object?> m) {
//     return RentPropertyRecord(
//       id: m['id']! as int,
//       propertyLocation: m['property_location'] as String? ?? '',
//       apartmentSuite: m['apartment_suite'] as String? ?? '',
//       propertyType: m['property_type'] as String? ?? '',
//       rentAmount: m['rent_amount'] as String? ?? '',
//       rentFrequency: m['rent_frequency'] as String? ?? '',
//       minRentalDuration: m['min_rental_duration'] as String? ?? '',
//       propertyRef: m['property_ref'] as String? ?? '',
//       ownerUserId: m['owner_user_id'] as String? ?? '',
//       workspaceType: m['workspace_type'] as String? ?? 'rent',
//       createdAtMs: m['created_at_ms'] as int? ?? 0,
//       unitsJson: m['units_json'] as String? ?? '',
//     );
//   }
//
//   Map<String, Object?> toInsertMap() => {
//         'property_location': propertyLocation,
//         'apartment_suite': apartmentSuite,
//         'property_type': propertyType,
//         'rent_amount': rentAmount,
//         'rent_frequency': rentFrequency,
//         'min_rental_duration': minRentalDuration,
//         'property_ref': propertyRef,
//         'owner_user_id': ownerUserId,
//         'workspace_type': workspaceType,
//         'created_at_ms': createdAtMs,
//         'units_json': unitsJson,
//       };
// }
//
// class RentPropertyLocalDataSource {
//   static const _table = AppLocalDatabase.rentPropertiesTable;
//
//   Database? _db;
//
//   Future<Database> get database async {
//     if (_db != null) return _db!;
//     _db = await _open();
//     return _db!;
//   }
//
//   Future<Database> _open() async {
//     return AppLocalDatabase.database;
//   }
//
//   Future<int> insert(RentPropertyRecord row) async {
//     final db = await database;
//     return db.insert(_table, row.toInsertMap());
//   }
//
//   /// Updates an existing row by primary key [RentPropertyRecord.id].
//   Future<int> update(RentPropertyRecord row) async {
//     final db = await database;
//     return db.update(
//       _table,
//       row.toInsertMap(),
//       where: 'id = ?',
//       whereArgs: [row.id],
//     );
//   }
//
//   Future<RentPropertyRecord?> getById(int id) async {
//     final db = await database;
//     final maps = await db.query(
//       _table,
//       where: 'id = ?',
//       whereArgs: [id],
//       limit: 1,
//     );
//     if (maps.isEmpty) return null;
//     return RentPropertyRecord.fromMap(maps.first);
//   }
//
//   Future<RentPropertyRecord?> getByPropertyRef(String propertyRef) async {
//     final ref = propertyRef.trim();
//     if (ref.isEmpty) return null;
//     final db = await database;
//     final maps = await db.query(
//       _table,
//       where: 'property_ref = ?',
//       whereArgs: [ref],
//       limit: 1,
//     );
//     if (maps.isEmpty) return null;
//     return RentPropertyRecord.fromMap(maps.first);
//   }
//
//   /// Resolves management hub id: `legacy_<sqliteId>` or stored `property_ref`.
//   Future<RentPropertyRecord?> findByHubId(String hubId) async {
//     final id = hubId.trim();
//     if (id.isEmpty) return null;
//     const legacy = 'legacy_';
//     if (id.startsWith(legacy)) {
//       final n = int.tryParse(id.substring(legacy.length));
//       if (n == null) return null;
//       return getById(n);
//     }
//     return getByPropertyRef(id);
//   }
//
//   Future<List<RentPropertyRecord>> getAllNewestFirst() async {
//     final db = await database;
//     final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
//     return maps.map(RentPropertyRecord.fromMap).toList();
//   }
//
//   Future<List<RentPropertyRecord>> getAllVisibleNewestFirst({
//     required String userId,
//     String workspaceType = 'rent',
//   }) async {
//     final db = await database;
//     if (userId.trim().isEmpty) {
//       final maps = await db.query(
//         _table,
//         where: 'workspace_type = ? OR workspace_type = ""',
//         whereArgs: [workspaceType],
//         orderBy: 'created_at_ms DESC',
//       );
//       return maps.map(RentPropertyRecord.fromMap).toList();
//     }
//     final maps = await db.rawQuery(
//       '''
//       SELECT p.*
//       FROM $_table p
//       WHERE (p.workspace_type = ? OR p.workspace_type = '')
//         AND (
//           p.owner_user_id = ?
//           OR p.owner_user_id = ''
//           OR EXISTS (
//             SELECT 1
//             FROM ${AppLocalDatabase.propertyMembersTable} m
//             WHERE m.property_ref = CASE
//               WHEN p.property_ref IS NULL OR p.property_ref = '' THEN 'legacy_' || p.id
//               ELSE p.property_ref
//             END
//             AND m.user_id = ?
//             AND m.workspace_type = ?
//           )
//         )
//       ORDER BY p.created_at_ms DESC
//       ''',
//       [workspaceType, userId, userId, workspaceType],
//     );
//     return maps.map(RentPropertyRecord.fromMap).toList();
//   }
// }

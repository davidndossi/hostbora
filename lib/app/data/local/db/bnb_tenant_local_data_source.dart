// import 'package:sqflite/sqflite.dart';
//
// import 'app_local_database.dart';
//
// /// Single-day / short-stay customer record for BnB listings.
// class BnBTenantRecord {
//   const BnBTenantRecord({
//     required this.id,
//     required this.listingId,
//     required this.apartmentUnitId,
//     required this.propertyLabel,
//     required this.unitLabel,
//     required this.guestName,
//     required this.phoneNumber,
//     required this.email,
//     required this.checkInIso,
//     required this.checkOutIso,
//     required this.amountPaid,
//     required this.paymentStatus,
//     required this.bookingSource,
//     required this.notes,
//     required this.createdAtMs,
//   });
//
//   final int id;
//   final String listingId;
//   final String apartmentUnitId;
//   final String propertyLabel;
//   final String unitLabel;
//   final String guestName;
//   final String phoneNumber;
//   final String email;
//   final String checkInIso;
//   final String checkOutIso;
//   final double amountPaid;
//   final String paymentStatus;
//   final String bookingSource;
//   final String notes;
//   final int createdAtMs;
//
//   factory BnBTenantRecord.fromMap(Map<String, Object?> m) {
//     return BnBTenantRecord(
//       id: m['id']! as int,
//       listingId: m['listing_id'] as String? ?? '',
//       apartmentUnitId: m['apartment_unit_id'] as String? ?? '',
//       propertyLabel: m['property_label'] as String? ?? '',
//       unitLabel: m['unit_label'] as String? ?? '',
//       guestName: m['guest_name'] as String? ?? '',
//       phoneNumber: m['phone_number'] as String? ?? '',
//       email: m['email'] as String? ?? '',
//       checkInIso: m['check_in_iso'] as String? ?? '',
//       checkOutIso: m['check_out_iso'] as String? ?? '',
//       amountPaid: (m['amount_paid'] as num?)?.toDouble() ?? 0,
//       paymentStatus: m['payment_status'] as String? ?? 'pending',
//       bookingSource: m['booking_source'] as String? ?? '',
//       notes: m['notes'] as String? ?? '',
//       createdAtMs: m['created_at_ms'] as int? ?? 0,
//     );
//   }
// }
//
// class BnBTenantLocalDataSource {
//   static const _table = AppLocalDatabase.bnbTenantTable;
//
//   Database? _db;
//
//   Future<Database> get database async {
//     if (_db != null) return _db!;
//     _db = await AppLocalDatabase.database;
//     return _db!;
//   }
//
//   Future<int> insert({
//     String listingId = '',
//     String propertyLabel = '',
//     String unitLabel = '',
//     String apartmentUnitId = '',
//     required String guestName,
//     String phoneNumber = '',
//     String email = '',
//     String gender = '',
//     required String checkInIso,
//     required String checkOutIso,
//     double amountPaid = 0,
//     String paymentStatus = 'pending',
//     String bookingSource = '',
//     String notes = '',
//   }) async {
//     final db = await database;
//     return db.insert(_table, {
//       'listing_id': listingId,
//       'apartment_unit_id': apartmentUnitId,
//       'property_label': propertyLabel,
//       'unit_label': unitLabel,
//       'guest_name': guestName,
//       'gender': gender,
//       'phone_number': phoneNumber,
//       'email': email,
//       'check_in_iso': checkInIso,
//       'check_out_iso': checkOutIso,
//       'amount_paid': amountPaid,
//       'payment_status': paymentStatus,
//       'booking_source': bookingSource,
//       'notes': notes,
//       'created_at_ms': DateTime.now().millisecondsSinceEpoch,
//     });
//   }
//
//   Future<List<BnBTenantRecord>> getAllNewestFirst() async {
//     final db = await database;
//     final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
//     return maps.map(BnBTenantRecord.fromMap).toList();
//   }
//
//   Future<List<BnBTenantRecord>> getByListingId(String listingId) async {
//     final db = await database;
//     final maps = await db.query(
//       _table,
//       where: 'listing_id = ?',
//       whereArgs: [listingId],
//       orderBy: 'check_in_iso DESC',
//     );
//     return maps.map(BnBTenantRecord.fromMap).toList();
//   }
//
//   Future<List<BnBTenantRecord>> getByApartmentUnitId(String apartmentUnitId) async {
//     final db = await database;
//     final maps = await db.query(
//       _table,
//       where: 'apartment_unit_id = ?',
//       whereArgs: [apartmentUnitId],
//       orderBy: 'check_in_iso DESC',
//     );
//     return maps.map(BnBTenantRecord.fromMap).toList();
//   }
//
//   Future<void> updatePaymentStatus({
//     required int id,
//     required String paymentStatus,
//   }) async {
//     final db = await database;
//     await db.update(
//       _table,
//       {'payment_status': paymentStatus},
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }
//
//   Future<void> deleteById(int id) async {
//     final db = await database;
//     await db.delete(_table, where: 'id = ?', whereArgs: [id]);
//   }
// }

import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class TenantRatingRecord {
  const TenantRatingRecord({
    required this.id,
    required this.tenantLocalId,
    required this.phoneNumber,
    required this.tenantName,
    required this.overallStars,
    required this.paymentStars,
    required this.propertyCareStars,
    required this.communicationStars,
    required this.rentAgain,
    required this.comment,
    required this.workspace,
    required this.shareConsent,
    required this.isPublished,
    required this.publishAfterMs,
    required this.tenancyDurationDays,
    required this.syncStatus,
    required this.createdAtMs,
  });

  final int id;
  final int tenantLocalId;
  final String phoneNumber;
  final String tenantName;
  final int overallStars;
  final int paymentStars;
  final int propertyCareStars;
  final int communicationStars;

  /// 'yes' | 'no' | 'maybe'
  final String rentAgain;
  final String comment;
  final String workspace;
  final bool shareConsent;
  final bool isPublished;

  /// Millisecond epoch when this rating may be published (30 days after creation).
  final int publishAfterMs;
  final int tenancyDurationDays;
  final String syncStatus;
  final int createdAtMs;

  factory TenantRatingRecord.fromMap(Map<String, Object?> m) =>
      TenantRatingRecord(
        id: m['id']! as int,
        tenantLocalId: m['tenant_local_id'] as int? ?? 0,
        phoneNumber: m['phone_number'] as String? ?? '',
        tenantName: m['tenant_name'] as String? ?? '',
        overallStars: m['overall_stars'] as int? ?? 0,
        paymentStars: m['payment_stars'] as int? ?? 0,
        propertyCareStars: m['property_care_stars'] as int? ?? 0,
        communicationStars: m['communication_stars'] as int? ?? 0,
        rentAgain: m['rent_again'] as String? ?? 'yes',
        comment: m['comment'] as String? ?? '',
        workspace: m['workspace'] as String? ?? 'rent',
        shareConsent: (m['share_consent'] as int? ?? 0) == 1,
        isPublished: (m['is_published'] as int? ?? 0) == 1,
        publishAfterMs: m['publish_after_ms'] as int? ?? 0,
        tenancyDurationDays: m['tenancy_duration_days'] as int? ?? 0,
        syncStatus: m['sync_status'] as String? ?? 'pending',
        createdAtMs: m['created_at_ms'] as int? ?? 0,
      );
}

class TenantRatingLocalDataSource {
  static const _table = AppLocalDatabase.tenantRatingTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required int tenantLocalId,
    required String phoneNumber,
    required String tenantName,
    required int overallStars,
    required int paymentStars,
    required int propertyCareStars,
    required int communicationStars,
    required String rentAgain,
    String comment = '',
    String workspace = 'rent',
    bool shareConsent = false,
    int tenancyDurationDays = 0,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    const thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    return db.insert(_table, {
      'tenant_local_id': tenantLocalId,
      'phone_number': phoneNumber.trim(),
      'tenant_name': tenantName.trim(),
      'overall_stars': overallStars.clamp(1, 5),
      'payment_stars': paymentStars.clamp(1, 5),
      'property_care_stars': propertyCareStars.clamp(1, 5),
      'communication_stars': communicationStars.clamp(1, 5),
      'rent_again': rentAgain,
      'comment': comment.trim(),
      'workspace': workspace.trim().toLowerCase(),
      'share_consent': shareConsent ? 1 : 0,
      'is_published': 0,
      'publish_after_ms': now + thirtyDaysMs,
      'tenancy_duration_days': tenancyDurationDays,
      'sync_status': 'pending',
      'created_at_ms': now,
    });
  }

  Future<TenantRatingRecord?> findByTenantId(int tenantLocalId) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'tenant_local_id = ?',
      whereArgs: [tenantLocalId],
      orderBy: 'created_at_ms DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TenantRatingRecord.fromMap(maps.first);
  }

  Future<void> updateSyncStatus(int id, String status) async {
    final db = await database;
    await db.update(
      _table,
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns all ratings ready to be published (cooling-off period elapsed, not yet published).
  Future<List<TenantRatingRecord>> getDueForPublishing() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      _table,
      where: 'is_published = 0 AND share_consent = 1 AND publish_after_ms <= ?',
      whereArgs: [now],
    );
    return maps.map(TenantRatingRecord.fromMap).toList();
  }

  Future<void> markPublished(int id) async {
    final db = await database;
    await db.update(
      _table,
      {'is_published': 1, 'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

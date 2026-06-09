import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

/// Event types for the client story timeline.
enum ClientEventType {
  tenantAdded,
  bookingCreated,
  checkIn,
  paymentPartial,
  paymentFull,
  balanceCleared,
  leaseStarted,
  leaseEnded,
  checkOut,
  reminderSent,
  leaseRenewed;

  String get value {
    switch (this) {
      case tenantAdded:
        return 'tenant_added';
      case bookingCreated:
        return 'booking_created';
      case checkIn:
        return 'check_in';
      case paymentPartial:
        return 'payment_partial';
      case paymentFull:
        return 'payment_full';
      case balanceCleared:
        return 'balance_cleared';
      case leaseStarted:
        return 'lease_started';
      case leaseEnded:
        return 'lease_ended';
      case checkOut:
        return 'check_out';
      case reminderSent:
        return 'reminder_sent';
      case leaseRenewed:
        return 'lease_renewed';
    }
  }

  static ClientEventType fromValue(String v) {
    switch (v) {
      case 'tenant_added':
        return tenantAdded;
      case 'booking_created':
        return bookingCreated;
      case 'check_in':
        return checkIn;
      case 'payment_partial':
        return paymentPartial;
      case 'payment_full':
        return paymentFull;
      case 'balance_cleared':
        return balanceCleared;
      case 'lease_started':
        return leaseStarted;
      case 'lease_ended':
        return leaseEnded;
      case 'check_out':
        return checkOut;
      case 'reminder_sent':
        return reminderSent;
      case 'lease_renewed':
        return leaseRenewed;
      default:
        return tenantAdded;
    }
  }
}

class ClientEventRecord {
  const ClientEventRecord({
    required this.id,
    required this.tenantLocalId,
    required this.phoneNumber,
    required this.clientName,
    required this.propertyRef,
    required this.propertyLabel,
    required this.unitLabel,
    required this.workspace,
    required this.eventType,
    required this.amountTsh,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.metadataJson,
    required this.syncStatus,
    required this.createdAtMs,
  });

  final int id;
  final int tenantLocalId;
  final String phoneNumber;
  final String clientName;
  final String propertyRef;
  final String propertyLabel;
  final String unitLabel;
  final String workspace;
  final ClientEventType eventType;
  final int amountTsh;
  final int balanceBefore;
  final int balanceAfter;
  final String metadataJson;
  final String syncStatus;
  final int createdAtMs;

  Map<String, dynamic> get metadata {
    try {
      return jsonDecode(metadataJson) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  factory ClientEventRecord.fromMap(Map<String, Object?> m) =>
      ClientEventRecord(
        id: m['id']! as int,
        tenantLocalId: m['tenant_local_id'] as int? ?? 0,
        phoneNumber: m['phone_number'] as String? ?? '',
        clientName: m['client_name'] as String? ?? '',
        propertyRef: m['property_ref'] as String? ?? '',
        propertyLabel: m['property_label'] as String? ?? '',
        unitLabel: m['unit_label'] as String? ?? '',
        workspace: m['workspace'] as String? ?? 'rent',
        eventType: ClientEventType.fromValue(
          m['event_type'] as String? ?? 'tenant_added',
        ),
        amountTsh: m['amount_tsh'] as int? ?? 0,
        balanceBefore: m['balance_before'] as int? ?? 0,
        balanceAfter: m['balance_after'] as int? ?? 0,
        metadataJson: m['metadata_json'] as String? ?? '{}',
        syncStatus: m['sync_status'] as String? ?? 'pending',
        createdAtMs: m['created_at_ms'] as int? ?? 0,
      );
}

class ClientEventLocalDataSource {
  static const _table = AppLocalDatabase.clientEventTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    int tenantLocalId = 0,
    required String phoneNumber,
    required String clientName,
    String propertyRef = '',
    String propertyLabel = '',
    String unitLabel = '',
    String workspace = 'rent',
    required ClientEventType eventType,
    int amountTsh = 0,
    int balanceBefore = 0,
    int balanceAfter = 0,
    Map<String, dynamic> metadata = const {},
  }) async {
    final db = await database;
    return db.insert(_table, {
      'tenant_local_id': tenantLocalId,
      'phone_number': phoneNumber.trim(),
      'client_name': clientName.trim(),
      'property_ref': propertyRef.trim(),
      'property_label': propertyLabel.trim(),
      'unit_label': unitLabel.trim(),
      'workspace': workspace.trim().toLowerCase(),
      'event_type': eventType.value,
      'amount_tsh': amountTsh,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'metadata_json': jsonEncode(metadata),
      'sync_status': 'pending',
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<ClientEventRecord>> getByPhone(String phone) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'phone_number = ?',
      whereArgs: [phone.trim()],
      orderBy: 'created_at_ms ASC',
    );
    return maps.map(ClientEventRecord.fromMap).toList();
  }

  Future<List<ClientEventRecord>> getByTenantLocalId(int tenantId) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'tenant_local_id = ?',
      whereArgs: [tenantId],
      orderBy: 'created_at_ms ASC',
    );
    return maps.map(ClientEventRecord.fromMap).toList();
  }

  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      _table,
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

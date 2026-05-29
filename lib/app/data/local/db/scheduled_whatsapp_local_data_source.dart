import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class ScheduledWhatsappRecord {
  const ScheduledWhatsappRecord({
    required this.id,
    required this.workspace,
    required this.recipientPhone,
    required this.recipientLabel,
    required this.messageBody,
    required this.templateName,
    required this.languageCode,
    required this.bodyParameters,
    required this.headerParameters,
    required this.scheduledAtIso,
    required this.notificationId,
    required this.sent,
    required this.createdAtMs,
  });

  final int id;
  final String workspace;
  final String recipientPhone;
  final String recipientLabel;
  final String messageBody;
  final String templateName;
  final String languageCode;
  final List<String> bodyParameters;
  final List<String> headerParameters;
  final String scheduledAtIso;
  final int notificationId;
  final bool sent;
  final int createdAtMs;

  factory ScheduledWhatsappRecord.fromMap(Map<String, Object?> m) {
    List<String> decodeList(String raw) {
      if (raw.isEmpty) return const [];
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => e.toString()).toList();
      } catch (_) {
        return const [];
      }
    }

    return ScheduledWhatsappRecord(
      id: m['id']! as int,
      workspace: m['workspace'] as String? ?? 'rent',
      recipientPhone: m['recipient_phone'] as String? ?? '',
      recipientLabel: m['recipient_label'] as String? ?? '',
      messageBody: m['message_body'] as String? ?? '',
      templateName: m['template_name'] as String? ?? '',
      languageCode: m['language_code'] as String? ?? '',
      bodyParameters: decodeList(m['body_parameters_json'] as String? ?? ''),
      headerParameters: decodeList(m['header_parameters_json'] as String? ?? ''),
      scheduledAtIso: m['scheduled_at_iso'] as String? ?? '',
      notificationId: m['notification_id'] as int? ?? 0,
      sent: (m['sent'] as int? ?? 0) == 1,
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class ScheduledWhatsappLocalDataSource {
  static const _table = AppLocalDatabase.scheduledWhatsappTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String workspace,
    required String recipientPhone,
    required String recipientLabel,
    required String messageBody,
    String templateName = '',
    String languageCode = '',
    List<String> bodyParameters = const [],
    List<String> headerParameters = const [],
    required String scheduledAtIso,
    required int notificationId,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'workspace': workspace,
      'recipient_phone': recipientPhone.trim(),
      'recipient_label': recipientLabel.trim(),
      'message_body': messageBody,
      'template_name': templateName,
      'language_code': languageCode,
      'body_parameters_json': jsonEncode(bodyParameters),
      'header_parameters_json': jsonEncode(headerParameters),
      'scheduled_at_iso': scheduledAtIso,
      'notification_id': notificationId,
      'sent': 0,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<ScheduledWhatsappRecord>> getDueUnsent({DateTime? before}) async {
    final db = await database;
    final cutoff = (before ?? DateTime.now()).toIso8601String();
    final maps = await db.query(
      _table,
      where: 'sent = 0 AND scheduled_at_iso <= ?',
      whereArgs: [cutoff],
      orderBy: 'scheduled_at_iso ASC',
    );
    return maps.map(ScheduledWhatsappRecord.fromMap).toList();
  }

  Future<void> markSent(int id) async {
    final db = await database;
    await db.update(_table, {'sent': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

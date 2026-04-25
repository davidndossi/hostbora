import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

/// WhatsApp Business template categories (per Meta's cloud API).
class WaTemplateCategory {
  static const utility = 'utility';
  static const marketing = 'marketing';
  static const authentication = 'authentication';

  static const values = [utility, marketing, authentication];

  static String label(String category) {
    switch (category) {
      case utility:
        return 'Utility';
      case marketing:
        return 'Marketing';
      case authentication:
        return 'Authentication';
    }
    return category;
  }
}

/// Submission state of a template against Meta's approval workflow.
class WaTemplateStatus {
  static const draft = 'draft';
  static const submitted = 'submitted';
  static const approved = 'approved';
  static const rejected = 'rejected';

  static String label(String s) {
    switch (s) {
      case draft:
        return 'Draft';
      case submitted:
        return 'Pending review';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
    }
    return s;
  }
}

class WaTemplateHeaderType {
  static const none = 'none';
  static const text = 'text';
}

/// Quick-reply / URL / phone buttons attached to a template.
class WaTemplateButton {
  const WaTemplateButton({
    required this.type,
    required this.label,
    this.url = '',
    this.phoneNumber = '',
  });

  /// One of `quick_reply`, `url`, `phone_number`.
  final String type;
  final String label;
  final String url;
  final String phoneNumber;

  Map<String, dynamic> toMap() => {
        'type': type,
        'label': label,
        'url': url,
        'phone_number': phoneNumber,
      };

  factory WaTemplateButton.fromMap(Map<String, dynamic> m) => WaTemplateButton(
        type: m['type'] as String? ?? 'quick_reply',
        label: m['label'] as String? ?? '',
        url: m['url'] as String? ?? '',
        phoneNumber: m['phone_number'] as String? ?? '',
      );
}

class RentWhatsappTemplateRecord {
  const RentWhatsappTemplateRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.language,
    required this.headerType,
    required this.headerText,
    required this.bodyText,
    required this.footerText,
    required this.buttons,
    required this.sampleVariables,
    required this.status,
    required this.submittedAtMs,
    required this.approvedAtMs,
    required this.rejectionReason,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final int id;
  final String name;
  final String category;
  final String language;
  final String headerType;
  final String headerText;
  final String bodyText;
  final String footerText;
  final List<WaTemplateButton> buttons;
  final List<String> sampleVariables;
  final String status;
  final int submittedAtMs;
  final int approvedAtMs;
  final String rejectionReason;
  final int createdAtMs;
  final int updatedAtMs;

  factory RentWhatsappTemplateRecord.fromMap(Map<String, Object?> m) {
    List<WaTemplateButton> decodeButtons() {
      final raw = m['buttons_json'] as String? ?? '';
      if (raw.isEmpty) return const [];
      try {
        final list = jsonDecode(raw) as List;
        return list
            .map((e) => WaTemplateButton.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        return const [];
      }
    }

    List<String> decodeVars() {
      final raw = m['sample_variables_json'] as String? ?? '';
      if (raw.isEmpty) return const [];
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => e.toString()).toList();
      } catch (_) {
        return const [];
      }
    }

    return RentWhatsappTemplateRecord(
      id: m['id']! as int,
      name: m['name'] as String? ?? '',
      category: m['category'] as String? ?? WaTemplateCategory.utility,
      language: m['language'] as String? ?? 'en_US',
      headerType: m['header_type'] as String? ?? WaTemplateHeaderType.none,
      headerText: m['header_text'] as String? ?? '',
      bodyText: m['body_text'] as String? ?? '',
      footerText: m['footer_text'] as String? ?? '',
      buttons: decodeButtons(),
      sampleVariables: decodeVars(),
      status: m['status'] as String? ?? WaTemplateStatus.draft,
      submittedAtMs: m['submitted_at_ms'] as int? ?? 0,
      approvedAtMs: m['approved_at_ms'] as int? ?? 0,
      rejectionReason: m['rejection_reason'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      updatedAtMs: m['updated_at_ms'] as int? ?? 0,
    );
  }
}

class RentWhatsappTemplateLocalDataSource {
  static const _table = AppLocalDatabase.rentWhatsappTemplateTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Map<String, Object?> _toRow({
    required String name,
    required String category,
    required String language,
    required String headerType,
    required String headerText,
    required String bodyText,
    required String footerText,
    required List<WaTemplateButton> buttons,
    required List<String> sampleVariables,
    required String status,
    required int submittedAtMs,
    required int approvedAtMs,
    required String rejectionReason,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'name': name,
      'category': category,
      'language': language,
      'header_type': headerType,
      'header_text': headerText,
      'body_text': bodyText,
      'footer_text': footerText,
      'buttons_json': jsonEncode(buttons.map((b) => b.toMap()).toList()),
      'sample_variables_json': jsonEncode(sampleVariables),
      'status': status,
      'submitted_at_ms': submittedAtMs,
      'approved_at_ms': approvedAtMs,
      'rejection_reason': rejectionReason,
      'updated_at_ms': now,
    };
  }

  Future<int> insert({
    required String name,
    required String category,
    required String language,
    required String headerType,
    required String headerText,
    required String bodyText,
    required String footerText,
    required List<WaTemplateButton> buttons,
    required List<String> sampleVariables,
    String status = WaTemplateStatus.draft,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = _toRow(
      name: name,
      category: category,
      language: language,
      headerType: headerType,
      headerText: headerText,
      bodyText: bodyText,
      footerText: footerText,
      buttons: buttons,
      sampleVariables: sampleVariables,
      status: status,
      submittedAtMs: status == WaTemplateStatus.submitted ? now : 0,
      approvedAtMs: 0,
      rejectionReason: '',
    )..['created_at_ms'] = now;
    return db.insert(_table, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update({
    required int id,
    required String name,
    required String category,
    required String language,
    required String headerType,
    required String headerText,
    required String bodyText,
    required String footerText,
    required List<WaTemplateButton> buttons,
    required List<String> sampleVariables,
    required String status,
    int submittedAtMs = 0,
    int approvedAtMs = 0,
    String rejectionReason = '',
  }) async {
    final db = await database;
    final row = _toRow(
      name: name,
      category: category,
      language: language,
      headerType: headerType,
      headerText: headerText,
      bodyText: bodyText,
      footerText: footerText,
      buttons: buttons,
      sampleVariables: sampleVariables,
      status: status,
      submittedAtMs: submittedAtMs,
      approvedAtMs: approvedAtMs,
      rejectionReason: rejectionReason,
    );
    return db.update(_table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStatus({
    required int id,
    required String status,
    String rejectionReason = '',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final values = <String, Object?>{
      'status': status,
      'updated_at_ms': now,
    };
    if (status == WaTemplateStatus.submitted) {
      values['submitted_at_ms'] = now;
      values['rejection_reason'] = '';
    }
    if (status == WaTemplateStatus.approved) {
      values['approved_at_ms'] = now;
      values['rejection_reason'] = '';
    }
    if (status == WaTemplateStatus.rejected) {
      values['rejection_reason'] = rejectionReason;
    }
    await db.update(_table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RentWhatsappTemplateRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'updated_at_ms DESC');
    return maps.map(RentWhatsappTemplateRecord.fromMap).toList();
  }

  Future<RentWhatsappTemplateRecord?> getById(int id) async {
    final db = await database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return RentWhatsappTemplateRecord.fromMap(rows.first);
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}

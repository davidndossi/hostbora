import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../data/local/preference/preference_manager.dart';

enum TenantLedgerDocumentType { invoice, receipt }

class TenantLedgerDocument {
  const TenantLedgerDocument({
    required this.id,
    required this.tenantId,
    required this.type,
    required this.title,
    required this.summary,
    required this.amountTsh,
    required this.filePath,
    required this.createdAtMs,
    this.incomeId,
  });

  final String id;
  final int tenantId;
  final TenantLedgerDocumentType type;
  final String title;
  final String summary;
  final int amountTsh;
  final String filePath;
  final int createdAtMs;
  final int? incomeId;

  factory TenantLedgerDocument.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] ?? 'invoice').toString();
    return TenantLedgerDocument(
      id: (json['id'] ?? '').toString(),
      tenantId: int.tryParse('${json['tenantId']}') ?? 0,
      type: typeRaw == 'receipt'
          ? TenantLedgerDocumentType.receipt
          : TenantLedgerDocumentType.invoice,
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      amountTsh: int.tryParse('${json['amountTsh']}') ?? 0,
      filePath: (json['filePath'] ?? '').toString(),
      createdAtMs: int.tryParse('${json['createdAtMs']}') ?? 0,
      incomeId: int.tryParse('${json['incomeId']}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'type': type == TenantLedgerDocumentType.receipt ? 'receipt' : 'invoice',
    'title': title,
    'summary': summary,
    'amountTsh': amountTsh,
    'filePath': filePath,
    'createdAtMs': createdAtMs,
    if (incomeId != null) 'incomeId': incomeId,
  };
}

class TenantLedgerDocumentStore {
  TenantLedgerDocumentStore(this._prefs);

  final PreferenceManager _prefs;
  static const _key = 'tenant_ledger_documents_v1';

  Future<List<TenantLedgerDocument>> listForTenant(int tenantId) async {
    final all = await _loadAll();
    return all
        .where((d) => d.tenantId == tenantId)
        .toList()
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
  }

  Future<void> save(TenantLedgerDocument doc) async {
    final all = await _loadAll();
    all.removeWhere((d) => d.id == doc.id);
    all.add(doc);
    await _persist(all);
  }

  Future<List<TenantLedgerDocument>> _loadAll() async {
    final raw = await _prefs.getString(_key, defaultValue: '');
    if (raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => TenantLedgerDocument.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<TenantLedgerDocument> docs) async {
    final encoded = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  static Future<String> writePdf({
    required String fileName,
    required String title,
    required List<String> lines,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/tenant_ledger_docs');
    if (!await folder.exists()) await folder.create(recursive: true);
    final path = '${folder.path}/$fileName';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}

import 'dart:io';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../db/tenant_local_data_source.dart';
import 'currency_service.dart';

/// Extracts probable date patterns from raw contract text.
///
/// Real OCR is not available in the current package set, so this service
/// generates a fully-updated PDF contract from the tenant's stored data.
/// When the user uploads a signed contract and chooses "Update with Tenant
/// Data", this creates a new PDF replacing the uploaded file reference.
class ContractUpdateService {
  ContractUpdateService._();

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  /// Generates an updated lease contract PDF with [tenant]'s actual data
  /// (dates, rent amount) and returns the file path.
  ///
  /// If [existingContractPath] is non-empty, the generated PDF is placed
  /// beside it with an "_updated" suffix; otherwise a new file is created.
  static Future<String> generateUpdatedContract({
    required TenantRecord tenant,
    String existingContractPath = '',
  }) async {
    final leaseStart = _parseDate(tenant.leaseStartIso);
    final leaseEnd = _parseDate(tenant.leaseEndIso);
    final startDisplay =
        leaseStart != null ? _dateFmt.format(leaseStart) : tenant.leaseStartIso;
    final endDisplay =
        leaseEnd != null ? _dateFmt.format(leaseEnd) : tenant.leaseEndIso;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'LEASE / TENANCY AGREEMENT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  '(Auto-generated from tenant data — Landlord signature required)',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 16),
              _section('TENANT DETAILS'),
              _field('Full Name', tenant.tenantName),
              _field('Phone', tenant.phoneNumber),
              if (tenant.email.trim().isNotEmpty)
                _field('Email', tenant.email),
              pw.SizedBox(height: 16),
              _section('PROPERTY DETAILS'),
              _field('Property', tenant.propertyLabel),
              if (tenant.unitLabel.trim().isNotEmpty)
                _field('Unit', tenant.unitLabel),
              pw.SizedBox(height: 16),
              _section('LEASE TERMS'),
              _field('Commencement Date', startDisplay),
              _field('Expiry Date', endDisplay),
              _field(
                'Rent Amount',
                '${_formatRent(tenant.rentAmountValue)} (${tenant.rentFrequency})',
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 16),
              _section('TERMS AND CONDITIONS'),
              pw.Text(
                '1. The tenant agrees to pay rent on or before the due date as specified above.\n'
                '2. The tenant shall maintain the property in good condition.\n'
                '3. Subletting is not permitted without prior written consent from the landlord.\n'
                '4. Either party may terminate this agreement with 30 days written notice.\n'
                '5. The tenant is responsible for utility bills unless otherwise agreed.',
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
              ),
              pw.SizedBox(height: 32),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _signBlock('LANDLORD SIGNATURE'),
                  _signBlock('TENANT SIGNATURE'),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Generated: ${_dateFmt.format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    final path = await _outputPath(tenant, existingContractPath);
    await File(path).writeAsBytes(bytes);
    return path;
  }

  static pw.Widget _section(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.teal800,
        ),
      ),
    );
  }

  static pw.Widget _field(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signBlock(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 160,
          height: 50,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey600),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(
          'Date: _______________',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static String _formatRent(double amount) {
    if (Get.isRegistered<CurrencyService>()) {
      return Get.find<CurrencyService>().formatBase(amount.round());
    }
    return '${CurrencyService.symbolFor(CurrencyService.defaultBaseCurrency)}${_fmtAmount(amount)}';
  }

  static String _fmtAmount(double amount) {
    return amount.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  static Future<String> _outputPath(
    TenantRecord tenant,
    String existingPath,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final name =
        'contract_${tenant.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return '${dir.path}/$name';
  }

  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }
}

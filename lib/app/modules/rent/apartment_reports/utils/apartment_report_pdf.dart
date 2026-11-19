import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ApartmentRentReportRow {
  const ApartmentRentReportRow({
    required this.date,
    required this.name,
    required this.aptNo,
    required this.floorLabel,
    this.floorIndex,
    required this.rentPerMonth,
    required this.rentSixMonth,
    required this.rentPeriod,
    required this.amtPaid,
    required this.balance,
    required this.startDate,
    required this.expiryDate,
    required this.recipient,
    required this.status,
    required this.contractRemarks,
  });

  final String date;
  final String name;
  final String aptNo;

  /// Display name of the unit floor. Tenants on the same floor share a section.
  final String floorLabel;

  /// Sort key. Null floors are listed after numbered floors.
  final int? floorIndex;
  final String rentPerMonth;
  final String rentSixMonth;
  final String rentPeriod;
  final String amtPaid;
  final String balance;
  final String startDate;
  final String expiryDate;
  final String recipient;
  final String status;
  final String contractRemarks;
}

class ApartmentServiceChargeReportRow {
  const ApartmentServiceChargeReportRow({
    required this.name,
    required this.month,
    required this.amount,
    required this.aptNo,
    required this.datePaid,
  });

  final String name;
  final String month;
  final String amount;
  final String aptNo;
  final String datePaid;
}

class ApartmentReportPdf {
  ApartmentReportPdf._();

  static final _stamp = DateFormat('yyyyMMdd_HHmm');

  static Future<void> shareRentReport({
    required String propertyTitle,
    required String unitFilterLabel,
    required List<ApartmentRentReportRow> rows,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (ctx) => [
          pw.Text(
            'Rent report',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$propertyTitle · $unitFilterLabel',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          _statusLegend(),
          pw.SizedBox(height: 10),
          if (rows.isEmpty)
            pw.Text('No rent rows for this apartment.')
          else
            ..._rentTablesByFloor(rows),
        ],
      ),
    );
    final bytes = await doc.save();
    final name =
        'rent_report_${_slug(propertyTitle)}_${_slug(unitFilterLabel)}_${_stamp.format(DateTime.now())}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  static Future<void> shareServiceChargeReport({
    required String propertyTitle,
    required String unitFilterLabel,
    required List<ApartmentServiceChargeReportRow> rows,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text(
            'Service charge report',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$propertyTitle · $unitFilterLabel',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text('No service charge payments for this apartment.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Name',
                'Month',
                'Amount',
                'Apt no',
                'Date paid',
              ],
              data: rows
                  .map(
                    (r) => [
                      r.name,
                      r.month,
                      r.amount,
                      r.aptNo,
                      r.datePaid,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF004D40),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
            ),
        ],
      ),
    );
    final bytes = await doc.save();
    final name =
        'service_charge_${_slug(propertyTitle)}_${_slug(unitFilterLabel)}_${_stamp.format(DateTime.now())}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  static const _partialBg = PdfColor.fromInt(0xFFFFF3E0);
  static const _partialFg = PdfColor.fromInt(0xFFEF6C00);
  static const _unpaidBg = PdfColor.fromInt(0xFFFFEBEE);
  static const _unpaidFg = PdfColor.fromInt(0xFFC62828);
  static const _statusColumn = 11;

  static List<pw.Widget> _rentTablesByFloor(List<ApartmentRentReportRow> rows) {
    final ordered = [...rows]..sort((a, b) {
        final af = a.floorIndex ?? 1 << 20;
        final bf = b.floorIndex ?? 1 << 20;
        final byFloor = af.compareTo(bf);
        if (byFloor != 0) return byFloor;
        final byApt = a.aptNo.toLowerCase().compareTo(b.aptNo.toLowerCase());
        if (byApt != 0) return byApt;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final groups = <String, List<ApartmentRentReportRow>>{};
    final labels = <String>[];
    for (final row in ordered) {
      final label = row.floorLabel.trim().isEmpty ? 'No floor' : row.floorLabel;
      if (!groups.containsKey(label)) labels.add(label);
      groups.putIfAbsent(label, () => []).add(row);
    }

    final out = <pw.Widget>[];
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final group = groups[label]!;
      if (i > 0) out.add(pw.SizedBox(height: 12));
      out.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE0F2F1),
          ),
          child: pw.Text(
            '$label  ·  ${group.length} ${group.length == 1 ? 'tenant' : 'tenants'}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
      out.add(pw.SizedBox(height: 4));
      out.add(_rentTable(group));
    }
    return out;
  }

  static pw.Widget _rentTable(List<ApartmentRentReportRow> rows) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Date',
        'Name',
        'Apt no',
        'Rent/month',
        'Rent/6 month',
        'Rent period',
        'Amt paid',
        'Balance',
        'Start date',
        'Expiry date',
        'Recipient',
        'Status',
        'Contract remarks',
      ],
      data: rows
          .map(
            (r) => [
              r.date,
              r.name,
              r.aptNo,
              r.rentPerMonth,
              r.rentSixMonth,
              r.rentPeriod,
              r.amtPaid,
              r.balance,
              r.startDate,
              r.expiryDate,
              r.recipient,
              r.status,
              r.contractRemarks,
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF004D40),
      ),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellDecoration: (col, data, rowNum) {
        final status = rows[rowNum - 1].status.trim().toUpperCase();
        if (status == 'PARTIAL') {
          return const pw.BoxDecoration(color: _partialBg);
        }
        if (status == 'NOT PAID') {
          return const pw.BoxDecoration(color: _unpaidBg);
        }
        return const pw.BoxDecoration();
      },
      textStyleBuilder: (col, data, rowNum) {
        if (col != _statusColumn) return const pw.TextStyle(fontSize: 7);
        final status = rows[rowNum - 1].status.trim().toUpperCase();
        if (status == 'PARTIAL') {
          return pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: _partialFg,
          );
        }
        if (status == 'NOT PAID') {
          return pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: _unpaidFg,
          );
        }
        return const pw.TextStyle(fontSize: 7);
      },
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    );
  }

  static pw.Widget _statusLegend() {
    pw.Widget item(PdfColor bg, PdfColor fg, String label) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: fg,
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        item(_partialBg, _partialFg, 'PARTIAL'),
        pw.SizedBox(width: 8),
        item(_unpaidBg, _unpaidFg, 'NOT PAID'),
      ],
    );
  }

  /// Optional local copy for debugging / future open-in-app.
  static Future<String> writeTempBytes(List<int> bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _slug(String raw) {
    final s = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return s.isEmpty ? 'unit' : s;
  }
}

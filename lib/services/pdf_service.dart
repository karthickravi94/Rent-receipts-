import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/receipt.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  Future<File> generateReceipt(
      Receipt receipt, String adminName, String adminPhone) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(adminName, adminPhone),
            pw.SizedBox(height: 16),
            _divider(),
            pw.SizedBox(height: 10),
            _title(receipt),
            pw.SizedBox(height: 10),
            _divider(),
            pw.SizedBox(height: 12),
            _receiptMeta(receipt),
            pw.SizedBox(height: 12),
            _infoSection(receipt),
            pw.SizedBox(height: 14),
            _chargesTable(receipt),
            pw.SizedBox(height: 14),
            _totalBox(receipt),
            if (receipt.gpayNumber.isNotEmpty || receipt.phonePeNumber.isNotEmpty) ...
              [pw.SizedBox(height: 12), _paymentDetails(receipt)],
            if (receipt.advanceAmount > 0) ...
              [pw.SizedBox(height: 12), _advanceInfo(receipt)],
            if (receipt.notes.isNotEmpty) ...
              [pw.SizedBox(height: 12), _notes(receipt)],
            pw.SizedBox(height: 24),
            _divider(),
            pw.SizedBox(height: 16),
            _footer(),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!receiptsDir.existsSync()) receiptsDir.createSync(recursive: true);

    final safeName = receipt.tenantName.replaceAll(RegExp(r'[^\w]'), '_');
    final file = File(
        '${receiptsDir.path}/receipt_${safeName}_${receipt.month}_${receipt.year}_${receipt.id.substring(0, 6)}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _header(String name, String phone) => pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo800,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Rent Receipt Manager',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 3),
                pw.Text('Professional Rental Management',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.indigo100)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (name.isNotEmpty)
                  pw.Text(name,
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                if (phone.isNotEmpty)
                  pw.Text(phone,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.indigo100)),
              ],
            ),
          ],
        ),
      );

  pw.Widget _title(Receipt receipt) => pw.Column(
        children: [
          pw.Center(
            child: pw.Text('RENT RECEIPT',
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800)),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
                'For the month of ${receipt.month} ${receipt.year}',
                style: const pw.TextStyle(
                    fontSize: 12, color: PdfColors.grey700)),
          ),
        ],
      );

  pw.Widget _receiptMeta(Receipt receipt) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
              'Receipt No: #${receipt.id.substring(0, 8).toUpperCase()}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(
              'Date: ${DateFormat('dd MMM yyyy').format(receipt.generatedAt)}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      );

  pw.Widget _infoSection(Receipt receipt) => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _sectionLabel('TENANT DETAILS'),
                  pw.SizedBox(height: 6),
                  _infoRow('Name', receipt.tenantName),
                  _infoRow('Phone', receipt.tenantPhone),
                  if (receipt.tenantEmail.isNotEmpty)
                    _infoRow('Email', receipt.tenantEmail),
                ],
              ),
            ),
            pw.Container(
                width: 1,
                height: 80,
                color: PdfColors.grey300,
                margin: const pw.EdgeInsets.symmetric(horizontal: 12)),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _sectionLabel('PROPERTY DETAILS'),
                  pw.SizedBox(height: 6),
                  _infoRow('Property', receipt.houseName),
                  _infoRow('Period',
                      '${receipt.month} ${receipt.year}'),
                ],
              ),
            ),
          ],
        ),
      );

  pw.Widget _sectionLabel(String text) => pw.Text(text,
      style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.indigo800));

  pw.Widget _infoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: 55,
                child: pw.Text('$label:',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700))),
            pw.Expanded(
                child: pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold))),
          ],
        ),
      );

  pw.Widget _chargesTable(Receipt receipt) {
    final rows = <pw.TableRow>[_tableHeader()];
    void addRow(String label, double amount, bool alt) {
      if (amount > 0) rows.add(_tableRow(label, amount, alt));
    }

    addRow('Base Rent', receipt.rentAmount, false);
    if (receipt.milkCharge > 0)
      addRow('Milk Charge', receipt.milkCharge, rows.length.isOdd);
    if (receipt.electricityCharge > 0)
      addRow('Electricity', receipt.electricityCharge, rows.length.isOdd);
    if (receipt.waterCharge > 0)
      addRow('Water Charge', receipt.waterCharge, rows.length.isOdd);
    if (receipt.otherCharges > 0)
      addRow('Other Charges', receipt.otherCharges, rows.length.isOdd);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  pw.TableRow _tableHeader() => pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.indigo800),
        children: [
          _cell('Description', isHeader: true),
          _cell('Amount', isHeader: true, right: true),
        ],
      );

  pw.TableRow _tableRow(String desc, double amount, bool alt) =>
      pw.TableRow(
        decoration:
            pw.BoxDecoration(color: alt ? PdfColors.indigo50 : PdfColors.white),
        children: [
          _cell(desc),
          _cell(_currency.format(amount), right: true),
        ],
      );

  pw.Widget _cell(String text, {bool isHeader = false, bool right = false}) =>
      pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment:
            right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight:
                    isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isHeader ? PdfColors.white : PdfColors.black)),
      );

  pw.Widget _totalBox(Receipt receipt) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo800,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL AMOUNT DUE',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
            pw.Text(_currency.format(receipt.totalAmount),
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.yellow200)),
          ],
        ),
      );

  pw.Widget _paymentDetails(Receipt receipt) => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          border: pw.Border.all(color: PdfColors.green700),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PAYMENT DETAILS',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                if (receipt.gpayNumber.isNotEmpty)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Google Pay (GPay)',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(receipt.gpayNumber,
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                if (receipt.phonePeNumber.isNotEmpty)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PhonePe',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(receipt.phonePeNumber,
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  pw.Widget _advanceInfo(Receipt receipt) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.orange50,
          border: pw.Border.all(color: PdfColors.orange700, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ADVANCE / SECURITY DEPOSIT',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900)),
                pw.SizedBox(height: 3),
                pw.Text('Held by landlord (for reference only)',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
            pw.Text(_currency.format(receipt.advanceAmount),
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange900)),
          ],
        ),
      );

  pw.Widget _notes(Receipt receipt) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('NOTES',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(receipt.notes,
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
          ],
        ),
      );

  pw.Widget _footer() => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _signatureBlock('Tenant Signature'),
          _signatureBlock('Landlord Signature'),
        ],
      );

  pw.Widget _signatureBlock(String label) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 24),
          pw.Container(width: 130, height: 1, color: PdfColors.black),
        ],
      );

  pw.Widget _divider() =>
      pw.Container(height: 1, color: PdfColors.grey300);
}

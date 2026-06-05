import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/receipt.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // PDF fonts don't support the Rs. symbol (Unicode U+20B9), use "Rs." instead
  String _fmt(double amount) =>
      'Rs. ${amount.toStringAsFixed(2)}';

  Future<Uint8List> generateReceipt(
      Receipt receipt, String adminName, String adminPhone) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(adminName, adminPhone),
            pw.SizedBox(height: 20),
            _titleSection(receipt),
            pw.SizedBox(height: 16),
            _divider(),
            pw.SizedBox(height: 12),
            _metaRow(receipt),
            pw.SizedBox(height: 14),
            _infoSection(receipt),
            pw.SizedBox(height: 16),
            _chargesTable(receipt),
            pw.SizedBox(height: 14),
            _totalBox(receipt),
            if (receipt.gpayNumber.isNotEmpty ||
                receipt.phonePeNumber.isNotEmpty) ...[pw.SizedBox(height: 12), _paymentDetails(receipt)],
            if (receipt.advanceAmount > 0) ...[pw.SizedBox(height: 12), _advanceInfo(receipt)],
            if (receipt.notes.isNotEmpty) ...[pw.SizedBox(height: 12), _notesBox(receipt)],
            pw.Spacer(),
            _divider(),
            pw.SizedBox(height: 18),
            _footer(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _header(String name, String phone) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo800,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Rent Receipt Manager',
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text('Professional Rental Management',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.indigo100)),
              ],
            ),
            if (name.isNotEmpty || phone.isNotEmpty)
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

  pw.Widget _titleSection(Receipt receipt) => pw.Column(
        children: [
          pw.Center(
            child: pw.Text('RENT RECEIPT',
                style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800,
                    letterSpacing: 2)),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(20)),
              ),
              child: pw.Text(
                  'For the month of ${receipt.month} ${receipt.year}',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.indigo800)),
            ),
          ),
        ],
      );

  pw.Widget _metaRow(Receipt receipt) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _badge(
              'Receipt No: #${receipt.id.substring(0, 8).toUpperCase()}'),
          _badge('Date: ${_formatDate(receipt.generatedAt)}'),
        ],
      );

  pw.Widget _badge(String text) => pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(text,
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey800)),
      );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} '
      '${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][d.month - 1]} '
      '${d.year}';

  pw.Widget _infoSection(Receipt receipt) => pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(14),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('TENANT DETAILS', PdfColors.indigo800),
                    pw.SizedBox(height: 8),
                    _infoRow('Name', receipt.tenantName),
                    _infoRow('Phone', receipt.tenantPhone),
                    if (receipt.tenantEmail.isNotEmpty)
                      _infoRow('Email', receipt.tenantEmail),
                  ],
                ),
              ),
            ),
            pw.Container(
                width: 1,
                color: PdfColors.grey300,
                margin:
                    const pw.EdgeInsets.symmetric(vertical: 14)),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(14),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('PROPERTY DETAILS', PdfColors.indigo800),
                    pw.SizedBox(height: 8),
                    _infoRow('Property', receipt.houseName),
                    _infoRow('Period',
                        '${receipt.month} ${receipt.year}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  pw.Widget _sectionLabel(String text, PdfColor color) => pw.Text(text,
      style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 0.5));

  pw.Widget _infoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: 55,
                child: pw.Text('$label:',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600))),
            pw.Expanded(
                child: pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black))),
          ],
        ),
      );

  pw.Widget _chargesTable(Receipt receipt) {
    final rows = <pw.TableRow>[_tableHeader()];
    int rowIndex = 0;
    void add(String label, double amount) {
      if (amount > 0) {
        rows.add(_tableRow(label, amount, rowIndex.isEven));
        rowIndex++;
      }
    }

    add('Base Rent', receipt.rentAmount);
    add('Milk Charge', receipt.milkCharge);
    add('Electricity', receipt.electricityCharge);
    add('Water Charge', receipt.waterCharge);
    add('Other Charges', receipt.otherCharges);

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
        decoration:
            const pw.BoxDecoration(color: PdfColors.indigo800),
        children: [
          _cell('Description', isHeader: true),
          _cell('Amount', isHeader: true, right: true),
        ],
      );

  pw.TableRow _tableRow(String desc, double amount, bool alt) =>
      pw.TableRow(
        decoration: pw.BoxDecoration(
            color: alt ? PdfColors.indigo50 : PdfColors.white),
        children: [
          _cell(desc),
          _cell(_fmt(amount), right: true),
        ],
      );

  pw.Widget _cell(String text,
          {bool isHeader = false, bool right = false}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        alignment:
            right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: isHeader
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
                color: isHeader ? PdfColors.white : PdfColors.black)),
      );

  pw.Widget _totalBox(Receipt receipt) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo800,
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL AMOUNT DUE',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1)),
            pw.Text(_fmt(receipt.totalAmount),
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.yellow200)),
          ],
        ),
      );

  pw.Widget _paymentDetails(Receipt receipt) => pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          border: pw.Border.all(color: PdfColors.green700),
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionLabel('PAYMENT DETAILS', PdfColors.green800),
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
                                fontSize: 10,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(receipt.gpayNumber,
                            style: pw.TextStyle(
                                fontSize: 13,
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
                                fontSize: 10,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(receipt.phonePeNumber,
                            style: pw.TextStyle(
                                fontSize: 13,
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
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.orange50,
          border: pw.Border.all(color: PdfColors.orange700, width: 0.5),
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionLabel(
                    'ADVANCE / SECURITY DEPOSIT', PdfColors.orange900),
                pw.SizedBox(height: 3),
                pw.Text('Held by landlord (for reference only)',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Text(_fmt(receipt.advanceAmount),
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange900)),
          ],
        ),
      );

  pw.Widget _notesBox(Receipt receipt) => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionLabel('NOTES', PdfColors.grey700),
            pw.SizedBox(height: 5),
            pw.Text(receipt.notes,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.black)),
          ],
        ),
      );

  pw.Widget _footer() => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _sig('Tenant Signature'),
          _sig('Landlord Signature'),
        ],
      );

  pw.Widget _sig(String label) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 28),
          pw.Container(width: 140, height: 1, color: PdfColors.black),
        ],
      );

  pw.Widget _divider() =>
      pw.Container(height: 1, color: PdfColors.grey300);
}

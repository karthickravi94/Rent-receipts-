import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/receipt.dart';
import '../models/tenant.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';

class ReceiptProvider extends ChangeNotifier {
  final _firestoreService = FirestoreService();
  final _pdfService = PdfService();

  List<Receipt> _receipts = [];
  bool _isGenerating = false;
  String? _error;
  Uint8List? _lastPdfBytes;
  String _lastPdfFilename = 'rent_receipt.pdf';
  Receipt? _lastReceipt;

  List<Receipt> get receipts => _receipts;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  Uint8List? get lastPdfBytes => _lastPdfBytes;
  String get lastPdfFilename => _lastPdfFilename;
  Receipt? get lastReceipt => _lastReceipt;

  ReceiptProvider() {
    _firestoreService.getReceipts().listen(
      (list) {
        _receipts = list;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<Uint8List?> generateAndSave({
    required Tenant tenant,
    required double milkCharge,
    required double electricityCharge,
    required double waterCharge,
    required double otherCharges,
    required String notes,
    required String month,
    required int year,
    required String adminName,
    required String adminPhone,
    required String receiptId,
  }) async {
    try {
      _isGenerating = true;
      _error = null;
      notifyListeners();

      final total = tenant.monthlyRent +
          milkCharge +
          electricityCharge +
          waterCharge +
          otherCharges;

      final receipt = Receipt(
        id: receiptId,
        tenantId: tenant.id,
        tenantName: tenant.name,
        tenantPhone: tenant.phone,
        tenantEmail: tenant.email,
        houseName: tenant.houseName,
        rentAmount: tenant.monthlyRent,
        milkCharge: milkCharge,
        electricityCharge: electricityCharge,
        waterCharge: waterCharge,
        otherCharges: otherCharges,
        notes: notes,
        totalAmount: total,
        advanceAmount: tenant.advanceAmount,
        gpayNumber: tenant.gpayNumber,
        phonePeNumber: tenant.phonePeNumber,
        month: month,
        year: year,
        generatedAt: DateTime.now(),
      );

      await _firestoreService.addReceipt(receipt);
      _lastReceipt = receipt;

      final safeName = tenant.name.replaceAll(RegExp(r'[^\w]'), '_');
      _lastPdfFilename = 'receipt_${safeName}_${month}_$year.pdf';

      final bytes =
          await _pdfService.generateReceipt(receipt, adminName, adminPhone);
      _lastPdfBytes = bytes;
      return bytes;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> regeneratePdf(
      Receipt receipt, String adminName, String adminPhone) async {
    try {
      _isGenerating = true;
      notifyListeners();
      final bytes =
          await _pdfService.generateReceipt(receipt, adminName, adminPhone);
      _lastPdfBytes = bytes;
      _lastReceipt = receipt;
      final safeName =
          receipt.tenantName.replaceAll(RegExp(r'[^\w]'), '_');
      _lastPdfFilename =
          'receipt_${safeName}_${receipt.month}_${receipt.year}.pdf';
      return bytes;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> downloadOrShare(Uint8List bytes, {String? filename}) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename ?? _lastPdfFilename,
    );
  }

  // Shares PDF via native share sheet (iOS/Android) so user can pick Mail
  // and get the PDF attached. Falls back to download + mailto on desktop.
  Future<void> shareViaEmail(
      Receipt receipt, Uint8List bytes, String filename) async {
    final subject = 'Rent Receipt - ${receipt.month} ${receipt.year}';
    final body = _buildEmailBody(receipt);

    bool sharedWithFile = false;

    if (kIsWeb) {
      try {
        final xFile =
            XFile.fromData(bytes, mimeType: 'application/pdf', name: filename);
        await Share.shareXFiles([xFile], subject: subject, text: body);
        sharedWithFile = true;
      } catch (_) {
        // Web Share API with files not supported; fall through
      }
    } else {
      final xFile =
          XFile.fromData(bytes, mimeType: 'application/pdf', name: filename);
      await Share.shareXFiles([xFile], subject: subject, text: body);
      sharedWithFile = true;
    }

    if (!sharedWithFile) {
      // Desktop fallback: download the PDF then open email client
      await Printing.sharePdf(bytes: bytes, filename: filename);
      if (receipt.tenantEmail.isNotEmpty) {
        final encodedSubject = Uri.encodeComponent(subject);
        final encodedBody = Uri.encodeComponent(body);
        final uri = Uri.parse(
            'mailto:${receipt.tenantEmail}?subject=$encodedSubject&body=$encodedBody');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    }
  }

  String _buildEmailBody(Receipt receipt) {
    final lines = [
      'Dear ${receipt.tenantName},',
      '',
      'Please find your rent receipt for ${receipt.month} ${receipt.year}.',
      '',
      'House: ${receipt.houseName}',
      'Base Rent: Rs.${receipt.rentAmount.toStringAsFixed(2)}',
      if (receipt.milkCharge > 0)
        'Milk Charge: Rs.${receipt.milkCharge.toStringAsFixed(2)}',
      if (receipt.electricityCharge > 0)
        'Electricity: Rs.${receipt.electricityCharge.toStringAsFixed(2)}',
      if (receipt.waterCharge > 0)
        'Water Charge: Rs.${receipt.waterCharge.toStringAsFixed(2)}',
      if (receipt.otherCharges > 0)
        'Other Charges: Rs.${receipt.otherCharges.toStringAsFixed(2)}',
      '',
      'TOTAL AMOUNT DUE: Rs.${receipt.totalAmount.toStringAsFixed(2)}',
      '',
      if (receipt.gpayNumber.isNotEmpty) 'GPay: ${receipt.gpayNumber}',
      if (receipt.phonePeNumber.isNotEmpty)
        'PhonePe: ${receipt.phonePeNumber}',
      '',
      'Regards',
    ];
    return lines.join('\n');
  }

  Future<void> openWhatsApp(String phone, Receipt receipt) async {
    final lines = [
      'Hi ${receipt.tenantName},',
      '',
      'Your rent receipt for ${receipt.month} ${receipt.year} is ready.',
      '',
      'House: ${receipt.houseName}',
      'Base Rent: Rs.${receipt.rentAmount.toStringAsFixed(2)}',
      if (receipt.milkCharge > 0)
        'Milk: Rs.${receipt.milkCharge.toStringAsFixed(2)}',
      if (receipt.electricityCharge > 0)
        'Electricity: Rs.${receipt.electricityCharge.toStringAsFixed(2)}',
      if (receipt.waterCharge > 0)
        'Water: Rs.${receipt.waterCharge.toStringAsFixed(2)}',
      if (receipt.otherCharges > 0)
        'Other: Rs.${receipt.otherCharges.toStringAsFixed(2)}',
      '',
      'Total: Rs.${receipt.totalAmount.toStringAsFixed(2)}',
    ];

    final msg = Uri.encodeComponent(lines.join('\n'));
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> deleteReceipt(String id) async {
    try {
      await _firestoreService.deleteReceipt(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  List<Receipt> filtered({String? tenantId, String? month, int? year}) =>
      _receipts.where((r) {
        if (tenantId != null && r.tenantId != tenantId) return false;
        if (month != null && r.month != month) return false;
        if (year != null && r.year != year) return false;
        return true;
      }).toList();

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

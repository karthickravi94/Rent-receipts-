import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
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

  List<Receipt> get receipts => _receipts;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  Uint8List? get lastPdfBytes => _lastPdfBytes;
  String get lastPdfFilename => _lastPdfFilename;

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

  // Works on all platforms:
  //   Web   → downloads the PDF file to the browser downloads folder
  //   Mobile → opens native share sheet (WhatsApp, Drive, Email, etc.)
  Future<void> downloadOrShare(Uint8List bytes, {String? filename}) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename ?? _lastPdfFilename,
    );
  }

  // Opens the device/browser mail client with pre-filled subject & body.
  Future<void> shareViaEmail(Receipt receipt, String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Rent Receipt – ${receipt.month} ${receipt.year}',
        'body':
            'Dear ${receipt.tenantName},\n\n'
            'Please find your rent receipt for ${receipt.month} ${receipt.year}.\n\n'
            'Total Amount Due: ₹${receipt.totalAmount.toStringAsFixed(2)}\n\n'
            'Regards',
      },
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // On web: opens WhatsApp Web. On mobile: opens WhatsApp app.
  Future<void> openWhatsApp(String phone, Receipt receipt) async {
    final msg = Uri.encodeComponent(
        'Hi ${receipt.tenantName}, your rent receipt for '
        '${receipt.month} ${receipt.year} is ready. '
        'Total: ₹${receipt.totalAmount.toStringAsFixed(2)}');
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

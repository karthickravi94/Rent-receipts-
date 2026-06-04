import 'dart:io';
import 'package:flutter/foundation.dart';
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
  File? _lastGeneratedPdf;

  List<Receipt> get receipts => _receipts;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  File? get lastGeneratedPdf => _lastGeneratedPdf;

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

  Future<File?> generateAndSave({
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
      final pdf = await _pdfService.generateReceipt(receipt, adminName, adminPhone);
      _lastGeneratedPdf = pdf;
      return pdf;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<File?> regeneratePdf(
      Receipt receipt, String adminName, String adminPhone) async {
    try {
      _isGenerating = true;
      notifyListeners();
      final pdf =
          await _pdfService.generateReceipt(receipt, adminName, adminPhone);
      _lastGeneratedPdf = pdf;
      return pdf;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> shareFile(File pdfFile, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: subject ?? 'Rent Receipt',
      text: 'Please find your rent receipt attached.',
    );
  }

  Future<void> shareViaEmail(
      File pdfFile, Receipt receipt, String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Rent Receipt – ${receipt.month} ${receipt.year}',
        'body':
            'Dear ${receipt.tenantName},\n\nPlease find your rent receipt for ${receipt.month} ${receipt.year} attached.\n\nTotal Amount Due: ₹${receipt.totalAmount.toStringAsFixed(2)}\n\nRegards',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await shareFile(pdfFile,
          subject: 'Rent Receipt – ${receipt.month} ${receipt.year}');
    }
  }

  Future<void> shareViaWhatsApp(File pdfFile, String phone) async {
    // Opens the native share sheet which includes WhatsApp.
    await shareFile(pdfFile);
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

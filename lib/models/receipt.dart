import 'package:cloud_firestore/cloud_firestore.dart';

class Receipt {
  final String id;
  final String tenantId;
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final String houseName;
  final double rentAmount;
  final double milkCharge;
  final double electricityCharge;
  final double waterCharge;
  final double otherCharges;
  final String notes;
  final double totalAmount;
  final double advanceAmount;
  final String gpayNumber;
  final String phonePeNumber;
  final String month;
  final int year;
  final DateTime generatedAt;

  const Receipt({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.houseName,
    required this.rentAmount,
    required this.milkCharge,
    required this.electricityCharge,
    required this.waterCharge,
    required this.otherCharges,
    required this.notes,
    required this.totalAmount,
    required this.advanceAmount,
    required this.gpayNumber,
    required this.phonePeNumber,
    required this.month,
    required this.year,
    required this.generatedAt,
  });

  factory Receipt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Receipt(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      tenantName: data['tenantName'] ?? '',
      tenantPhone: data['tenantPhone'] ?? '',
      tenantEmail: data['tenantEmail'] ?? '',
      houseName: data['houseName'] ?? '',
      rentAmount: (data['rentAmount'] ?? 0).toDouble(),
      milkCharge: (data['milkCharge'] ?? 0).toDouble(),
      electricityCharge: (data['electricityCharge'] ?? 0).toDouble(),
      waterCharge: (data['waterCharge'] ?? 0).toDouble(),
      otherCharges: (data['otherCharges'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      advanceAmount: (data['advanceAmount'] ?? 0).toDouble(),
      gpayNumber: data['gpayNumber'] ?? '',
      phonePeNumber: data['phonePeNumber'] ?? '',
      month: data['month'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      generatedAt:
          (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'tenantId': tenantId,
        'tenantName': tenantName,
        'tenantPhone': tenantPhone,
        'tenantEmail': tenantEmail,
        'houseName': houseName,
        'rentAmount': rentAmount,
        'milkCharge': milkCharge,
        'electricityCharge': electricityCharge,
        'waterCharge': waterCharge,
        'otherCharges': otherCharges,
        'notes': notes,
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
        'gpayNumber': gpayNumber,
        'phonePeNumber': phonePeNumber,
        'month': month,
        'year': year,
        'generatedAt': Timestamp.fromDate(generatedAt),
      };
}

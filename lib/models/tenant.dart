import 'package:cloud_firestore/cloud_firestore.dart';

class Tenant {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String houseName;
  final double monthlyRent;
  final double advanceAmount;
  final String gpayNumber;
  final String phonePeNumber;
  final DateTime createdAt;

  const Tenant({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.houseName,
    required this.monthlyRent,
    required this.advanceAmount,
    required this.gpayNumber,
    required this.phonePeNumber,
    required this.createdAt,
  });

  factory Tenant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tenant(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      houseName: data['houseName'] ?? '',
      monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
      advanceAmount: (data['advanceAmount'] ?? 0).toDouble(),
      gpayNumber: data['gpayNumber'] ?? '',
      phonePeNumber: data['phonePeNumber'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'email': email,
        'houseName': houseName,
        'monthlyRent': monthlyRent,
        'advanceAmount': advanceAmount,
        'gpayNumber': gpayNumber,
        'phonePeNumber': phonePeNumber,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Tenant copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? houseName,
    double? monthlyRent,
    double? advanceAmount,
    String? gpayNumber,
    String? phonePeNumber,
    DateTime? createdAt,
  }) =>
      Tenant(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        houseName: houseName ?? this.houseName,
        monthlyRent: monthlyRent ?? this.monthlyRent,
        advanceAmount: advanceAmount ?? this.advanceAmount,
        gpayNumber: gpayNumber ?? this.gpayNumber,
        phonePeNumber: phonePeNumber ?? this.phonePeNumber,
        createdAt: createdAt ?? this.createdAt,
      );
}

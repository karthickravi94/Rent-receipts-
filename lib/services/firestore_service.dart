import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant.dart';
import '../models/receipt.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _tenants => _db.collection('tenants');
  CollectionReference get _receipts => _db.collection('receipts');

  // ── Tenants ──────────────────────────────────────────────────────────────

  Stream<List<Tenant>> getTenants() => _tenants
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Tenant.fromFirestore).toList());

  Future<void> addTenant(Tenant tenant) =>
      _tenants.doc(tenant.id).set(tenant.toFirestore());

  Future<void> updateTenant(Tenant tenant) =>
      _tenants.doc(tenant.id).update(tenant.toFirestore());

  Future<void> deleteTenant(String id) => _tenants.doc(id).delete();

  // ── Receipts ─────────────────────────────────────────────────────────────

  Stream<List<Receipt>> getReceipts() => _receipts
      .orderBy('generatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Receipt.fromFirestore).toList());

  Future<void> addReceipt(Receipt receipt) =>
      _receipts.doc(receipt.id).set(receipt.toFirestore());

  Future<void> deleteReceipt(String id) => _receipts.doc(id).delete();

  // ── Dashboard stats ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final currentMonth = _monthName(now.month);

    final tenantsSnap = await _tenants.get();
    final receiptsSnap = await _receipts
        .where('month', isEqualTo: currentMonth)
        .where('year', isEqualTo: now.year)
        .get();

    double totalMonthlyRent = 0;
    for (final doc in tenantsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalMonthlyRent += (data['monthlyRent'] ?? 0).toDouble();
    }

    return {
      'tenantCount': tenantsSnap.docs.length,
      'totalMonthlyRent': totalMonthlyRent,
      'receiptsThisMonth': receiptsSnap.docs.length,
    };
  }

  static String _monthName(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][month - 1];
}

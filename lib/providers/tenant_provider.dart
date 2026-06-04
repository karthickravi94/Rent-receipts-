import 'package:flutter/foundation.dart';
import '../models/tenant.dart';
import '../services/firestore_service.dart';

class TenantProvider extends ChangeNotifier {
  final _service = FirestoreService();

  List<Tenant> _tenants = [];
  bool _isLoading = false;
  String? _error;

  List<Tenant> get tenants => _tenants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TenantProvider() {
    _service.getTenants().listen(
      (list) {
        _tenants = list;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<bool> addTenant(Tenant tenant) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _service.addTenant(tenant);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTenant(Tenant tenant) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _service.updateTenant(tenant);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTenant(String tenantId) async {
    try {
      await _service.deleteTenant(tenantId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

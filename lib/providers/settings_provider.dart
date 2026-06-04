import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _adminName = '';
  String _adminPhone = '';
  bool _darkMode = false;

  String get adminName => _adminName;
  String get adminPhone => _adminPhone;
  bool get darkMode => _darkMode;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _adminName = p.getString('adminName') ?? '';
    _adminPhone = p.getString('adminPhone') ?? '';
    _darkMode = p.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> save({
    required String adminName,
    required String adminPhone,
    required bool darkMode,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('adminName', adminName);
    await p.setString('adminPhone', adminPhone);
    await p.setBool('darkMode', darkMode);
    _adminName = adminName;
    _adminPhone = adminPhone;
    _darkMode = darkMode;
    notifyListeners();
  }
}

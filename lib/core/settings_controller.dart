import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _showUsedKey = 'show_used_coupons';
  static const _darkThemeKey = 'dark_theme';
  static const _openOnTapKey = 'open_coupon_on_tap';

  bool _showUsedCoupons = true;
  bool _darkTheme = false;
  bool _openOnTap = true;

  bool get openOnTap => _openOnTap;

  bool get showUsedCoupons => _showUsedCoupons;

  bool get darkTheme => _darkTheme;

  late final SharedPreferences _prefs;

  SettingsController() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    _showUsedCoupons = _prefs.getBool(_showUsedKey) ?? true;
    _darkTheme = _prefs.getBool(_darkThemeKey) ?? false;
    _openOnTap = _prefs.getBool(_openOnTapKey) ?? true;

    notifyListeners();
  }

  Future<void> setOpenOnTap(bool value) async {
    _openOnTap = value;
    await _prefs.setBool(_openOnTapKey, value);
    notifyListeners();
  }

  Future<void> setShowUsedCoupons(bool value) async {
    _showUsedCoupons = value;
    await _prefs.setBool(_showUsedKey, value);
    notifyListeners();
  }

  Future<void> setDarkTheme(bool value) async {
    _darkTheme = value;
    await _prefs.setBool(_darkThemeKey, value);
    notifyListeners();
  }
}

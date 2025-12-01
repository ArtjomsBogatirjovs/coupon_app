import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _showUsedKey = 'show_used_coupons';
  static const _darkThemeKey = 'dark_theme';
  static const _openOnTapKey = 'open_coupon_on_tap';
  static const _infiniteGmailKey = 'infinite_gmail';
  static const _rememberEmailKey = 'remember_email';
  static const _savedEmailKey = 'saved_email';

  bool _infiniteGmail = false;
  bool _showUsedCoupons = true;
  bool _darkTheme = false;
  bool _openOnTap = true;
  bool _rememberEmail = false;
  String? _savedEmail;

  bool get openOnTap => _openOnTap;

  bool get showUsedCoupons => _showUsedCoupons;

  bool get darkTheme => _darkTheme;

  bool get infiniteGmail => _infiniteGmail;

  bool get rememberEmail => _rememberEmail;

  String? get savedEmail => _savedEmail;
  final SharedPreferences _prefs;

  SettingsController(this._prefs) {
    _init();
  }

  Future<void> _init() async {
    _showUsedCoupons = _prefs.getBool(_showUsedKey) ?? true;
    _darkTheme = _prefs.getBool(_darkThemeKey) ?? false;
    _openOnTap = _prefs.getBool(_openOnTapKey) ?? true;
    _infiniteGmail = _prefs.getBool(_infiniteGmailKey) ?? true;
    _rememberEmail = _prefs.getBool(_rememberEmailKey) ?? false;
    _savedEmail = _prefs.getString(_savedEmailKey);

    notifyListeners();
  }

  Future<void> setInfiniteGmail(bool value) async {
    _infiniteGmail = value;
    await _prefs.setBool(_infiniteGmailKey, value);
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

  Future<void> setRememberEmail(bool value) async {
    _rememberEmail = value;
    await _prefs.setBool(_rememberEmailKey, value);
    if (!value) {
      _savedEmail = null;
      await _prefs.remove(_savedEmailKey);
    }
    notifyListeners();
  }

  Future<void> setSavedEmail(String? email) async {
    _savedEmail = email;
    if (email == null || email.isEmpty) {
      await _prefs.remove(_savedEmailKey);
    } else {
      await _prefs.setString(_savedEmailKey, email);
    }
    notifyListeners();
  }
}

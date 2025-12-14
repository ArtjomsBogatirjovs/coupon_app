import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _showUsedKey = 'show_used_coupons';
  static const _showLogsKey = 'show_logs';
  static const _logsEnabledKey = 'logs_enabled';
  static const _openOnTapKey = 'open_coupon_on_tap';
  static const _infiniteGmailKey = 'infinite_gmail';
  static const _rememberEmailKey = 'remember_email';
  static const _savedEmailKey = 'saved_email';

  bool _infiniteGmail = false;
  bool _showUsedCoupons = true;
  bool _showLogs = false;
  bool _logsEnabled = true;
  bool _openOnTap = true;
  bool _rememberEmail = false;
  String? _savedEmail;

  bool get openOnTap => _openOnTap;

  bool get showUsedCoupons => _showUsedCoupons;

  bool get showLogs => _showLogs;

  bool get logsEnabled => _logsEnabled;

  bool get infiniteGmail => _infiniteGmail;

  bool get rememberEmail => _rememberEmail;

  String? get savedEmail => _savedEmail;
  final SharedPreferences _prefs;

  SettingsController(this._prefs) {
    _init();
  }

  Future<void> _init() async {
    _showUsedCoupons = _prefs.getBool(_showUsedKey) ?? _showUsedCoupons;
    _openOnTap = _prefs.getBool(_openOnTapKey) ?? _openOnTap;
    _infiniteGmail = _prefs.getBool(_infiniteGmailKey) ?? _infiniteGmail;
    _rememberEmail = _prefs.getBool(_rememberEmailKey) ?? _rememberEmail;
    _savedEmail = _prefs.getString(_savedEmailKey);
    _logsEnabled = _prefs.getBool(_logsEnabledKey) ?? _logsEnabled;
    _showLogs = _prefs.getBool(_showLogsKey) ?? _showLogs;

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

  Future<void> setShowLogs(bool value) async {
    _showLogs = value;
    await _prefs.setBool(_showLogsKey, value);
    notifyListeners();
  }

  Future<void> setEnabledLogs(bool value) async {
    _logsEnabled = value;
    await _prefs.setBool(_logsEnabledKey, value);
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

import 'dart:convert';
import 'package:coupon_app/core/logs_controller.dart';

import 'app_error.dart';
import 'log_level.dart';
import 'log_record.dart';
import 'logs_repository.dart';

class AppLogger {
  final LogsRepository _logsRepo;
  final LogsController _logsController;
  bool _enabled;

  AppLogger._(this._logsRepo, this._logsController, {bool enabled = true})
    : _enabled = enabled;

  static AppLogger? _instance;

  static void init(
    LogsRepository logs,
    LogsController logsController, {
    bool enabled = true,
  }) {
    _instance ??= AppLogger._(logs, logsController, enabled: enabled);
  }

  static AppLogger get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('AppLogger not initialized');
    }
    return inst;
  }

  void setEnabled(bool value) {
    _enabled = value;
  }

  bool get _isEnabled => _enabled;

  ScopedLogger getLogger({required LogCategory category, String? source}) {
    return ScopedLogger._(root: this, category: category, source: source);
  }

  Future<void> _write(LogRecord record) async {
    if (!_isEnabled) return;
    try {
      await _logsRepo.insert(record);
      _logsController.notifyChanged();
    } catch (_) {
      //TODO popup
    }
  }
}

class ScopedLogger {
  ScopedLogger._({
    required AppLogger root,
    required LogCategory category,
    String? source,
  }) : _root = root,
       _category = category,
       _source = source;

  final AppLogger _root;
  final LogCategory _category;
  final String? _source;

  Future<void> _logInternal({
    required LogLevel level,
    required String message,
    String? chainId,
    String? details,
    AppError? error,
    Map<String, dynamic>? extra,
  }) async {
    final ts = error?.occurredAt ?? DateTime.now();

    String? combinedDetails;
    if (_source != null && details != null) {
      combinedDetails = '$_source | $details';
    } else if (_source != null) {
      combinedDetails = _source;
    } else {
      combinedDetails = details ?? error?.detail;
    }

    final record = LogRecord(
      timestamp: ts,
      level: level,
      category: _category,
      message: message,
      chainId: chainId,
      details: combinedDetails,
      errorType: error?.runtimeType.toString(),
      errorStack: error?.stackTrace?.toString(),
      extraJson: extra != null ? jsonEncode(extra) : null,
    );

    await _root._write(record);
  }

  Future<void> debug(
    String message, {
    String? chainId,
    String? details,
    Map<String, dynamic>? extra,
  }) => _logInternal(
    level: LogLevel.debug,
    message: message,
    chainId: chainId,
    details: details,
    extra: extra,
  );

  Future<void> info(
    String message, {
    String? chainId,
    String? details,
    Map<String, dynamic>? extra,
  }) => _logInternal(
    level: LogLevel.info,
    message: message,
    chainId: chainId,
    details: details,
    extra: extra,
  );

  Future<void> warning(
    String message, {
    String? chainId,
    String? details,
    Map<String, dynamic>? extra,
  }) => _logInternal(
    level: LogLevel.warning,
    message: message,
    chainId: chainId,
    details: details,
    extra: extra,
  );

  Future<void> error(
    String message, {
    String? chainId,
    String? details,
    AppError? error,
    Map<String, dynamic>? extra,
  }) => _logInternal(
    level: LogLevel.error,
    message: message,
    chainId: chainId,
    details: details,
    error: error,
    extra: extra,
  );

  Future<void> critical(
    String message, {
    String? chainId,
    String? details,
    AppError? error,
    Map<String, dynamic>? extra,
  }) => _logInternal(
    level: LogLevel.critical,
    message: message,
    chainId: chainId,
    details: details,
    error: error,
    extra: extra,
  );

  Future<void> errorFrom(
    AppError error, {
    String? chainId,
    Map<String, dynamic>? extra,
  }) => _logInternal(
    level: LogLevel.error,
    message: error.message,
    chainId: chainId,
    details: error.detail,
    error: error,
    extra: extra,
  );
}

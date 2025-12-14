import 'package:flutter/foundation.dart';
import 'log_level.dart';

@immutable
class LogRecord {
  final int? id;
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? chainId;
  final String? details;
  final String? errorType;
  final String? errorStack;
  final String? extraJson;

  const LogRecord({
    this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.chainId,
    this.details,
    this.errorType,
    this.errorStack,
    this.extraJson,
  });

  Map<String, dynamic> toMap() {
    return {
      LogField.id: id,
      LogField.timestamp: timestamp.toIso8601String(),
      LogField.level: level.name,
      LogField.category: category.name,
      LogField.message: message,
      LogField.chainId: chainId,
      LogField.details: details,
      LogField.errorType: errorType,
      LogField.errorStack: errorStack,
      LogField.extraJson: extraJson,
    };
  }

  factory LogRecord.fromMap(Map<String, dynamic> map) {
    return LogRecord(
      id: map[LogField.id] as int?,
      timestamp: DateTime.parse(map[LogField.timestamp] as String),
      level: LogLevelExt.fromString(map[LogField.level] as String),
      category: LogCategoryExt.from(map[LogField.category] as String),
      message: map[LogField.message] as String,
      chainId: map[LogField.chainId] as String?,
      details: map[LogField.details] as String?,
      errorType: map[LogField.errorType] as String?,
      errorStack: map[LogField.errorStack] as String?,
      extraJson: map[LogField.extraJson] as String?,
    );
  }
}

enum LogCategory {
  api,
  db,
  background,
  job,
  email,
  coupon,
  system,
  ui,
  network,
}

extension LogCategoryExt on LogCategory {
  String get name => toString().split('.').last;

  static LogCategory from(String value) {
    return LogCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => LogCategory.system,
    );
  }
}

class LogField {
  static const id = 'id';
  static const timestamp = 'timestamp';
  static const level = 'level';
  static const category = 'category';
  static const message = 'message';
  static const chainId = 'chain_id';
  static const details = 'details';
  static const errorType = 'error_type';
  static const errorStack = 'error_stack';
  static const extraJson = 'extra_json';
}

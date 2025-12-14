enum LogLevel { debug, info, warning, error, critical }

extension LogLevelExt on LogLevel {
  String get name => toString().split('.').last;

  static LogLevel fromString(String value) {
    return LogLevel.values.firstWhere(
      (l) => l.name == value,
      orElse: () => LogLevel.info,
    );
  }
}

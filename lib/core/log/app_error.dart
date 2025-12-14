import 'package:flutter/foundation.dart';

@immutable
abstract class AppError {
  final String message;
  final String? detail;
  final Object? cause;
  final StackTrace? stackTrace;
  final DateTime occurredAt;

  AppError({
    required this.message,
    this.detail,
    this.cause,
    this.stackTrace,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  @override
  String toString() =>
      '$runtimeType: $message${detail != null ? " ($detail)" : ""}';
}

class NetworkError extends AppError {
  final int? statusCode;

  NetworkError({
    required super.message,
    super.detail,
    super.cause,
    super.stackTrace,
    this.statusCode,
    super.occurredAt,
  });
}

class ApiError extends AppError {
  final int? statusCode;
  final String? errorCode;

  ApiError({
    required super.message,
    super.detail,
    super.cause,
    super.stackTrace,
    this.statusCode,
    this.errorCode,
    super.occurredAt,
  });
}

class DbError extends AppError {
  final String? operation;
  final String? table;

  DbError({
    required super.message,
    super.detail,
    super.cause,
    super.stackTrace,
    this.operation,
    this.table,
    super.occurredAt,
  });
}

class BackgroundTaskError extends AppError {
  final String? taskName;

  BackgroundTaskError({
    required super.message,
    this.taskName,
    super.detail,
    super.cause,
    super.stackTrace,
    super.occurredAt,
  });
}

class UnknownError extends AppError {
  UnknownError({
    required super.message,
    super.detail,
    super.cause,
    super.stackTrace,
    super.occurredAt,
  });
}

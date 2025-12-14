import 'log/app_error.dart';

class Result<T> {
  final T? data;
  final AppError? error;

  bool get isSuccess => error == null;

  bool get isFailure => error != null;

  const Result._({this.data, this.error});

  factory Result.success(T data) => Result._(data: data);

  factory Result.failure(AppError error) => Result._(error: error);

  R match<R>({
    required R Function(T data) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onFailure(error!);
  }
}

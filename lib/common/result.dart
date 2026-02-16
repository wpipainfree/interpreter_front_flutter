import 'failure.dart';

abstract class Result<T> {
  const Result();

  factory Result.success(T value) = Success<T>;
  factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess;

  bool get isFailure => !isSuccess;

  T? get valueOrNull;

  Failure? get failureOrNull;

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  });
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool get isSuccess => true;

  @override
  T get valueOrNull => value;

  @override
  Failure? get failureOrNull => null;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    return success(value);
  }
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;

  @override
  bool get isSuccess => false;

  @override
  T? get valueOrNull => null;

  @override
  Failure get failureOrNull => failure;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    return failure(this.failure);
  }
}

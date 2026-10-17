/// Result type returned by every service layer method.
/// Controllers handle [Success] and [Failure] outcomes cleanly.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final failure) => failure,
      };
}

/// Successful outcome carrying [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// Failed outcome carrying [failure].
final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}

/// Structured failure containing a message key from `app_strings.dart`
/// and machine-readable error codes.
class AppFailure {
  const AppFailure({
    required this.code,
    required this.userMessageKey,
    this.detail,
  });

  /// Error code identifier (e.g., 'network_error', 'unauthorized', 'not_found').
  final String code;

  /// String key resolved by the UI from [AppStrings].
  final String userMessageKey;

  /// Optional diagnostic detail (never displayed raw in production UI).
  final String? detail;

  @override
  String toString() => 'AppFailure(code: $code, messageKey: $userMessageKey, detail: $detail)';
}

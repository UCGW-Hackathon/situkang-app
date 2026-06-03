/// Core error handling for the SITUKANG app.
///
/// Defines a sealed [Failure] hierarchy used throughout the application
/// to represent typed errors in a functional programming style.
/// All repository methods return `Future<Result<T>>` (i.e., `Future<Either<Failure, T>>`)
/// so that error handling is explicit and composable.
library;

import 'package:equatable/equatable.dart';

/// Represents a server-side field validation error.
///
/// Used when the API returns field-level validation errors (HTTP 400/422),
/// mapping each field name to its corresponding error message.
class FieldError extends Equatable {
  /// Creates a [FieldError] with the given [field] name and [message].
  const FieldError({required this.field, required this.message});

  /// Creates a [FieldError] from a JSON map.
  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  /// The name of the field that failed validation (e.g., "email", "phone").
  final String field;

  /// The human-readable error message for this field.
  final String message;

  /// Converts this [FieldError] to a JSON map.
  Map<String, dynamic> toJson() => {'field': field, 'message': message};

  @override
  List<Object?> get props => [field, message];
}

/// Base sealed class for all failure types in the application.
///
/// Using a sealed class ensures exhaustive pattern matching when handling
/// errors, so no failure case is accidentally missed.
sealed class Failure extends Equatable {
  /// Creates a [Failure] with a human-readable [message] and optional [errorCode].
  const Failure(this.message, {this.errorCode});

  /// A human-readable error message describing what went wrong.
  final String message;

  /// An optional error code from the server for programmatic handling.
  final String? errorCode;

  @override
  List<Object?> get props => [message, errorCode];
}

/// Represents a server-side error (HTTP 4xx/5xx responses).
///
/// Maps to HTTP status codes: 404, 409, 422, 429, 500+.
/// May include field-level validation errors from the server.
class ServerFailure extends Failure {
  /// Creates a [ServerFailure] with the given [message], [statusCode],
  /// and optional [fieldErrors] and [errorCode].
  const ServerFailure(
    super.message, {
    required this.statusCode,
    this.fieldErrors,
    super.errorCode,
  });

  /// The HTTP status code returned by the server.
  final int statusCode;

  /// Optional list of field-level validation errors from the server.
  final List<FieldError>? fieldErrors;

  @override
  List<Object?> get props => [message, errorCode, statusCode, fieldErrors];
}

/// Represents a network connectivity failure.
///
/// Triggered when the device has no internet connection or the server
/// is unreachable. Default message is in Indonesian for the target audience.
class NetworkFailure extends Failure {
  /// Creates a [NetworkFailure] with an optional [message].
  const NetworkFailure([super.message = 'Tidak ada koneksi internet']);
}

/// Represents a local cache failure.
///
/// Triggered when cached data is unavailable, corrupted, or expired
/// and the app cannot fall back to the network.
class CacheFailure extends Failure {
  /// Creates a [CacheFailure] with an optional [message].
  const CacheFailure([super.message = 'Data cache tidak tersedia']);
}

/// Represents an authentication/authorization failure.
///
/// Triggered on HTTP 401 (unauthorized) or 403 (forbidden) responses.
/// Used to trigger token refresh flows or redirect to login.
class AuthFailure extends Failure {
  /// Creates an [AuthFailure] with the given [message] and optional [errorCode].
  const AuthFailure(super.message, {super.errorCode});
}

/// Represents a client-side validation failure.
///
/// Used when form input fails local validation before being sent to the server.
/// Contains a map of field names to their respective error messages.
class ValidationFailure extends Failure {
  /// Creates a [ValidationFailure] with the given [message] and [fieldErrors].
  const ValidationFailure(super.message, {required this.fieldErrors});

  /// Map of field names to their validation error messages.
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, errorCode, fieldErrors];
}

/// Represents a request timeout failure.
///
/// Triggered when a network request exceeds the configured timeout duration.
/// Default message is in Indonesian for the target audience.
class TimeoutFailure extends Failure {
  /// Creates a [TimeoutFailure] with an optional [message].
  const TimeoutFailure([super.message = 'Koneksi timeout, coba lagi']);
}

/// Represents a WebSocket connection or communication failure.
///
/// Triggered when the WebSocket connection drops, fails to establish,
/// or encounters an error during real-time communication.
class WebSocketFailure extends Failure {
  /// Creates a [WebSocketFailure] with the given [message].
  const WebSocketFailure(super.message);
}

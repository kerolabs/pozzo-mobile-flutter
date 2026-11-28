/// An error the member can read: a rule of the domain that was not met before calling the backend.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  /// The message to show on screen.
  String get userMessage => message;

  @override
  String toString() => userMessage;
}

/// An error answered by the Pozzo REST backend, or a request that could not reach it.
///
/// [status] is the HTTP status, or 0 when there is no connection. [code] is the machine-readable code
/// the backend sends (`INVALID_VERIFICATION_CODE`, `VALIDATION_ERROR`...) and [details] explains which
/// field failed when the request did not pass the validation.
class ApiException extends AppException {
  const ApiException({required this.status, required this.code, required String message, this.details})
      : super(message);

  final int status;
  final String code;
  final String? details;

  @override
  String get userMessage => code == 'VALIDATION_ERROR' && details != null ? details! : message;
}

/// The message to show for any failure caught in a view model.
String userMessageOf(Object error) =>
    error is AppException ? error.userMessage : 'Ocurrió un error. Inténtalo de nuevo.';

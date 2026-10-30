enum ApiErrorKind {
  network,
  timeout,
  unauthorised,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}

/// Typed error raised by [ApiService] so callers can react to the failure
/// kind (for example falling back to cached data when offline) instead of
/// matching on message text.
class ApiException implements Exception {
  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  const ApiException(this.kind, this.message, {this.statusCode});

  bool get isOffline =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  @override
  String toString() => message;
}

library;

/// Custom exceptions for API Sentinel SDK
///
/// These exceptions provide granular error handling for different failure scenarios

/// Base exception for all API Sentinel errors
class SentinelException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  SentinelException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'SentinelException: $message${code != null ? ' (code: $code)' : ''}';
  }
}

/// Thrown when SDK is not initialized before use
class SentinelNotInitializedException extends SentinelException {
  SentinelNotInitializedException()
    : super(
        message:
            'API Sentinel is not initialized. Call init() before using the SDK.',
        code: 'NOT_INITIALIZED',
      );
}

/// Thrown when configuration is invalid
class SentinelConfigurationException extends SentinelException {
  SentinelConfigurationException(String message)
    : super(message: message, code: 'INVALID_CONFIGURATION');
}

/// Thrown when API key is invalid or missing
class SentinelAuthenticationException extends SentinelException {
  SentinelAuthenticationException(String message)
    : super(message: message, code: 'AUTHENTICATION_FAILED');
}

/// Thrown when network request fails
class SentinelNetworkException extends SentinelException {
  final int? statusCode;
  final Map<String, dynamic>? responseData;

  SentinelNetworkException({
    required super.message,
    this.statusCode,
    this.responseData,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'NETWORK_ERROR');
}

/// Thrown when both primary and secondary gateways fail
class SentinelGatewayException extends SentinelException {
  final String primaryGateway;
  final String secondaryGateway;
  final String? primaryError;
  final String? secondaryError;

  SentinelGatewayException({
    required this.primaryGateway,
    required this.secondaryGateway,
    this.primaryError,
    this.secondaryError,
  }) : super(
         message: 'Both gateways failed: $primaryGateway and $secondaryGateway',
         code: 'GATEWAY_FAILURE',
       );

  @override
  String toString() {
    return 'SentinelGatewayException: Both gateways failed\n'
        '  Primary ($primaryGateway): $primaryError\n'
        '  Secondary ($secondaryGateway): $secondaryError';
  }
}

/// Thrown when request times out
class SentinelTimeoutException extends SentinelException {
  final Duration timeout;

  SentinelTimeoutException({required this.timeout, String? message})
    : super(
        message: message ?? 'Request timed out after ${timeout.inSeconds}s',
        code: 'TIMEOUT',
      );
}

/// Thrown when rate limit is exceeded
class SentinelRateLimitException extends SentinelException {
  final int? retryAfterSeconds;

  SentinelRateLimitException({this.retryAfterSeconds, String? message})
    : super(
        message: message ?? 'Rate limit exceeded',
        code: 'RATE_LIMIT_EXCEEDED',
      );

  @override
  String toString() {
    final retry = retryAfterSeconds != null
        ? ' (retry after ${retryAfterSeconds}s)'
        : '';
    return 'SentinelRateLimitException: $message$retry';
  }
}

/// Thrown when request validation fails
class SentinelValidationException extends SentinelException {
  final Map<String, List<String>>? errors;

  SentinelValidationException({required super.message, this.errors})
    : super(code: 'VALIDATION_ERROR');

  @override
  String toString() {
    if (errors == null || errors!.isEmpty) {
      return 'SentinelValidationException: $message';
    }

    final buffer = StringBuffer('SentinelValidationException: $message\n');
    errors!.forEach((field, messages) {
      buffer.writeln('  $field: ${messages.join(', ')}');
    });
    return buffer.toString();
  }
}

/// Thrown when storage operations fail
class SentinelStorageException extends SentinelException {
  SentinelStorageException(String message, {super.originalError})
    : super(message: message, code: 'STORAGE_ERROR');
}

/// Thrown when an operation is attempted while offline
class SentinelOfflineException extends SentinelException {
  SentinelOfflineException()
    : super(
        message: 'Operation requires network connectivity',
        code: 'OFFLINE',
      );
}

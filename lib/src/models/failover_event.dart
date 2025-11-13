/// Represents a failover event that occurred during payment processing
///
/// This event is tracked and sent to API Sentinel backend for analytics
class FailoverEvent {
  /// Unique identifier for this event
  final String eventId;

  /// Timestamp when the failover occurred
  final DateTime timestamp;

  /// Primary gateway that failed (e.g., 'stripe')
  final String primaryGateway;

  /// Type of error that triggered the failover
  final String errorType;

  /// Error message from the primary gateway
  final String? errorMessage;

  /// HTTP status code from the primary gateway
  final int? statusCode;

  /// Secondary gateway used for recovery (e.g., 'paypal')
  final String secondaryGateway;

  /// Whether the failover attempt was successful
  final bool success;

  /// Payment amount involved in this transaction
  final double? amount;

  /// Currency code (e.g., 'USD', 'EUR')
  final String? currency;

  /// Time taken to recover (in milliseconds)
  final int? recoveryTimeMs;

  /// Customer ID associated with this transaction
  final String? customerId;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  FailoverEvent({
    required this.eventId,
    required this.timestamp,
    required this.primaryGateway,
    required this.errorType,
    this.errorMessage,
    this.statusCode,
    required this.secondaryGateway,
    required this.success,
    this.amount,
    this.currency,
    this.recoveryTimeMs,
    this.customerId,
    this.metadata,
  });

  /// Create FailoverEvent from JSON
  factory FailoverEvent.fromJson(Map<String, dynamic> json) {
    return FailoverEvent(
      eventId: json['eventId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      primaryGateway: json['primaryGateway'] as String,
      errorType: json['errorType'] as String,
      errorMessage: json['errorMessage'] as String?,
      statusCode: json['statusCode'] as int?,
      secondaryGateway: json['secondaryGateway'] as String,
      success: json['success'] as bool,
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
      recoveryTimeMs: json['recoveryTimeMs'] as int?,
      customerId: json['customerId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert FailoverEvent to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'timestamp': timestamp.toIso8601String(),
      'primaryGateway': primaryGateway,
      'errorType': errorType,
      'errorMessage': errorMessage,
      'statusCode': statusCode,
      'secondaryGateway': secondaryGateway,
      'success': success,
      'amount': amount,
      'currency': currency,
      'recoveryTimeMs': recoveryTimeMs,
      'customerId': customerId,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'FailoverEvent(eventId: $eventId, primaryGateway: $primaryGateway, '
        'errorType: $errorType, success: $success, amount: $amount)';
  }
}

/// Error types that can trigger failover
class FailoverErrorType {
  static const String timeout = 'TIMEOUT';
  static const String serverError = 'SERVER_ERROR';
  static const String networkError = 'NETWORK_ERROR';
  static const String gatewayUnavailable = 'GATEWAY_UNAVAILABLE';
  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  static const String authenticationFailed = 'AUTHENTICATION_FAILED';
  static const String invalidRequest = 'INVALID_REQUEST';
  static const String unknown = 'UNKNOWN';

  /// Determine error type from HTTP status code
  static String fromStatusCode(int? statusCode) {
    if (statusCode == null) return networkError;

    if (statusCode >= 500) return serverError;
    if (statusCode == 429) return rateLimitExceeded;
    if (statusCode == 401 || statusCode == 403) return authenticationFailed;
    if (statusCode == 400) return invalidRequest;
    if (statusCode == 503 || statusCode == 504) return gatewayUnavailable;

    return unknown;
  }

  /// Check if error type should trigger failover
  static bool shouldTriggerFailover(String errorType) {
    return [
      timeout,
      serverError,
      networkError,
      gatewayUnavailable,
      rateLimitExceeded,
    ].contains(errorType);
  }
}

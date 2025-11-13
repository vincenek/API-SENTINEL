/// Response from API Sentinel after a payment operation
///
/// This response indicates whether the payment was successful,
/// whether failover was used, and includes relevant timing data.
class SentinelResponse<T> {
  /// Whether the operation was successful
  final bool success;

  /// Response data from the payment gateway
  final T? data;

  /// Whether failover was used to complete this transaction
  final bool failoverUsed;

  /// Gateway that ultimately processed the payment
  final String? gatewayUsed;

  /// Time taken to recover (in milliseconds) if failover was used
  final int? recoveryTimeMs;

  /// Error message if operation failed
  final String? errorMessage;

  /// Error type if operation failed
  final String? errorType;

  /// HTTP status code from the gateway
  final int? statusCode;

  /// Event ID for tracking this transaction
  final String? eventId;

  /// Timestamp when the operation completed
  final DateTime timestamp;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  SentinelResponse({
    required this.success,
    this.data,
    this.failoverUsed = false,
    this.gatewayUsed,
    this.recoveryTimeMs,
    this.errorMessage,
    this.errorType,
    this.statusCode,
    this.eventId,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a successful response
  factory SentinelResponse.successResponse({
    required T data,
    required String gatewayUsed,
    bool failoverUsed = false,
    int? recoveryTimeMs,
    String? eventId,
    Map<String, dynamic>? metadata,
  }) {
    return SentinelResponse<T>(
      success: true,
      data: data,
      failoverUsed: failoverUsed,
      gatewayUsed: gatewayUsed,
      recoveryTimeMs: recoveryTimeMs,
      eventId: eventId,
      metadata: metadata,
    );
  }

  /// Create a failure response
  factory SentinelResponse.failureResponse({
    required String errorMessage,
    required String errorType,
    int? statusCode,
    String? gatewayUsed,
    String? eventId,
    Map<String, dynamic>? metadata,
  }) {
    return SentinelResponse<T>(
      success: false,
      errorMessage: errorMessage,
      errorType: errorType,
      statusCode: statusCode,
      gatewayUsed: gatewayUsed,
      eventId: eventId,
      metadata: metadata,
    );
  }

  /// Create SentinelResponse from JSON
  factory SentinelResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return SentinelResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      failoverUsed: json['failoverUsed'] as bool? ?? false,
      gatewayUsed: json['gatewayUsed'] as String?,
      recoveryTimeMs: json['recoveryTimeMs'] as int?,
      errorMessage: json['errorMessage'] as String?,
      errorType: json['errorType'] as String?,
      statusCode: json['statusCode'] as int?,
      eventId: json['eventId'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert SentinelResponse to JSON
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'success': success,
      'data': data != null ? toJsonT(data as T) : null,
      'failoverUsed': failoverUsed,
      'gatewayUsed': gatewayUsed,
      'recoveryTimeMs': recoveryTimeMs,
      'errorMessage': errorMessage,
      'errorType': errorType,
      'statusCode': statusCode,
      'eventId': eventId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'SentinelResponse(success: $success, failoverUsed: $failoverUsed, '
        'gatewayUsed: $gatewayUsed, recoveryTimeMs: $recoveryTimeMs)';
  }
}

/// Payment request data structure
class PaymentRequest {
  /// Payment amount
  final double amount;

  /// Currency code (e.g., 'USD', 'EUR')
  final String currency;

  /// Payment method token or identifier
  final String paymentMethod;

  /// Customer email
  final String? customerEmail;

  /// Customer ID
  final String? customerId;

  /// Description of the payment
  final String? description;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  PaymentRequest({
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.customerEmail,
    this.customerId,
    this.description,
    this.metadata,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      paymentMethod: json['paymentMethod'] as String,
      customerEmail: json['customerEmail'] as String?,
      customerId: json['customerId'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'customerEmail': customerEmail,
      'customerId': customerId,
      'description': description,
      'metadata': metadata,
    };
  }
}

/// Payment response data structure
class PaymentResponse {
  /// Transaction ID from the gateway
  final String transactionId;

  /// Payment status (e.g., 'succeeded', 'pending', 'failed')
  final String status;

  /// Amount charged
  final double amount;

  /// Currency code
  final String currency;

  /// Gateway that processed the payment
  final String gateway;

  /// Additional data from the gateway
  final Map<String, dynamic>? gatewayData;

  PaymentResponse({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.gateway,
    this.gatewayData,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      transactionId: json['transactionId'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      gateway: json['gateway'] as String,
      gatewayData: json['gatewayData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status,
      'amount': amount,
      'currency': currency,
      'gateway': gateway,
      'gatewayData': gatewayData,
    };
  }
}

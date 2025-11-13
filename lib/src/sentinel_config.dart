/// Configuration class for API Sentinel SDK
///
/// This class holds all the configuration needed for the SDK to function,
/// including API credentials, gateway settings, and behavioral options.
class SentinelConfig {
  /// Base URL of the API Sentinel backend service
  final String baseUrl;

  /// API key for authenticating with API Sentinel backend
  /// Get this from your API Sentinel dashboard after registration
  final String apiKey;

  /// Primary payment gateway identifier (e.g., 'stripe', 'paypal')
  final String primaryGateway;

  /// Secondary payment gateway for failover (e.g., 'paypal', 'square')
  final String secondaryGateway;

  /// Whether to send analytics events to API Sentinel backend
  final bool enableAnalytics;

  /// Maximum number of retry attempts before giving up
  final int maxRetryAttempts;

  /// Timeout duration for HTTP requests in seconds
  final int requestTimeoutSeconds;

  /// Customer/Company ID for tracking in analytics
  final String? customerId;

  /// Enable debug logging
  final bool enableDebugLogging;

  const SentinelConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.primaryGateway,
    required this.secondaryGateway,
    this.enableAnalytics = true,
    this.maxRetryAttempts = 3,
    this.requestTimeoutSeconds = 30,
    this.customerId,
    this.enableDebugLogging = false,
  });

  /// Create a copy of this config with updated values
  SentinelConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? primaryGateway,
    String? secondaryGateway,
    bool? enableAnalytics,
    int? maxRetryAttempts,
    int? requestTimeoutSeconds,
    String? customerId,
    bool? enableDebugLogging,
  }) {
    return SentinelConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      primaryGateway: primaryGateway ?? this.primaryGateway,
      secondaryGateway: secondaryGateway ?? this.secondaryGateway,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      requestTimeoutSeconds:
          requestTimeoutSeconds ?? this.requestTimeoutSeconds,
      customerId: customerId ?? this.customerId,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
    );
  }

  /// Convert config to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'primaryGateway': primaryGateway,
      'secondaryGateway': secondaryGateway,
      'enableAnalytics': enableAnalytics,
      'maxRetryAttempts': maxRetryAttempts,
      'requestTimeoutSeconds': requestTimeoutSeconds,
      'customerId': customerId,
      'enableDebugLogging': enableDebugLogging,
    };
  }

  /// Create config from JSON
  factory SentinelConfig.fromJson(Map<String, dynamic> json) {
    return SentinelConfig(
      baseUrl: json['baseUrl'] as String,
      apiKey: json['apiKey'] as String,
      primaryGateway: json['primaryGateway'] as String,
      secondaryGateway: json['secondaryGateway'] as String,
      enableAnalytics: json['enableAnalytics'] as bool? ?? true,
      maxRetryAttempts: json['maxRetryAttempts'] as int? ?? 3,
      requestTimeoutSeconds: json['requestTimeoutSeconds'] as int? ?? 30,
      customerId: json['customerId'] as String?,
      enableDebugLogging: json['enableDebugLogging'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'SentinelConfig(baseUrl: $baseUrl, primaryGateway: $primaryGateway, '
        'secondaryGateway: $secondaryGateway, enableAnalytics: $enableAnalytics)';
  }
}

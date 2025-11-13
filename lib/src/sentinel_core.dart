import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'sentinel_config.dart';
import 'models/failover_event.dart';
import 'models/sentinel_response.dart';
import 'sentry_service.dart';

/// Main API Sentinel SDK class
///
/// This class provides the core functionality for automatic payment failover recovery.
/// Initialize it once in your app and use it for all payment operations that need
/// failover protection.
///
/// Example usage:
/// ```dart
/// final sentinel = APISentinel(
///   baseUrl: 'https://api.apisentinel.com',
///   apiKey: 'your-api-key-here',
/// );
///
/// await sentinel.init();
///
/// final response = await sentinel.postWithFailover(
///   endpoint: '/process-payment',
///   data: {'amount': 100, 'currency': 'USD'},
/// );
/// ```
class APISentinel {
  final SentinelConfig _config;
  late final Dio _httpClient;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;
  final Uuid _uuid;

  bool _isInitialized = false;

  // Storage keys
  static const String _configStorageKey = 'api_sentinel_config';
  static const String _apiKeyStorageKey = 'api_sentinel_api_key';

  APISentinel({
    required String baseUrl,
    required String apiKey,
    required String primaryGateway,
    required String secondaryGateway,
    bool enableAnalytics = true,
    int maxRetryAttempts = 3,
    int requestTimeoutSeconds = 30,
    String? customerId,
    bool enableDebugLogging = false,
  }) : _config = SentinelConfig(
         baseUrl: baseUrl,
         apiKey: apiKey,
         primaryGateway: primaryGateway,
         secondaryGateway: secondaryGateway,
         enableAnalytics: enableAnalytics,
         maxRetryAttempts: maxRetryAttempts,
         requestTimeoutSeconds: requestTimeoutSeconds,
         customerId: customerId,
         enableDebugLogging: enableDebugLogging,
       ),
       _secureStorage = const FlutterSecureStorage(),
       _logger = Logger(
         printer: PrettyPrinter(
           methodCount: 0,
           errorMethodCount: 5,
           lineLength: 50,
           colors: true,
           printEmojis: true,
         ),
         level: enableDebugLogging ? Level.debug : Level.info,
       ),
       _uuid = const Uuid();

  /// Initialize the SDK
  ///
  /// This must be called before using any other SDK methods.
  /// It sets up the HTTP client and saves configuration securely.
  Future<void> init() async {
    if (_isInitialized) {
      _logger.w('API Sentinel already initialized');
      return;
    }

    try {
      // Initialize HTTP client with configuration
      _httpClient = Dio(
        BaseOptions(
          baseUrl: _config.baseUrl,
          connectTimeout: Duration(seconds: _config.requestTimeoutSeconds),
          receiveTimeout: Duration(seconds: _config.requestTimeoutSeconds),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_config.apiKey}',
            'X-API-Sentinel-Version': '1.0.0',
          },
        ),
      );

      // Add interceptors for logging
      if (_config.enableDebugLogging) {
        _httpClient.interceptors.add(
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (obj) => _logger.d(obj),
          ),
        );
      }

      // Save configuration securely
      await _saveConfiguration();

      _isInitialized = true;
      _logger.i('API Sentinel initialized successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize API Sentinel',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Execute a POST request with automatic failover support
  ///
  /// This method attempts to send the request to the primary gateway first.
  /// If it fails with a recoverable error, it automatically retries with the
  /// secondary gateway.
  ///
  /// [endpoint] - The API endpoint to call (relative to base URL)
  /// [data] - The request payload
  /// [primaryGatewayUrl] - Override primary gateway URL
  /// [secondaryGatewayUrl] - Override secondary gateway URL
  /// [headers] - Additional headers to include
  Future<SentinelResponse<Map<String, dynamic>>> postWithFailover({
    required String endpoint,
    required Map<String, dynamic> data,
    String? primaryGatewayUrl,
    String? secondaryGatewayUrl,
    Map<String, String>? headers,
  }) async {
    _ensureInitialized();

    final eventId = _uuid.v4();
    final startTime = DateTime.now();

    _logger.i('Starting payment request with failover protection');
    _logger.d('Event ID: $eventId, Endpoint: $endpoint');

    try {
      // Attempt primary gateway
      final primaryResult = await _attemptGatewayRequest(
        endpoint: endpoint,
        data: data,
        gateway: _config.primaryGateway,
        gatewayUrl: primaryGatewayUrl,
        headers: headers,
      );

      if (primaryResult.success) {
        _logger.i('Payment successful on primary gateway');

        // Track success event
        if (_config.enableAnalytics) {
          await _trackSuccessEvent(
            eventId: eventId,
            gateway: _config.primaryGateway,
            amount: data['amount'] as double?,
            currency: data['currency'] as String?,
          );
        }

        return SentinelResponse.successResponse(
          data: primaryResult.data!,
          gatewayUsed: _config.primaryGateway,
          failoverUsed: false,
          eventId: eventId,
        );
      }

      // Primary failed - check if we should failover
      final errorType = primaryResult.errorType ?? FailoverErrorType.unknown;

      if (!FailoverErrorType.shouldTriggerFailover(errorType)) {
        _logger.w(
          'Primary gateway failed but error does not trigger failover: $errorType',
        );
        return primaryResult;
      }

      _logger.w(
        'Primary gateway failed, attempting failover to ${_config.secondaryGateway}',
      );

      // Attempt secondary gateway (failover)
      final secondaryResult = await _attemptGatewayRequest(
        endpoint: endpoint,
        data: data,
        gateway: _config.secondaryGateway,
        gatewayUrl: secondaryGatewayUrl,
        headers: headers,
      );

      final recoveryTime = DateTime.now().difference(startTime).inMilliseconds;

      if (secondaryResult.success) {
        _logger.i('Payment recovered successfully via failover');

        // Track failover success event
        if (_config.enableAnalytics) {
          await _trackFailoverEvent(
            eventId: eventId,
            primaryGateway: _config.primaryGateway,
            secondaryGateway: _config.secondaryGateway,
            errorType: errorType,
            errorMessage: primaryResult.errorMessage,
            statusCode: primaryResult.statusCode,
            success: true,
            amount: data['amount'] as double?,
            currency: data['currency'] as String?,
            recoveryTimeMs: recoveryTime,
          );
        }

        return SentinelResponse.successResponse(
          data: secondaryResult.data!,
          gatewayUsed: _config.secondaryGateway,
          failoverUsed: true,
          recoveryTimeMs: recoveryTime,
          eventId: eventId,
        );
      } else {
        _logger.e('Failover also failed - both gateways unavailable');

        // Track failover failure event
        if (_config.enableAnalytics) {
          await _trackFailoverEvent(
            eventId: eventId,
            primaryGateway: _config.primaryGateway,
            secondaryGateway: _config.secondaryGateway,
            errorType: errorType,
            errorMessage: primaryResult.errorMessage,
            statusCode: primaryResult.statusCode,
            success: false,
            amount: data['amount'] as double?,
            currency: data['currency'] as String?,
            recoveryTimeMs: recoveryTime,
          );
        }

        return SentinelResponse.failureResponse(
          errorMessage: 'Both primary and secondary gateways failed',
          errorType: FailoverErrorType.gatewayUnavailable,
          eventId: eventId,
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error during failover operation',
        error: e,
        stackTrace: stackTrace,
      );

      return SentinelResponse.failureResponse(
        errorMessage: 'Unexpected error: ${e.toString()}',
        errorType: FailoverErrorType.unknown,
        eventId: eventId,
      );
    }
  }

  /// Attempt to send request to a specific gateway
  Future<SentinelResponse<Map<String, dynamic>>> _attemptGatewayRequest({
    required String endpoint,
    required Map<String, dynamic> data,
    required String gateway,
    String? gatewayUrl,
    Map<String, String>? headers,
  }) async {
    final url = gatewayUrl ?? endpoint;

    try {
      _logger.d('Attempting request to $gateway: $url');

      final response = await _httpClient.post(
        url,
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return SentinelResponse.successResponse(
          data: response.data as Map<String, dynamic>,
          gatewayUsed: gateway,
        );
      } else {
        return SentinelResponse.failureResponse(
          errorMessage: 'Gateway returned error status: ${response.statusCode}',
          errorType: FailoverErrorType.fromStatusCode(response.statusCode),
          statusCode: response.statusCode,
          gatewayUsed: gateway,
        );
      }
    } on DioException catch (e) {
      _logger.w('Gateway request failed: ${e.message}');

      // Report to Sentry
      await SentryService.captureException(
        e,
        stackTrace: e.stackTrace,
        extras: {
          'gateway': gateway,
          'endpoint': endpoint,
          'statusCode': e.response?.statusCode,
        },
        tags: {'error_type': 'gateway_request_failed', 'gateway': gateway},
      );

      return SentinelResponse.failureResponse(
        errorMessage: e.message ?? 'Request failed',
        errorType: _getErrorTypeFromDioException(e),
        statusCode: e.response?.statusCode,
        gatewayUsed: gateway,
      );
    } catch (e, stackTrace) {
      _logger.w('Unexpected error in gateway request: $e');

      // Report to Sentry
      await SentryService.captureException(
        e,
        stackTrace: stackTrace,
        extras: {'gateway': gateway, 'endpoint': endpoint},
        tags: {'error_type': 'unexpected_error', 'gateway': gateway},
      );

      return SentinelResponse.failureResponse(
        errorMessage: e.toString(),
        errorType: FailoverErrorType.unknown,
        gatewayUsed: gateway,
      );
    }
  }

  /// Track a failover event to API Sentinel backend
  Future<void> _trackFailoverEvent({
    required String eventId,
    required String primaryGateway,
    required String secondaryGateway,
    required String errorType,
    String? errorMessage,
    int? statusCode,
    required bool success,
    double? amount,
    String? currency,
    int? recoveryTimeMs,
  }) async {
    try {
      final event = FailoverEvent(
        eventId: eventId,
        timestamp: DateTime.now(),
        primaryGateway: primaryGateway,
        errorType: errorType,
        errorMessage: errorMessage,
        statusCode: statusCode,
        secondaryGateway: secondaryGateway,
        success: success,
        amount: amount,
        currency: currency,
        recoveryTimeMs: recoveryTimeMs,
        customerId: _config.customerId,
      );

      await _httpClient.post(
        '/api/v1/analytics/failover-event',
        data: event.toJson(),
      );

      _logger.d('Failover event tracked successfully');
    } catch (e) {
      _logger.w('Failed to track failover event: $e (non-critical)');
      // Don't throw - analytics failures shouldn't break the main flow
    }
  }

  /// Track a successful payment event
  Future<void> _trackSuccessEvent({
    required String eventId,
    required String gateway,
    double? amount,
    String? currency,
  }) async {
    try {
      await _httpClient.post(
        '/api/v1/analytics/payment-success',
        data: {
          'eventId': eventId,
          'timestamp': DateTime.now().toIso8601String(),
          'gateway': gateway,
          'amount': amount,
          'currency': currency,
          'customerId': _config.customerId,
        },
      );

      _logger.d('Success event tracked');
    } catch (e) {
      _logger.w('Failed to track success event: $e (non-critical)');
    }
  }

  /// Track a custom payment event for analytics
  ///
  /// Use this to send custom events to your API Sentinel dashboard
  Future<void> trackPaymentEvent({
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    _ensureInitialized();

    if (!_config.enableAnalytics) {
      _logger.d('Analytics disabled, skipping event tracking');
      return;
    }

    try {
      await _httpClient.post(
        '/api/v1/analytics/custom-event',
        data: {
          'eventType': eventType,
          'timestamp': DateTime.now().toIso8601String(),
          'customerId': _config.customerId,
          'eventData': eventData,
        },
      );

      _logger.d('Custom event tracked: $eventType');
    } catch (e) {
      _logger.w('Failed to track custom event: $e');
    }
  }

  /// Save configuration securely
  Future<void> _saveConfiguration() async {
    try {
      await _secureStorage.write(
        key: _configStorageKey,
        value: jsonEncode(_config.toJson()),
      );
      await _secureStorage.write(key: _apiKeyStorageKey, value: _config.apiKey);
    } catch (e) {
      _logger.w('Failed to save configuration securely: $e');
    }
  }

  /// Get error type from Dio exception
  String _getErrorTypeFromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return FailoverErrorType.timeout;

      case DioExceptionType.connectionError:
        return FailoverErrorType.networkError;

      case DioExceptionType.badResponse:
        return FailoverErrorType.fromStatusCode(e.response?.statusCode);

      default:
        return FailoverErrorType.unknown;
    }
  }

  /// Ensure SDK is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'API Sentinel is not initialized. Call init() before using the SDK.',
      );
    }
  }

  /// Get current configuration (without sensitive data)
  SentinelConfig get config => _config;

  /// Check if SDK is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
    _isInitialized = false;
    _logger.i('API Sentinel disposed');
  }
}

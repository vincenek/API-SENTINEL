import 'package:flutter_test/flutter_test.dart';
import 'package:apisentinei/api_sentinel.dart';

void main() {
  group('SentinelConfig', () {
    test('creates config with required parameters', () {
      final config = SentinelConfig(
        baseUrl: 'https://api.apisentinel.com',
        apiKey: 'test-key',
        primaryGateway: 'stripe',
        secondaryGateway: 'paypal',
      );

      expect(config.baseUrl, 'https://api.apisentinel.com');
      expect(config.apiKey, 'test-key');
      expect(config.primaryGateway, 'stripe');
      expect(config.secondaryGateway, 'paypal');
      expect(config.enableAnalytics, true);
      expect(config.maxRetryAttempts, 3);
    });

    test('toJson and fromJson work correctly', () {
      final config = SentinelConfig(
        baseUrl: 'https://api.test.com',
        apiKey: 'key123',
        primaryGateway: 'stripe',
        secondaryGateway: 'paypal',
        customerId: 'customer-1',
      );

      final json = config.toJson();
      final restored = SentinelConfig.fromJson(json);

      expect(restored.baseUrl, config.baseUrl);
      expect(restored.apiKey, config.apiKey);
      expect(restored.primaryGateway, config.primaryGateway);
      expect(restored.customerId, config.customerId);
    });

    test('copyWith creates new config with updated values', () {
      final config = SentinelConfig(
        baseUrl: 'https://api.test.com',
        apiKey: 'key123',
        primaryGateway: 'stripe',
        secondaryGateway: 'paypal',
      );

      final updated = config.copyWith(
        maxRetryAttempts: 5,
        enableAnalytics: false,
      );

      expect(updated.maxRetryAttempts, 5);
      expect(updated.enableAnalytics, false);
      expect(updated.baseUrl, config.baseUrl);
      expect(updated.apiKey, config.apiKey);
    });
  });

  group('FailoverEvent', () {
    test('creates event with required fields', () {
      final event = FailoverEvent(
        eventId: 'evt-123',
        timestamp: DateTime(2025, 11, 12),
        primaryGateway: 'stripe',
        errorType: FailoverErrorType.timeout,
        secondaryGateway: 'paypal',
        success: true,
      );

      expect(event.eventId, 'evt-123');
      expect(event.primaryGateway, 'stripe');
      expect(event.errorType, FailoverErrorType.timeout);
      expect(event.success, true);
    });

    test('toJson and fromJson preserve all fields', () {
      final event = FailoverEvent(
        eventId: 'evt-456',
        timestamp: DateTime(2025, 11, 12),
        primaryGateway: 'stripe',
        errorType: FailoverErrorType.serverError,
        secondaryGateway: 'paypal',
        success: true,
        amount: 100.50,
        currency: 'USD',
        recoveryTimeMs: 1500,
      );

      final json = event.toJson();
      final restored = FailoverEvent.fromJson(json);

      expect(restored.eventId, event.eventId);
      expect(restored.amount, event.amount);
      expect(restored.currency, event.currency);
      expect(restored.recoveryTimeMs, event.recoveryTimeMs);
    });
  });

  group('FailoverErrorType', () {
    test('fromStatusCode correctly classifies errors', () {
      expect(
        FailoverErrorType.fromStatusCode(500),
        FailoverErrorType.serverError,
      );
      expect(
        FailoverErrorType.fromStatusCode(502),
        FailoverErrorType.serverError,
      );
      expect(
        FailoverErrorType.fromStatusCode(429),
        FailoverErrorType.rateLimitExceeded,
      );
      expect(
        FailoverErrorType.fromStatusCode(401),
        FailoverErrorType.authenticationFailed,
      );
      expect(
        FailoverErrorType.fromStatusCode(503),
        FailoverErrorType.serverError,
      ); // 503 is >= 500, so it returns serverError first
      expect(
        FailoverErrorType.fromStatusCode(null),
        FailoverErrorType.networkError,
      );
    });

    test('shouldTriggerFailover identifies recoverable errors', () {
      expect(
        FailoverErrorType.shouldTriggerFailover(FailoverErrorType.timeout),
        true,
      );
      expect(
        FailoverErrorType.shouldTriggerFailover(FailoverErrorType.serverError),
        true,
      );
      expect(
        FailoverErrorType.shouldTriggerFailover(FailoverErrorType.networkError),
        true,
      );
      expect(
        FailoverErrorType.shouldTriggerFailover(
          FailoverErrorType.gatewayUnavailable,
        ),
        true,
      );
      expect(
        FailoverErrorType.shouldTriggerFailover(
          FailoverErrorType.invalidRequest,
        ),
        false,
      );
    });
  });

  group('SentinelResponse', () {
    test('creates success response', () {
      final response = SentinelResponse.successResponse(
        data: {'transactionId': 'txn-123'},
        gatewayUsed: 'stripe',
        failoverUsed: false,
      );

      expect(response.success, true);
      expect(response.data, {'transactionId': 'txn-123'});
      expect(response.gatewayUsed, 'stripe');
      expect(response.failoverUsed, false);
    });

    test('creates failure response', () {
      final response = SentinelResponse<Map<String, dynamic>>.failureResponse(
        errorMessage: 'Gateway timeout',
        errorType: FailoverErrorType.timeout,
        statusCode: 504,
      );

      expect(response.success, false);
      expect(response.errorMessage, 'Gateway timeout');
      expect(response.errorType, FailoverErrorType.timeout);
      expect(response.statusCode, 504);
    });

    test('includes failover recovery metrics', () {
      final response = SentinelResponse.successResponse(
        data: {'status': 'paid'},
        gatewayUsed: 'paypal',
        failoverUsed: true,
        recoveryTimeMs: 2500,
      );

      expect(response.failoverUsed, true);
      expect(response.recoveryTimeMs, 2500);
      expect(response.gatewayUsed, 'paypal');
    });
  });

  group('RequestValidator', () {
    test('validates correct payment request', () {
      final data = {
        'amount': 100.0,
        'currency': 'USD',
        'paymentMethod': 'pm_card_visa',
      };

      final errors = RequestValidator.validatePaymentRequest(data);
      expect(errors, isEmpty);
    });

    test('detects missing required fields', () {
      final data = {'currency': 'USD'};

      final errors = RequestValidator.validatePaymentRequest(data);
      expect(errors.containsKey('amount'), true);
      expect(errors.containsKey('paymentMethod'), true);
    });

    test('validates amount constraints', () {
      final data1 = {
        'amount': -10.0,
        'currency': 'USD',
        'paymentMethod': 'test',
      };

      final errors1 = RequestValidator.validatePaymentRequest(data1);
      expect(errors1['amount'], contains('Amount must be greater than 0'));

      final data2 = {
        'amount': 1000000000.0,
        'currency': 'USD',
        'paymentMethod': 'test',
      };

      final errors2 = RequestValidator.validatePaymentRequest(data2);
      expect(
        errors2['amount'],
        contains('Amount exceeds maximum allowed value'),
      );
    });

    test('validates currency format', () {
      final data = {
        'amount': 100.0,
        'currency': 'INVALID',
        'paymentMethod': 'test',
      };

      final errors = RequestValidator.validatePaymentRequest(data);
      expect(errors.containsKey('currency'), true);
    });

    test('validates email format', () {
      final data = {
        'amount': 100.0,
        'currency': 'USD',
        'paymentMethod': 'test',
        'customerEmail': 'invalid-email',
      };

      final errors = RequestValidator.validatePaymentRequest(data);
      expect(errors['customerEmail'], contains('Invalid email format'));
    });

    test('sanitizes input data', () {
      final data = {'name': '  John Doe  ', 'email': '  test@example.com  '};

      final sanitized = RequestValidator.sanitizeInput(data);
      expect(sanitized['name'], 'John Doe');
      expect(sanitized['email'], 'test@example.com');
    });
  });

  group('RateLimiter', () {
    test('allows requests within limit', () {
      final limiter = RateLimiter(
        maxRequests: 5,
        window: const Duration(seconds: 10),
      );

      expect(limiter.canMakeRequest(), true);
      limiter.recordRequest();
      expect(limiter.currentRequestCount, 1);
      expect(limiter.remainingRequests, 4);
    });

    test('blocks requests exceeding limit', () async {
      final limiter = RateLimiter(
        maxRequests: 2,
        window: const Duration(seconds: 1),
      );

      limiter.recordRequest();
      limiter.recordRequest();

      expect(
        () => limiter.execute(() async => 'test'),
        throwsA(isA<SentinelRateLimitException>()),
      );
    });

    test('resets after time window', () async {
      final limiter = RateLimiter(
        maxRequests: 2,
        window: const Duration(milliseconds: 100),
      );

      limiter.recordRequest();
      limiter.recordRequest();

      await Future.delayed(const Duration(milliseconds: 150));

      expect(limiter.canMakeRequest(), true);
      expect(limiter.currentRequestCount, 0);
    });
  });

  group('RetryPolicy', () {
    test('retries on failure up to max attempts', () async {
      int attempts = 0;
      final policy = RetryPolicy(maxAttempts: 3, initialDelay: Duration.zero);

      try {
        await policy.execute(() async {
          attempts++;
          throw Exception('Test error');
        });
      } catch (e) {
        expect(attempts, 3);
      }
    });

    test('succeeds on first attempt if no error', () async {
      int attempts = 0;
      final policy = RetryPolicy(maxAttempts: 3);

      final result = await policy.execute(() async {
        attempts++;
        return 'success';
      });

      expect(result, 'success');
      expect(attempts, 1);
    });

    test('respects retryIf condition', () async {
      int attempts = 0;
      final policy = RetryPolicy(
        maxAttempts: 5,
        initialDelay: Duration.zero,
        retryIf: (e) => e.toString().contains('retry'),
      );

      try {
        await policy.execute(() async {
          attempts++;
          throw Exception('fail immediately');
        });
      } catch (e) {
        expect(attempts, 1); // Should not retry because retryIf returns false
      }
    });
  });

  group('CircuitBreaker', () {
    test('allows requests in closed state', () async {
      final breaker = CircuitBreaker(name: 'test', failureThreshold: 3);

      final result = await breaker.execute(() async => 'success');
      expect(result, 'success');
      expect(breaker.state, CircuitState.closed);
    });

    test('opens after threshold failures', () async {
      final breaker = CircuitBreaker(
        name: 'test',
        failureThreshold: 2,
        timeout: const Duration(milliseconds: 100),
      );

      for (int i = 0; i < 2; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(breaker.state, CircuitState.open);
      expect(breaker.failureCount, 2);

      // Next request should be rejected
      expect(
        () => breaker.execute(() async => 'test'),
        throwsA(isA<CircuitBreakerOpenException>()),
      );
    });
  });

  group('EnvironmentConfig', () {
    test('creates development config', () {
      final config = EnvironmentConfig.development();

      expect(config.environment, Environment.development);
      expect(config.enableDebugLogging, true);
      expect(config.enableAnalytics, false);
    });

    test('creates production config', () {
      final config = EnvironmentConfig.production(apiKey: 'prod-key');

      expect(config.environment, Environment.production);
      expect(config.enableDebugLogging, false);
      expect(config.enableAnalytics, true);
      expect(config.apiKey, 'prod-key');
    });

    test('creates custom config', () {
      final config = EnvironmentConfig.custom(
        environment: Environment.staging,
        baseUrl: 'https://custom.api.com',
        apiKey: 'custom-key',
        enableDebugLogging: true,
        maxRetryAttempts: 5,
      );

      expect(config.baseUrl, 'https://custom.api.com');
      expect(config.maxRetryAttempts, 5);
    });
  });
}

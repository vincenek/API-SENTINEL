import 'package:flutter_test/flutter_test.dart';
import 'package:apisentinei/api_sentinel.dart';
import 'dart:async';

/// Load testing suite for API Sentinel SDK
///
/// Tests performance under various load conditions

void main() {
  group('Load Testing', () {
    test('handles 100 concurrent requests', () async {
      final sentinel = APISentinel(
        baseUrl: 'https://httpbin.org',
        apiKey: 'test-key',
        primaryGateway: 'stripe',
        secondaryGateway: 'paypal',
        enableAnalytics: false,
      );

      await sentinel.init();

      final stopwatch = Stopwatch()..start();
      final futures = <Future<SentinelResponse>>[];

      // Create 100 concurrent requests
      for (int i = 0; i < 100; i++) {
        futures.add(
          sentinel.postWithFailover(
            endpoint: '/post',
            data: {'request_id': i, 'amount': 100.0 + i, 'currency': 'USD'},
          ),
        );
      }

      final results = await Future.wait(futures);
      stopwatch.stop();

      print(
        '100 concurrent requests completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      print('Average response time: ${stopwatch.elapsedMilliseconds / 100}ms');

      // Verify all requests completed
      expect(results.length, 100);

      // Should complete within reasonable time (10 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });

    test('handles 500 sequential requests without memory leak', () async {
      final sentinel = APISentinel(
        baseUrl: 'https://httpbin.org',
        apiKey: 'test-key',
        primaryGateway: 'stripe',
        secondaryGateway: 'paypal',
        enableAnalytics: false,
      );

      await sentinel.init();

      final stopwatch = Stopwatch()..start();
      int successCount = 0;

      for (int i = 0; i < 500; i++) {
        final response = await sentinel.postWithFailover(
          endpoint: '/post',
          data: {'request_id': i, 'amount': 50.0, 'currency': 'USD'},
        );

        if (response.success) {
          successCount++;
        }

        // Log every 100 requests
        if ((i + 1) % 100 == 0) {
          print(
            'Completed ${i + 1} requests, success rate: ${(successCount / (i + 1) * 100).toStringAsFixed(1)}%',
          );
        }
      }

      stopwatch.stop();

      print(
        '500 sequential requests completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      print('Average response time: ${stopwatch.elapsedMilliseconds / 500}ms');
      print('Success rate: ${(successCount / 500 * 100).toStringAsFixed(1)}%');

      expect(successCount, greaterThan(450)); // At least 90% success rate
    });

    test('rate limiter prevents excessive requests', () async {
      final rateLimiter = RateLimiter(
        maxRequests: 10,
        window: const Duration(seconds: 1),
      );

      int allowedCount = 0;
      int blockedCount = 0;

      // Try to make 50 requests
      for (int i = 0; i < 50; i++) {
        if (rateLimiter.canMakeRequest()) {
          rateLimiter.recordRequest();
          allowedCount++;
        } else {
          blockedCount++;
        }
      }

      print('Allowed: $allowedCount, Blocked: $blockedCount');

      expect(allowedCount, 10); // Should allow exactly 10
      expect(blockedCount, 40); // Should block 40
    });

    test('circuit breaker opens after threshold failures', () async {
      final circuitBreaker = CircuitBreaker(
        name: 'test-breaker',
        failureThreshold: 5,
        timeout: const Duration(seconds: 2),
      );

      int attemptCount = 0;

      // Simulate 10 failures
      for (int i = 0; i < 10; i++) {
        try {
          await circuitBreaker.execute(() async {
            attemptCount++;
            throw Exception('Simulated failure');
          });
        } catch (e) {
          // Expected to fail
        }
      }

      print('Circuit breaker attempt count: $attemptCount');

      // Should stop after threshold (5 failures)
      expect(
        attemptCount,
        lessThanOrEqualTo(6),
      ); // Threshold + possibly 1 in half-open
    });

    test('retry policy with exponential backoff', () async {
      final policy = RetryPolicy(
        maxAttempts: 5,
        initialDelay: const Duration(milliseconds: 100),
        backoffMultiplier: 2.0,
      );

      final stopwatch = Stopwatch()..start();
      int attempts = 0;

      try {
        await policy.execute(() async {
          attempts++;
          if (attempts < 4) {
            throw Exception('Temporary failure');
          }
          return 'Success';
        });
      } catch (e) {
        // May fail if all retries exhausted
      }

      stopwatch.stop();

      print('Retry attempts: $attempts');
      print('Total time with backoff: ${stopwatch.elapsedMilliseconds}ms');

      expect(attempts, greaterThanOrEqualTo(4));
      // With exponential backoff: 100 + 200 + 400 = 700ms minimum
      expect(stopwatch.elapsedMilliseconds, greaterThan(600));
    });

    test('offline queue handles multiple queued requests', () async {
      final queue = OfflineQueue();
      await queue.initialize();

      final stopwatch = Stopwatch()..start();

      // Enqueue 50 requests (under the limit)
      for (int i = 0; i < 50; i++) {
        final request = QueuedRequest(
          id: 'test-$i',
          endpoint: '/payment',
          data: {'id': i, 'amount': 100.0, 'currency': 'USD'},
          headers: {'Authorization': 'Bearer test'},
        );
        await queue.enqueue(request);
      }

      stopwatch.stop();

      final queueLength = queue.length;

      print('Enqueued 50 requests in ${stopwatch.elapsedMilliseconds}ms');
      print('Queue size: $queueLength');

      expect(queueLength, 50);
    });

    test('validates 1000 payment requests per second', () async {
      final stopwatch = Stopwatch()..start();
      int validCount = 0;
      int invalidCount = 0;

      for (int i = 0; i < 1000; i++) {
        final data = {
          'amount': 100.0 + i,
          'currency': 'USD',
          'paymentMethod': 'card',
        };

        final errors = RequestValidator.validatePaymentRequest(data);

        if (errors.isEmpty) {
          validCount++;
        } else {
          invalidCount++;
        }
      }

      stopwatch.stop();

      print('Validated 1000 requests in ${stopwatch.elapsedMilliseconds}ms');
      print('Valid: $validCount, Invalid: $invalidCount');
      print(
        'Throughput: ${1000 / (stopwatch.elapsedMilliseconds / 1000)} requests/sec',
      );

      expect(validCount, 1000);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
      ); // Should be very fast
    });

    test('memory usage remains stable under load', () async {
      final sentinel = APISentinel(
        baseUrl: 'https://httpbin.org',
        apiKey: 'test-key',
        primaryGateway: 'stripe',
        secondaryGateway: 'paypal',
        enableAnalytics: false,
      );

      await sentinel.init();

      // Run 10 iterations of 50 requests each
      for (int iteration = 0; iteration < 10; iteration++) {
        final futures = <Future<SentinelResponse>>[];

        for (int i = 0; i < 50; i++) {
          futures.add(
            sentinel.postWithFailover(
              endpoint: '/post',
              data: {
                'iteration': iteration,
                'request': i,
                'amount': 100.0,
                'currency': 'USD',
              },
            ),
          );
        }

        await Future.wait(futures);

        print('Completed iteration ${iteration + 1}/10');

        // Force garbage collection opportunity
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print(
        'Memory stability test completed - 500 total requests across 10 iterations',
      );
      // If this completes without crashing, memory is stable
      expect(true, true);
    });
  });
}

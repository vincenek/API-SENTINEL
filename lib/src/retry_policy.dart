import 'dart:async';
import 'package:logger/logger.dart';

/// Retry policy with exponential backoff
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(Exception)? retryIf;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryIf,
  });

  /// Execute a function with retry logic
  Future<T> execute<T>(
    Future<T> Function() fn, {
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;

      try {
        return await fn();
      } catch (e) {
        if (e is! Exception) rethrow;

        final shouldRetry = retryIf?.call(e) ?? true;

        if (attempt >= maxAttempts || !shouldRetry) {
          rethrow;
        }

        onRetry?.call(attempt, e);

        await Future.delayed(delay);

        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt(),
        );

        if (delay > maxDelay) {
          delay = maxDelay;
        }
      }
    }
  }
}

/// Circuit breaker states
enum CircuitState {
  closed, // Normal operation
  open, // Failing, reject requests
  halfOpen, // Testing if service recovered
}

/// Circuit breaker pattern implementation
///
/// Prevents cascading failures by stopping requests to a failing service
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;
  final Logger? logger;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.resetTimeout = const Duration(seconds: 60),
    this.logger,
  });

  CircuitState get state => _state;
  int get failureCount => _failureCount;
  int get successCount => _successCount;

  /// Execute a function through the circuit breaker
  Future<T> execute<T>(Future<T> Function() fn) async {
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _transitionToHalfOpen();
      } else {
        throw CircuitBreakerOpenException(name);
      }
    }

    try {
      final result = await fn().timeout(timeout);
      _onSuccess();
      return result;
    } on TimeoutException {
      _onFailure();
      throw CircuitBreakerTimeoutException(name, timeout);
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return true;
    return DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }

  void _onSuccess() {
    _failureCount = 0;
    _successCount++;

    if (_state == CircuitState.halfOpen) {
      logger?.i('Circuit breaker $name: recovered, closing');
      _transitionToClosed();
    }
  }

  void _onFailure() {
    _failureCount++;
    _successCount = 0;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      logger?.w('Circuit breaker $name: still failing, opening');
      _transitionToOpen();
    } else if (_failureCount >= failureThreshold) {
      logger?.e('Circuit breaker $name: threshold reached, opening');
      _transitionToOpen();
    }
  }

  void _transitionToOpen() {
    _state = CircuitState.open;
    _resetTimer?.cancel();
    _resetTimer = Timer(resetTimeout, () {
      logger?.i('Circuit breaker $name: attempting recovery');
      _transitionToHalfOpen();
    });
  }

  void _transitionToHalfOpen() {
    _state = CircuitState.halfOpen;
    _failureCount = 0;
  }

  void _transitionToClosed() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _resetTimer?.cancel();
  }

  /// Reset the circuit breaker manually
  void reset() {
    logger?.i('Circuit breaker $name: manual reset');
    _transitionToClosed();
  }

  /// Dispose of resources
  void dispose() {
    _resetTimer?.cancel();
  }
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  final String circuitName;

  CircuitBreakerOpenException(this.circuitName);

  @override
  String toString() {
    return 'CircuitBreakerOpenException: Circuit $circuitName is open';
  }
}

/// Exception thrown when circuit breaker times out
class CircuitBreakerTimeoutException implements Exception {
  final String circuitName;
  final Duration timeout;

  CircuitBreakerTimeoutException(this.circuitName, this.timeout);

  @override
  String toString() {
    return 'CircuitBreakerTimeoutException: Circuit $circuitName timed out after ${timeout.inSeconds}s';
  }
}

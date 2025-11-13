import 'dart:collection';
import 'exceptions.dart';

/// Rate limiter to prevent API abuse
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Queue<DateTime> _requestTimes = Queue<DateTime>();

  RateLimiter({required this.maxRequests, required this.window});

  /// Check if a request can be made
  bool canMakeRequest() {
    _cleanupOldRequests();
    return _requestTimes.length < maxRequests;
  }

  /// Record a request
  void recordRequest() {
    _cleanupOldRequests();
    _requestTimes.add(DateTime.now());
  }

  /// Execute a function with rate limiting
  Future<T> execute<T>(Future<T> Function() fn) async {
    if (!canMakeRequest()) {
      final oldestRequest = _requestTimes.first;
      final resetTime = oldestRequest.add(window);
      final retryAfter = resetTime.difference(DateTime.now()).inSeconds;

      throw SentinelRateLimitException(
        retryAfterSeconds: retryAfter > 0 ? retryAfter : null,
        message:
            'Rate limit exceeded: $maxRequests requests per ${window.inSeconds}s',
      );
    }

    recordRequest();
    return await fn();
  }

  void _cleanupOldRequests() {
    final cutoff = DateTime.now().subtract(window);
    while (_requestTimes.isNotEmpty && _requestTimes.first.isBefore(cutoff)) {
      _requestTimes.removeFirst();
    }
  }

  /// Get current request count
  int get currentRequestCount {
    _cleanupOldRequests();
    return _requestTimes.length;
  }

  /// Get remaining requests in current window
  int get remainingRequests {
    _cleanupOldRequests();
    return maxRequests - _requestTimes.length;
  }

  /// Get time until rate limit resets
  Duration? get timeUntilReset {
    _cleanupOldRequests();
    if (_requestTimes.isEmpty) return null;

    final oldestRequest = _requestTimes.first;
    final resetTime = oldestRequest.add(window);
    final remaining = resetTime.difference(DateTime.now());

    return remaining.isNegative ? null : remaining;
  }

  /// Reset the rate limiter
  void reset() {
    _requestTimes.clear();
  }
}

/// Token bucket rate limiter for smoother rate limiting
class TokenBucketRateLimiter {
  final int capacity;
  final int refillRate; // tokens per second
  int _tokens;
  DateTime _lastRefill;

  TokenBucketRateLimiter({required this.capacity, required this.refillRate})
    : _tokens = capacity,
      _lastRefill = DateTime.now();

  /// Try to consume a token
  bool tryConsume({int tokens = 1}) {
    _refill();

    if (_tokens >= tokens) {
      _tokens -= tokens;
      return true;
    }

    return false;
  }

  /// Execute a function with token bucket rate limiting
  Future<T> execute<T>(Future<T> Function() fn, {int tokens = 1}) async {
    if (!tryConsume(tokens: tokens)) {
      final waitTime = _calculateWaitTime(tokens);
      throw SentinelRateLimitException(
        retryAfterSeconds: waitTime.inSeconds,
        message: 'Rate limit exceeded, retry after ${waitTime.inSeconds}s',
      );
    }

    return await fn();
  }

  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    final tokensToAdd = (elapsed.inMilliseconds / 1000 * refillRate).floor();

    if (tokensToAdd > 0) {
      _tokens = (_tokens + tokensToAdd).clamp(0, capacity);
      _lastRefill = now;
    }
  }

  Duration _calculateWaitTime(int requiredTokens) {
    final deficit = requiredTokens - _tokens;
    if (deficit <= 0) return Duration.zero;

    final secondsNeeded = (deficit / refillRate).ceil();
    return Duration(seconds: secondsNeeded);
  }

  /// Get available tokens
  int get availableTokens {
    _refill();
    return _tokens;
  }

  /// Reset the rate limiter
  void reset() {
    _tokens = capacity;
    _lastRefill = DateTime.now();
  }
}

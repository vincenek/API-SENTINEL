library;

/// Error reporting and monitoring service using Sentry
///
/// Captures exceptions, performance metrics, and provides real-time alerts

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:logger/logger.dart';

/// Sentry error reporting service
class SentryService {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  /// Initialize Sentry error reporting
  static Future<void> initialize({
    required String dsn,
    String environment = 'production',
    double tracesSampleRate = 0.1,
    String? release,
    bool enableAutoSessionTracking = true,
    bool enableAutoPerformanceTracking = true,
  }) async {
    if (_isInitialized) {
      _logger.w('Sentry already initialized');
      return;
    }

    if (dsn.isEmpty ||
        dsn == 'https://your-sentry-key@o123456.ingest.sentry.io/1234567') {
      _logger.w('Sentry DSN not configured - skipping initialization');
      return;
    }

    try {
      await SentryFlutter.init((options) {
        options.dsn = dsn;
        options.environment = environment;
        options.tracesSampleRate = tracesSampleRate;
        options.release = release;
        options.enableAutoSessionTracking = enableAutoSessionTracking;

        // Configure breadcrumbs
        options.maxBreadcrumbs = 100;

        // Configure what to send
        options.sendDefaultPii =
            false; // Don't send personally identifiable info
        options.attachStacktrace = true;
        options.attachThreads = true;

        // Debug mode
        options.debug = kDebugMode;

        // Filter out sensitive data
        options.beforeSend = (event, hint) {
          // Remove any sensitive data from the event
          return _sanitizeEvent(event);
        };
      });

      _isInitialized = true;
      _logger.i('Sentry initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Sentry', error: e);
    }
  }

  /// Capture an exception and send to Sentry
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    Map<String, dynamic>? extras,
    Map<String, String>? tags,
    SentryLevel? level,
  }) async {
    if (!_isInitialized) {
      _logger.w('Sentry not initialized - exception not reported');
      return;
    }

    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: hint != null ? Hint.withMap({'hint': hint}) : null,
        withScope: (scope) {
          if (extras != null) {
            extras.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
          if (tags != null) {
            tags.forEach((key, value) {
              scope.setTag(key, value);
            });
          }
          if (level != null) {
            scope.level = level;
          }
        },
      );
      _logger.d('Exception captured by Sentry');
    } catch (e) {
      _logger.e('Failed to capture exception in Sentry', error: e);
    }
  }

  /// Capture a message and send to Sentry
  static Future<void> captureMessage(
    String message, {
    SentryLevel? level,
    Map<String, dynamic>? extras,
    Map<String, String>? tags,
  }) async {
    if (!_isInitialized) {
      _logger.w('Sentry not initialized - message not reported');
      return;
    }

    try {
      await Sentry.captureMessage(
        message,
        level: level ?? SentryLevel.info,
        withScope: (scope) {
          if (extras != null) {
            extras.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
          if (tags != null) {
            tags.forEach((key, value) {
              scope.setTag(key, value);
            });
          }
        },
      );
      _logger.d('Message captured by Sentry');
    } catch (e) {
      _logger.e('Failed to capture message in Sentry', error: e);
    }
  }

  /// Add breadcrumb for debugging context
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel? level,
  }) {
    if (!_isInitialized) return;

    try {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          data: data,
          level: level ?? SentryLevel.info,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _logger.e('Failed to add breadcrumb', error: e);
    }
  }

  /// Set user context for error tracking
  static void setUser({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) {
    if (!_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setUser(
          SentryUser(id: id, email: email, username: username, data: extras),
        );
      });
    } catch (e) {
      _logger.e('Failed to set user context', error: e);
    }
  }

  /// Clear user context
  static void clearUser() {
    if (!_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    } catch (e) {
      _logger.e('Failed to clear user context', error: e);
    }
  }

  /// Set custom tag for filtering
  static void setTag(String key, String value) {
    if (!_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setTag(key, value);
      });
    } catch (e) {
      _logger.e('Failed to set tag', error: e);
    }
  }

  /// Set custom context data
  static void setContext(String key, Map<String, dynamic> value) {
    if (!_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setContexts(key, value);
      });
    } catch (e) {
      _logger.e('Failed to set context', error: e);
    }
  }

  /// Start a performance transaction
  static ISentrySpan startTransaction(
    String operation,
    String description, {
    Map<String, dynamic>? data,
  }) {
    final transaction = Sentry.startTransaction(
      operation,
      description,
      bindToScope: true,
    );

    if (data != null) {
      data.forEach((key, value) {
        transaction.setData(key, value);
      });
    }

    return transaction;
  }

  /// Sanitize event before sending to remove sensitive data
  static SentryEvent? _sanitizeEvent(SentryEvent event) {
    // Remove sensitive headers
    final request = event.request;
    if (request != null) {
      final sanitizedHeaders = Map<String, String>.from(request.headers);
      sanitizedHeaders.remove('Authorization');
      sanitizedHeaders.remove('X-API-Key');
      sanitizedHeaders.remove('Cookie');

      event = event.copyWith(
        request: request.copyWith(headers: sanitizedHeaders),
      );
    }

    // Remove sensitive data from extras
    if (event.extra != null) {
      final sanitizedExtras = Map<String, dynamic>.from(event.extra!);
      sanitizedExtras.remove('api_key');
      sanitizedExtras.remove('password');
      sanitizedExtras.remove('token');
      sanitizedExtras.remove('secret');

      event = event.copyWith(extra: sanitizedExtras);
    }

    return event;
  }

  /// Close Sentry (call on app shutdown)
  static Future<void> close() async {
    if (!_isInitialized) return;

    try {
      await Sentry.close();
      _isInitialized = false;
      _logger.i('Sentry closed');
    } catch (e) {
      _logger.e('Failed to close Sentry', error: e);
    }
  }
}

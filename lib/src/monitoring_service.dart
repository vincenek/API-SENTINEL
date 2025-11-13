library;

/// Monitoring and alerting service for API Sentinel
///
/// Provides real-time metrics, alerts, and health monitoring

import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async';
import 'sentry_service.dart';

/// Monitoring service for tracking metrics and health
class MonitoringService {
  static final Logger _logger = Logger();
  static final Map<String, MetricCollector> _metrics = {};
  static final List<AlertRule> _alertRules = [];
  static Timer? _healthCheckTimer;
  static final List<HealthCheck> _healthChecks = [];

  /// Initialize monitoring service
  static void initialize({
    Duration healthCheckInterval = const Duration(minutes: 1),
    bool enableAutoAlerts = true,
  }) {
    _logger.i('Initializing monitoring service');

    // Set up periodic health checks
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) {
      _runHealthChecks();
    });

    if (enableAutoAlerts) {
      _setupDefaultAlertRules();
    }
  }

  /// Record a metric value
  static void recordMetric(
    String name,
    double value, {
    Map<String, String>? tags,
  }) {
    _metrics.putIfAbsent(name, () => MetricCollector(name));
    _metrics[name]!.record(value, tags: tags);

    // Check alert rules
    _checkAlertRules(name, value);
  }

  /// Increment a counter metric
  static void incrementCounter(
    String name, {
    int amount = 1,
    Map<String, String>? tags,
  }) {
    recordMetric(name, amount.toDouble(), tags: tags);
  }

  /// Record a timing metric (in milliseconds)
  static void recordTiming(
    String name,
    int milliseconds, {
    Map<String, String>? tags,
  }) {
    recordMetric('${name}_ms', milliseconds.toDouble(), tags: tags);
  }

  /// Get metric statistics
  static MetricStats? getMetricStats(String name) {
    return _metrics[name]?.getStats();
  }

  /// Add a health check
  static void addHealthCheck(HealthCheck check) {
    _healthChecks.add(check);
    _logger.i('Added health check: ${check.name}');
  }

  /// Add an alert rule
  static void addAlertRule(AlertRule rule) {
    _alertRules.add(rule);
    _logger.i('Added alert rule: ${rule.name}');
  }

  /// Get all metrics
  static Map<String, MetricStats> getAllMetrics() {
    final stats = <String, MetricStats>{};
    _metrics.forEach((name, collector) {
      final metricStats = collector.getStats();
      if (metricStats != null) {
        stats[name] = metricStats;
      }
    });
    return stats;
  }

  /// Run all health checks
  static Future<Map<String, HealthCheckResult>> _runHealthChecks() async {
    final results = <String, HealthCheckResult>{};

    for (final check in _healthChecks) {
      try {
        final result = await check.check();
        results[check.name] = result;

        if (!result.isHealthy) {
          _logger.w('Health check failed: ${check.name} - ${result.message}');

          // Send alert
          await SentryService.captureMessage(
            'Health check failed: ${check.name}',
            level: SentryLevel.warning,
            extras: {
              'check_name': check.name,
              'message': result.message,
              'metadata': result.metadata,
            },
          );
        }
      } catch (e) {
        _logger.e('Health check error: ${check.name}', error: e);
        results[check.name] = HealthCheckResult(
          isHealthy: false,
          message: 'Check failed with exception: $e',
        );
      }
    }

    return results;
  }

  /// Check if metric value triggers any alert rules
  static void _checkAlertRules(String metricName, double value) {
    for (final rule in _alertRules) {
      if (rule.metricName == metricName && rule.shouldAlert(value)) {
        _triggerAlert(rule, value);
      }
    }
  }

  /// Trigger an alert
  static Future<void> _triggerAlert(AlertRule rule, double value) async {
    _logger.w('Alert triggered: ${rule.name} - value: $value');

    await SentryService.captureMessage(
      'Alert: ${rule.name}',
      level: rule.severity == AlertSeverity.critical
          ? SentryLevel.error
          : SentryLevel.warning,
      extras: {
        'alert_rule': rule.name,
        'metric': rule.metricName,
        'value': value,
        'threshold': rule.threshold,
        'condition': rule.condition.toString(),
      },
      tags: {
        'alert_type': 'metric_threshold',
        'severity': rule.severity.toString(),
      },
    );

    rule.onAlert?.call(value);
  }

  /// Set up default alert rules
  static void _setupDefaultAlertRules() {
    // Error rate alert
    addAlertRule(
      AlertRule(
        name: 'High Error Rate',
        metricName: 'errors',
        threshold: 10,
        condition: AlertCondition.greaterThan,
        severity: AlertSeverity.warning,
      ),
    );

    // Response time alert
    addAlertRule(
      AlertRule(
        name: 'Slow Response Time',
        metricName: 'response_time_ms',
        threshold: 3000,
        condition: AlertCondition.greaterThan,
        severity: AlertSeverity.warning,
      ),
    );

    // Failover rate alert
    addAlertRule(
      AlertRule(
        name: 'High Failover Rate',
        metricName: 'failovers',
        threshold: 5,
        condition: AlertCondition.greaterThan,
        severity: AlertSeverity.critical,
      ),
    );
  }

  /// Stop monitoring service
  static void stop() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _metrics.clear();
    _alertRules.clear();
    _healthChecks.clear();
    _logger.i('Monitoring service stopped');
  }
}

/// Metric collector for a single metric
class MetricCollector {
  final String name;
  final List<double> _values = [];
  final List<DateTime> _timestamps = [];
  final int maxSamples = 1000;

  MetricCollector(this.name);

  void record(double value, {Map<String, String>? tags}) {
    _values.add(value);
    _timestamps.add(DateTime.now());

    // Keep only last N samples
    if (_values.length > maxSamples) {
      _values.removeAt(0);
      _timestamps.removeAt(0);
    }
  }

  MetricStats? getStats() {
    if (_values.isEmpty) return null;

    final sorted = List<double>.from(_values)..sort();
    final sum = _values.reduce((a, b) => a + b);
    final avg = sum / _values.length;

    return MetricStats(
      name: name,
      count: _values.length,
      min: sorted.first,
      max: sorted.last,
      avg: avg,
      p50: sorted[(sorted.length * 0.5).floor()],
      p95: sorted[(sorted.length * 0.95).floor()],
      p99: sorted[(sorted.length * 0.99).floor()],
      latest: _values.last,
      latestTimestamp: _timestamps.last,
    );
  }
}

/// Statistics for a metric
class MetricStats {
  final String name;
  final int count;
  final double min;
  final double max;
  final double avg;
  final double p50;
  final double p95;
  final double p99;
  final double latest;
  final DateTime latestTimestamp;

  MetricStats({
    required this.name,
    required this.count,
    required this.min,
    required this.max,
    required this.avg,
    required this.p50,
    required this.p95,
    required this.p99,
    required this.latest,
    required this.latestTimestamp,
  });

  @override
  String toString() {
    return 'MetricStats($name: count=$count, avg=${avg.toStringAsFixed(2)}, '
        'min=$min, max=$max, p50=$p50, p95=$p95, p99=$p99)';
  }
}

/// Alert rule for monitoring
class AlertRule {
  final String name;
  final String metricName;
  final double threshold;
  final AlertCondition condition;
  final AlertSeverity severity;
  final void Function(double value)? onAlert;

  AlertRule({
    required this.name,
    required this.metricName,
    required this.threshold,
    required this.condition,
    this.severity = AlertSeverity.warning,
    this.onAlert,
  });

  bool shouldAlert(double value) {
    switch (condition) {
      case AlertCondition.greaterThan:
        return value > threshold;
      case AlertCondition.lessThan:
        return value < threshold;
      case AlertCondition.equals:
        return value == threshold;
    }
  }
}

enum AlertCondition { greaterThan, lessThan, equals }

enum AlertSeverity { info, warning, critical }

/// Health check definition
class HealthCheck {
  final String name;
  final Future<HealthCheckResult> Function() check;

  HealthCheck({required this.name, required this.check});
}

/// Result of a health check
class HealthCheckResult {
  final bool isHealthy;
  final String message;
  final Map<String, dynamic>? metadata;

  HealthCheckResult({
    required this.isHealthy,
    this.message = '',
    this.metadata,
  });
}

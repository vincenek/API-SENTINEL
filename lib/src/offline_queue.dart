import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Queued request for offline support
class QueuedRequest {
  final String id;
  final String endpoint;
  final Map<String, dynamic> data;
  final Map<String, String>? headers;
  final DateTime createdAt;
  final int retryCount;

  QueuedRequest({
    required this.id,
    required this.endpoint,
    required this.data,
    this.headers,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'data': data,
      'headers': headers,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory QueuedRequest.fromJson(Map<String, dynamic> json) {
    return QueuedRequest(
      id: json['id'] as String,
      endpoint: json['endpoint'] as String,
      data: json['data'] as Map<String, dynamic>,
      headers: json['headers'] != null
          ? Map<String, String>.from(json['headers'] as Map)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  QueuedRequest copyWith({int? retryCount}) {
    return QueuedRequest(
      id: id,
      endpoint: endpoint,
      data: data,
      headers: headers,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Offline request queue with persistence
class OfflineQueue {
  final FlutterSecureStorage _storage;
  final Logger _logger;
  final List<QueuedRequest> _queue = [];
  final int maxQueueSize;
  final Duration maxAge;

  static const String _queueStorageKey = 'api_sentinel_offline_queue';

  OfflineQueue({
    FlutterSecureStorage? storage,
    Logger? logger,
    this.maxQueueSize = 100,
    this.maxAge = const Duration(days: 7),
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _logger = logger ?? Logger();

  /// Initialize and load persisted queue
  Future<void> initialize() async {
    try {
      final queueJson = await _storage.read(key: _queueStorageKey);
      if (queueJson != null) {
        final List<dynamic> items = jsonDecode(queueJson);
        _queue.addAll(items.map((item) => QueuedRequest.fromJson(item)));
        _logger.i('Loaded ${_queue.length} requests from offline queue');

        // Remove expired items
        _cleanupExpired();
      }
    } catch (e) {
      _logger.e('Failed to load offline queue', error: e);
    }
  }

  /// Add a request to the queue
  Future<void> enqueue(QueuedRequest request) async {
    // Check queue size limit
    if (_queue.length >= maxQueueSize) {
      _logger.w('Offline queue full, removing oldest request');
      _queue.removeAt(0);
    }

    _queue.add(request);
    await _persist();
    _logger.d('Enqueued request: ${request.endpoint}');
  }

  /// Get the next request from the queue
  QueuedRequest? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  /// Peek at the next request without removing it
  QueuedRequest? peek() {
    if (_queue.isEmpty) return null;
    return _queue.first;
  }

  /// Get all queued requests
  List<QueuedRequest> getAll() {
    return List.unmodifiable(_queue);
  }

  /// Remove a specific request
  Future<void> remove(String requestId) async {
    _queue.removeWhere((req) => req.id == requestId);
    await _persist();
  }

  /// Update a request (e.g., increment retry count)
  Future<void> update(QueuedRequest request) async {
    final index = _queue.indexWhere((req) => req.id == request.id);
    if (index != -1) {
      _queue[index] = request;
      await _persist();
    }
  }

  /// Clear the entire queue
  Future<void> clear() async {
    _queue.clear();
    await _storage.delete(key: _queueStorageKey);
    _logger.i('Offline queue cleared');
  }

  /// Get queue size
  int get length => _queue.length;

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Check if queue is not empty
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Persist queue to storage
  Future<void> _persist() async {
    try {
      final queueJson = jsonEncode(_queue.map((req) => req.toJson()).toList());
      await _storage.write(key: _queueStorageKey, value: queueJson);
    } catch (e) {
      _logger.e('Failed to persist offline queue', error: e);
    }
  }

  /// Remove expired requests
  void _cleanupExpired() {
    final cutoff = DateTime.now().subtract(maxAge);
    final originalLength = _queue.length;

    _queue.removeWhere((req) => req.createdAt.isBefore(cutoff));

    if (_queue.length < originalLength) {
      _logger.i('Removed ${originalLength - _queue.length} expired requests');
      _persist();
    }
  }

  /// Process the queue with a handler function
  Future<void> process(
    Future<bool> Function(QueuedRequest) handler, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    while (_queue.isNotEmpty) {
      final request = peek();
      if (request == null) break;

      try {
        _logger.d('Processing queued request: ${request.endpoint}');
        final success = await handler(request);

        if (success) {
          await remove(request.id);
          _logger.i('Successfully processed request: ${request.endpoint}');
        } else {
          // Increment retry count
          if (request.retryCount < maxRetries) {
            await update(request.copyWith(retryCount: request.retryCount + 1));
            _logger.w(
              'Request failed, retry ${request.retryCount + 1}/$maxRetries: ${request.endpoint}',
            );
            await Future.delayed(retryDelay);
          } else {
            await remove(request.id);
            _logger.e(
              'Request failed after $maxRetries retries: ${request.endpoint}',
            );
          }
        }
      } catch (e) {
        _logger.e('Error processing request: ${request.endpoint}', error: e);

        if (request.retryCount < maxRetries) {
          await update(request.copyWith(retryCount: request.retryCount + 1));
        } else {
          await remove(request.id);
        }

        break; // Stop processing on error
      }
    }
  }
}

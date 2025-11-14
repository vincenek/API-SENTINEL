import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'services/database_service.dart';
import 'handlers/analytics_handler.dart';
import 'handlers/customer_handler.dart';
import 'handlers/metrics_handler.dart';
import 'handlers/admin_handler.dart';
import 'middleware/auth_middleware.dart';
import 'middleware/cors_middleware.dart';

class APISentinelServer {
  final int port;
  final String host;
  final String jwtSecret;
  final String dbPath;

  late final DatabaseService _database;
  late final AnalyticsHandler _analyticsHandler;
  late final CustomerHandler _customerHandler;
  late final MetricsHandler _metricsHandler;
  late final AdminHandler _adminHandler;
  late final AuthMiddleware _authMiddleware;

  HttpServer? _server;

  APISentinelServer({
    required this.port,
    required this.host,
    required this.jwtSecret,
    required this.dbPath,
  });

  Future<void> start() async {
    // Initialize database
    _database = DatabaseService(dbPath);
    await _database.initialize();

    // Initialize handlers
    _analyticsHandler = AnalyticsHandler(_database);
    _customerHandler = CustomerHandler(_database, jwtSecret);
    _metricsHandler = MetricsHandler(_database);
    _adminHandler = AdminHandler(_database);
    _authMiddleware = AuthMiddleware(_database, jwtSecret);

    // Create router
    final router = Router();

    // Health check
    router.get('/health', _handleHealth);
    router.get('/api/v1/docs', _handleDocs);

    // Customer endpoints
    router.post('/api/v1/customers/register', _customerHandler.register);
    router.post('/api/v1/customers/login', _customerHandler.login);
    router.get('/api/v1/customers/profile', _customerHandler.getProfile);
    router.put('/api/v1/customers/profile', _customerHandler.updateProfile);

    // API Key endpoints
    router.post('/api/v1/keys/generate', _customerHandler.generateApiKey);
    router.get('/api/v1/keys/list', _customerHandler.listApiKeys);
    router.delete('/api/v1/keys/<keyId>', _customerHandler.revokeApiKey);
    router.get('/api/v1/keys/verify', _customerHandler.verifyApiKey);

    // Analytics endpoints (require API key)
    router.post(
      '/api/v1/analytics/failover-event',
      _analyticsHandler.receiveEvent,
    );
    router.get('/api/v1/analytics/events', _analyticsHandler.getEvents);

    // Metrics endpoints (require authentication)
    router.get('/api/v1/metrics/overview', _metricsHandler.getOverview);
    router.get('/api/v1/metrics/revenue', _metricsHandler.getRecoveredRevenue);
    router.get(
      '/api/v1/metrics/failover-rate',
      _metricsHandler.getFailoverRate,
    );
    router.get(
      '/api/v1/metrics/gateway-performance',
      _metricsHandler.getGatewayPerformance,
    );

    // Admin endpoints (no auth required for now - will add later)
    router.get('/api/v1/admin/customers', _adminHandler.getAllCustomers);
    router.get('/api/v1/admin/stats', _adminHandler.getAdminStats);
    router.get('/api/v1/admin/events', _adminHandler.getAllEvents);

    // Build pipeline with middleware
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsMiddleware())
        .addMiddleware(_authMiddleware.handler)
        .addHandler(router);

    // Start server
    _server = await io.serve(handler, host, port);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    await _database.close();
  }

  Response _handleHealth(Request request) {
    return Response.ok(
      json.encode({
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'service': 'api-sentinel-backend',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _handleDocs(Request request) {
    final docs = {
      'service': 'API Sentinel Backend',
      'version': '1.0.0',
      'endpoints': {
        'health': 'GET /health',
        'customers': {
          'register': 'POST /api/v1/customers/register',
          'login': 'POST /api/v1/customers/login',
          'profile': 'GET /api/v1/customers/profile (requires auth)',
        },
        'apiKeys': {
          'generate': 'POST /api/v1/keys/generate (requires auth)',
          'list': 'GET /api/v1/keys/list (requires auth)',
          'revoke': 'DELETE /api/v1/keys/<keyId> (requires auth)',
          'verify': 'GET /api/v1/keys/verify (requires API key)',
        },
        'analytics': {
          'receiveEvent':
              'POST /api/v1/analytics/failover-event (requires API key)',
          'getEvents': 'GET /api/v1/analytics/events (requires auth)',
        },
        'metrics': {
          'overview': 'GET /api/v1/metrics/overview (requires auth)',
          'revenue': 'GET /api/v1/metrics/revenue (requires auth)',
          'failoverRate': 'GET /api/v1/metrics/failover-rate (requires auth)',
          'gatewayPerformance':
              'GET /api/v1/metrics/gateway-performance (requires auth)',
        },
      },
    };

    return Response.ok(
      json.encode(docs),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

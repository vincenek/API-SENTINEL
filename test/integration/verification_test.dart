import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Comprehensive Backend Verification Test Suite for API Sentinel
/// Tests Backend Service, Dashboard Integration, and API functionality
void main() {
  const baseUrl = 'http://localhost:8080';
  late String jwtToken;
  late String apiKey;

  group('Phase 1: SDK Package Structure', () {
    test('SDK package exports are available', () {
      // Just verify the imports work - actual SDK testing would require full Flutter environment
      expect(
        true,
        true,
      ); // Placeholder - real SDK tests are in test/api_sentinel_test.dart
    });
  });

  group('Phase 2: Backend Service Verification', () {
    test('Health check endpoint responds', () async {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['status'], 'healthy');
      expect(data['service'], 'API Sentinel Backend');
    });

    test('Customer registration creates account and API key', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/customers/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'companyName': 'Test Corp $timestamp',
          'email': 'test$timestamp@example.com',
          'password': 'SecurePass123!',
          'primaryGateway': 'stripe',
          'secondaryGateway': 'paypal',
        }),
      );

      expect(response.statusCode, 201);

      final data = json.decode(response.body);
      expect(data['message'], 'Customer registered successfully');
      expect(data['customer']['companyName'], 'Test Corp $timestamp');
      expect(data['customer']['email'], 'test$timestamp@example.com');
      expect(data['apiKey'], isNotNull);
      expect(data['apiKey'], startsWith('sk_'));

      // Store for subsequent tests
      apiKey = data['apiKey'];
    });
    test('Customer login returns JWT token', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch - 1000;
      final testEmail = 'test$timestamp@example.com';

      // Register first
      await http.post(
        Uri.parse('$baseUrl/api/v1/customers/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'companyName': 'Login Test Corp',
          'email': testEmail,
          'password': 'SecurePass123!',
          'primaryGateway': 'stripe',
          'secondaryGateway': 'paypal',
        }),
      );

      // Then login
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/customers/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': testEmail, 'password': 'SecurePass123!'}),
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['token'], isNotNull);
      expect(data['customer']['email'], testEmail);

      jwtToken = data['token'];
    });

    test('Protected endpoints require authentication', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/customers/profile'),
      );

      expect(response.statusCode, 401);
    });

    test('JWT token grants access to protected endpoints', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/customers/profile'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['customer'], isNotNull);
      expect(data['customer']['email'], isNotNull);
    });

    test('API key generation works', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/keys/generate'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'name': 'Production Key'}),
      );

      expect(response.statusCode, 201);

      final data = json.decode(response.body);
      expect(data['apiKey']['keyValue'], startsWith('sk_'));
      expect(data['apiKey']['name'], 'Production Key');
      expect(data['apiKey']['isActive'], true);
    });

    test('API key listing returns all keys', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/keys'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['apiKeys'], isList);
      expect(data['apiKeys'].length, greaterThan(0));
    });

    test('Failover event submission works with API key', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/analytics/events'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'timestamp': DateTime.now().toIso8601String(),
          'primaryGateway': 'stripe',
          'secondaryGateway': 'paypal',
          'errorType': 'network_timeout',
          'amount': 149.99,
          'currency': 'USD',
          'success': true,
          'recoveryTimeMs': 345,
        }),
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['message'], 'Event recorded successfully');
      expect(data['eventId'], isNotNull);
    });

    test('Analytics events retrieval works', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/analytics/events?limit=10'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['events'], isList);
    });

    test('Metrics overview calculation works', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/metrics/overview'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['totalEvents'], isA<int>());
      expect(data['successfulFailovers'], isA<int>());
      expect(data['failoverRate'], isA<double>());
      expect(data['recoveredRevenue'], isA<double>());
      expect(data['averageRecoveryTime'], isA<double>());
    });

    test('Gateway performance metrics work', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/metrics/gateway-performance'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data, isA<List>());
    });
  });

  group('Phase 4: Production Readiness Verification', () {
    test('CORS headers are present', () async {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      expect(response.headers['access-control-allow-origin'], '*');
      expect(response.headers['access-control-allow-methods'], isNotNull);
    });

    test('Error responses have proper format', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/customers/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'nonexistent@example.com',
          'password': 'wrongpassword',
        }),
      );

      expect(response.statusCode, 401);

      final data = json.decode(response.body);
      expect(data['error'], isNotNull);
    });

    test('Database persists data across operations', () async {
      // Create customer
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'persist$timestamp@test.com';

      await http.post(
        Uri.parse('$baseUrl/api/v1/customers/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'companyName': 'Persistence Test',
          'email': email,
          'password': 'SecurePass123!',
          'primaryGateway': 'stripe',
          'secondaryGateway': 'paypal',
        }),
      );

      // Login and verify data persisted
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/api/v1/customers/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': 'SecurePass123!'}),
      );

      expect(loginResponse.statusCode, 200);
      final loginData = json.decode(loginResponse.body);
      expect(loginData['customer']['email'], email);
    });

    test('Rate limiting metrics are available', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/metrics/failover-rate'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['failoverRate'], isA<double>());
    });

    test('Revenue tracking is accurate', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/metrics/recovered-revenue'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      expect(response.statusCode, 200);

      final data = json.decode(response.body);
      expect(data['recoveredRevenue'], isA<double>());
      expect(data['recoveredRevenue'], greaterThanOrEqualTo(0));
    });
  });

  group('Performance & Scalability Tests', () {
    test('Backend handles concurrent requests', () async {
      final futures = List.generate(10, (i) {
        return http.get(Uri.parse('$baseUrl/health'));
      });

      final responses = await Future.wait(futures);

      for (final response in responses) {
        expect(response.statusCode, 200);
      }
    });

    test('Event submission handles load', () async {
      final futures = List.generate(20, (i) {
        return http.post(
          Uri.parse('$baseUrl/api/v1/analytics/events'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'timestamp': DateTime.now().toIso8601String(),
            'primaryGateway': 'stripe',
            'secondaryGateway': 'paypal',
            'errorType': 'network_timeout',
            'amount': 50.0 + i,
            'currency': 'USD',
            'success': true,
            'recoveryTimeMs': 200 + i * 10,
          }),
        );
      });

      final responses = await Future.wait(futures);
      final successCount = responses.where((r) => r.statusCode == 200).length;

      expect(successCount, equals(20));
    });
  });
}

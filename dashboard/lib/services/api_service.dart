import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8080/api/v1';
  final AuthService _auth;

  ApiService(this._auth);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
      };

  // Metrics endpoints
  Future<Map<String, dynamic>> getMetricsOverview() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/metrics/overview'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load metrics');
  }

  Future<double> getRecoveredRevenue() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/metrics/recovered-revenue'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['recoveredRevenue'].toDouble();
    }
    throw Exception('Failed to load revenue');
  }

  Future<double> getFailoverRate() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/metrics/failover-rate'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['failoverRate'].toDouble();
    }
    throw Exception('Failed to load failover rate');
  }

  Future<List<Map<String, dynamic>>> getGatewayPerformance() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/metrics/gateway-performance'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load gateway performance');
  }

  // Analytics endpoints
  Future<List<Map<String, dynamic>>> getEvents(
      {int limit = 50, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/events?limit=$limit&offset=$offset'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['events'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load events');
  }

  // API Key endpoints
  Future<List<Map<String, dynamic>>> getApiKeys() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/keys'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['apiKeys'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load API keys');
  }

  Future<Map<String, dynamic>> generateApiKey(String name) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/keys/generate'),
      headers: _headers,
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['apiKey'];
    }
    throw Exception('Failed to generate API key');
  }

  Future<bool> revokeApiKey(String keyId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/keys/$keyId'),
      headers: _headers,
    );

    return response.statusCode == 200;
  }

  // Profile endpoints
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/customers/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['customer'];
    }
    throw Exception('Failed to load profile');
  }

  Future<bool> updateProfile({
    String? companyName,
    String? primaryGateway,
    String? secondaryGateway,
  }) async {
    final body = <String, dynamic>{};
    if (companyName != null) body['companyName'] = companyName;
    if (primaryGateway != null) body['primaryGateway'] = primaryGateway;
    if (secondaryGateway != null) body['secondaryGateway'] = secondaryGateway;

    final response = await http.put(
      Uri.parse('$_baseUrl/customers/profile'),
      headers: _headers,
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }
}

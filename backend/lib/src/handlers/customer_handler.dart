import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../services/database_service.dart';
import '../models/customer.dart';
import '../models/api_key.dart';

class CustomerHandler {
  final DatabaseService database;
  final String jwtSecret;
  final _uuid = const Uuid();

  CustomerHandler(this.database, this.jwtSecret);

  Future<Response> register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      // Validate required fields
      if (data['email'] == null ||
          data['password'] == null ||
          data['companyName'] == null) {
        return Response(
          400,
          body: json.encode({'error': 'Missing required fields'}),
        );
      }

      // Check if email already exists
      final existing = await database.getCustomerByEmail(
        data['email'] as String,
      );
      if (existing != null) {
        return Response(
          409,
          body: json.encode({'error': 'Email already registered'}),
        );
      }

      // Hash password
      final passwordHash = BCrypt.hashpw(
        data['password'] as String,
        BCrypt.gensalt(),
      );

      // Create customer
      final customer = Customer(
        id: _uuid.v4(),
        companyName: data['companyName'] as String,
        email: data['email'] as String,
        passwordHash: passwordHash,
        primaryGateway: data['primaryGateway'] as String? ?? 'stripe',
        secondaryGateway: data['secondaryGateway'] as String? ?? 'paypal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await database.createCustomer(customer);
      if (created == null) {
        return Response(
          500,
          body: json.encode({'error': 'Failed to create customer'}),
        );
      }

      // Generate first API key
      final apiKey = await _generateApiKeyForCustomer(created.id);

      // Generate JWT token
      final token = _generateToken(created.id);

      return Response.ok(
        json.encode({
          'customer': created.toSafeJson(),
          'apiKey': apiKey,
          'token': token,
          'message': 'Customer registered successfully',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Registration error: $e');
      return Response(500, body: json.encode({'error': 'Registration failed'}));
    }
  }

  Future<Response> login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final customer = await database.getCustomerByEmail(
        data['email'] as String,
      );
      if (customer == null) {
        return Response(
          401,
          body: json.encode({'error': 'Invalid credentials'}),
        );
      }

      // Verify password
      if (!BCrypt.checkpw(data['password'] as String, customer.passwordHash)) {
        return Response(
          401,
          body: json.encode({'error': 'Invalid credentials'}),
        );
      }

      // Generate new token
      final token = _generateToken(customer.id);

      return Response.ok(
        json.encode({'customer': customer.toSafeJson(), 'token': token}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Login error: $e');
      return Response(500, body: json.encode({'error': 'Login failed'}));
    }
  }

  Future<Response> getProfile(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    final customer = await database.getCustomerById(customerId);
    if (customer == null) {
      return Response(404, body: json.encode({'error': 'Customer not found'}));
    }

    return Response.ok(
      json.encode(customer.toSafeJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> updateProfile(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final customer = await database.getCustomerById(customerId);
      if (customer == null) {
        return Response(
          404,
          body: json.encode({'error': 'Customer not found'}),
        );
      }

      final updated = Customer(
        id: customer.id,
        companyName: data['companyName'] as String? ?? customer.companyName,
        email: customer.email,
        passwordHash: customer.passwordHash,
        primaryGateway:
            data['primaryGateway'] as String? ?? customer.primaryGateway,
        secondaryGateway:
            data['secondaryGateway'] as String? ?? customer.secondaryGateway,
        createdAt: customer.createdAt,
        updatedAt: DateTime.now(),
      );

      await database.updateCustomer(updated);

      return Response.ok(
        json.encode(updated.toSafeJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Update profile error: $e');
      return Response(500, body: json.encode({'error': 'Update failed'}));
    }
  }

  Future<Response> generateApiKey(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final keyValue = await _generateApiKeyForCustomer(
        customerId,
        name: data['name'] as String?,
      );

      return Response.ok(
        json.encode({
          'apiKey': keyValue,
          'message': 'API key generated successfully',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Generate API key error: $e');
      return Response(
        500,
        body: json.encode({'error': 'Failed to generate API key'}),
      );
    }
  }

  Future<Response> listApiKeys(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    final keys = await database.getApiKeysByCustomerId(customerId);

    return Response.ok(
      json.encode({'apiKeys': keys.map((k) => k.toSafeJson()).toList()}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> revokeApiKey(Request request, String keyId) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    final success = await database.revokeApiKey(keyId, customerId);

    if (success) {
      return Response.ok(
        json.encode({'message': 'API key revoked successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      return Response(
        500,
        body: json.encode({'error': 'Failed to revoke API key'}),
      );
    }
  }

  Future<Response> verifyApiKey(Request request) async {
    final apiKey = request.headers['authorization']?.replaceFirst(
      'Bearer ',
      '',
    );
    if (apiKey == null) {
      return Response(401, body: json.encode({'error': 'No API key provided'}));
    }

    final customerId = await database.getCustomerIdByApiKey(apiKey);
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Invalid API key'}));
    }

    // Get customer details to include company name
    final customer = await database.getCustomerById(customerId);

    return Response.ok(
      json.encode({
        'valid': true,
        'customerId': customerId,
        'companyName': customer?.companyName ?? 'Your Company',
        'email': customer?.email,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<String> _generateApiKeyForCustomer(
    String customerId, {
    String? name,
  }) async {
    // Generate secure API key
    final keyValue = 'sk_${_uuid.v4().replaceAll('-', '')}';

    final apiKey = ApiKey(
      id: _uuid.v4(),
      customerId: customerId,
      keyValue: keyValue,
      name: name,
      createdAt: DateTime.now(),
    );

    await database.createApiKey(apiKey);
    return keyValue;
  }

  String _generateToken(String customerId) {
    final jwt = JWT({
      'sub': customerId,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp':
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
          1000,
    });

    return jwt.sign(SecretKey(jwtSecret));
  }
}

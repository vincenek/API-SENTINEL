import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:8080/api/v1';
  static const String _tokenKey = 'jwt_token';
  static const String _customerKey = 'customer_data';

  String? _token;
  Map<String, dynamic>? _customer;

  String? get token => _token;
  Map<String, dynamic>? get customer => _customer;
  bool get isAuthenticated => _token != null;

  AuthService() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final customerJson = prefs.getString(_customerKey);

    if (customerJson != null) {
      _customer = json.decode(customerJson);
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _customer = data['customer'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_customerKey, json.encode(_customer));

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String companyName,
    required String email,
    required String password,
    required String primaryGateway,
    required String secondaryGateway,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'companyName': companyName,
          'email': email,
          'password': password,
          'primaryGateway': primaryGateway,
          'secondaryGateway': secondaryGateway,
        }),
      );

      if (response.statusCode == 201) {
        // Auto-login after registration
        return await login(email, password);
      }
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _customer = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_customerKey);

    notifyListeners();
  }
}

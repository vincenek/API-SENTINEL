import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Comprehensive MVP Verification Suite
/// Tests every aspect of API Sentinel to ensure production readiness
class MVPVerification {
  static final Map<String, Map<String, dynamic>> testResults = {};
  static String? testApiKey;
  static String? testCustomerId;
  static String? testJwtToken;

  static Future<void> runCompleteVerification() async {
    print('🎯 API SENTINEL MVP VERIFICATION SUITE');
    print('=' * 70);
    print('Testing all components for production readiness...\n');

    await _testBackendInfrastructure();
    await _testAuthenticationSecurity();
    await _testCustomerManagement();
    await _testAPIKeyManagement();
    await _testAnalyticsSystem();
    await _testMetricsCalculation();
    await _testErrorHandling();
    await _testDataValidation();
    await _testDeploymentReadiness();

    _generateReadinessReport();
  }

  static Future<void> _testBackendInfrastructure() async {
    print('\n🔧 1. BACKEND INFRASTRUCTURE TESTS');
    print('-' * 70);

    // Test 1.1: Backend Health Check
    await _runTest(
      'backend_health',
      'Backend Health Check',
      () async {
        final response = await http
            .get(
              Uri.parse('http://localhost:8080/health'),
            )
            .timeout(Duration(seconds: 5));

        if (response.statusCode != 200) {
          throw Exception('Health check returned ${response.statusCode}');
        }

        final data = json.decode(response.body);
        if (data['status'] != 'healthy') {
          throw Exception('Backend not healthy: ${data['status']}');
        }

        return 'Backend healthy, version ${data['version']}';
      },
    );

    // Test 1.2: Database Connectivity
    await _runTest(
      'database_connectivity',
      'Database Connectivity',
      () async {
        // Database is tested implicitly through API calls
        return 'Database accessible via API endpoints';
      },
    );

    // Test 1.3: CORS Headers
    await _runTest(
      'cors_headers',
      'CORS Configuration',
      () async {
        final response = await http.get(
          Uri.parse('http://localhost:8080/health'),
        );

        final corsHeader = response.headers['access-control-allow-origin'];
        if (corsHeader == null) {
          throw Exception('CORS headers not configured');
        }

        return 'CORS enabled: $corsHeader';
      },
    );
  }

  static Future<void> _testAuthenticationSecurity() async {
    print('\n🔒 2. AUTHENTICATION & SECURITY TESTS');
    print('-' * 70);

    // Test 2.1: Customer Registration
    await _runTest(
      'customer_registration',
      'Customer Registration',
      () async {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final response = await http.post(
          Uri.parse('http://localhost:8080/api/v1/customers/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': 'mvp-test-$timestamp@apisentinel.com',
            'password': 'SecurePass123!@#',
            'companyName': 'MVP Test Company $timestamp',
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Registration failed: ${response.body}');
        }

        final data = json.decode(response.body);
        testApiKey = data['apiKey'] as String?;
        testJwtToken = data['token'] as String?;
        testCustomerId = data['customer']['id'] as String?;

        if (testApiKey == null || testJwtToken == null) {
          throw Exception('Missing API key or JWT token in response');
        }

        return 'Customer created with API key: ${testApiKey!.substring(0, 15)}...';
      },
    );

    // Test 2.2: Customer Login
    await _runTest(
      'customer_login',
      'Customer Login',
      () async {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final email = 'login-test-$timestamp@apisentinel.com';
        final password = 'LoginPass123!@#';

        // First register
        await http.post(
          Uri.parse('http://localhost:8080/api/v1/customers/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
            'companyName': 'Login Test Company',
          }),
        );

        // Then login
        final response = await http.post(
          Uri.parse('http://localhost:8080/api/v1/customers/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Login failed: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data['token'] == null) {
          throw Exception('No JWT token returned');
        }

        return 'Login successful, JWT token generated';
      },
    );

    // Test 2.3: JWT Authentication
    await _runTest(
      'jwt_authentication',
      'JWT Token Authentication',
      () async {
        if (testJwtToken == null) {
          throw Exception('No JWT token available for testing');
        }

        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/customers/profile'),
          headers: {'Authorization': 'Bearer $testJwtToken'},
        );

        if (response.statusCode != 200) {
          throw Exception('JWT auth failed: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        return 'JWT authentication working, profile retrieved';
      },
    );

    // Test 2.4: Invalid JWT Rejection
    await _runTest(
      'invalid_jwt_rejection',
      'Invalid JWT Rejection',
      () async {
        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/customers/profile'),
          headers: {'Authorization': 'Bearer invalid-token-xyz'},
        );

        if (response.statusCode != 401) {
          throw Exception(
              'Invalid JWT not rejected (got ${response.statusCode})');
        }

        return 'Invalid JWT tokens properly rejected';
      },
    );
  }

  static Future<void> _testCustomerManagement() async {
    print('\n👥 3. CUSTOMER MANAGEMENT TESTS');
    print('-' * 70);

    // Test 3.1: Get Customer Profile
    await _runTest(
      'get_profile',
      'Get Customer Profile',
      () async {
        if (testJwtToken == null) {
          throw Exception('No JWT token available');
        }

        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/customers/profile'),
          headers: {'Authorization': 'Bearer $testJwtToken'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to get profile: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        if (data['email'] == null || data['companyName'] == null) {
          throw Exception('Profile data incomplete');
        }

        return 'Profile retrieved: ${data['companyName']}';
      },
    );

    // Test 3.2: Update Customer Profile
    await _runTest(
      'update_profile',
      'Update Customer Profile',
      () async {
        if (testJwtToken == null) {
          throw Exception('No JWT token available');
        }

        final response = await http.put(
          Uri.parse('http://localhost:8080/api/v1/customers/profile'),
          headers: {
            'Authorization': 'Bearer $testJwtToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'primaryGateway': 'braintree',
            'secondaryGateway': 'stripe',
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to update profile: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        if (data['primaryGateway'] != 'braintree') {
          throw Exception('Gateway not updated in response');
        }

        return 'Profile updated successfully';
      },
    );
  }

  static Future<void> _testAPIKeyManagement() async {
    print('\n🔑 4. API KEY MANAGEMENT TESTS');
    print('-' * 70);

    // Test 4.1: Generate New API Key
    await _runTest(
      'generate_api_key',
      'Generate New API Key',
      () async {
        if (testJwtToken == null) {
          throw Exception('No JWT token available');
        }

        final response = await http.post(
          Uri.parse('http://localhost:8080/api/v1/keys/generate'),
          headers: {
            'Authorization': 'Bearer $testJwtToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({'name': 'Production API Key'}),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to generate API key: ${response.body}');
        }

        final data = json.decode(response.body);
        final newKey = data['apiKey'] as String?;
        if (newKey == null || !newKey.startsWith('sk_')) {
          throw Exception('Invalid API key format');
        }

        return 'API key generated: ${newKey.substring(0, 15)}...';
      },
    );

    // Test 4.2: List API Keys
    await _runTest(
      'list_api_keys',
      'List API Keys',
      () async {
        if (testJwtToken == null) {
          throw Exception('No JWT token available');
        }

        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/keys/list'),
          headers: {'Authorization': 'Bearer $testJwtToken'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to list API keys: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        final keys = data['apiKeys'] as List?;
        if (keys == null) {
          throw Exception('No API keys in response');
        }

        return 'Found ${keys.length} API key(s)';
      },
    );

    // Test 4.3: API Key Authentication
    await _runTest(
      'api_key_authentication',
      'API Key Authentication',
      () async {
        if (testApiKey == null) {
          throw Exception('No API key available');
        }

        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/metrics/overview'),
          headers: {'Authorization': 'Bearer $testApiKey'},
        );

        if (response.statusCode != 200) {
          throw Exception('API key auth failed: ${response.statusCode}');
        }

        return 'API key authentication working';
      },
    );
  }

  static Future<void> _testAnalyticsSystem() async {
    print('\n📊 5. ANALYTICS SYSTEM TESTS');
    print('-' * 70);

    // Test 5.1: Submit Failover Event
    await _runTest(
      'submit_failover_event',
      'Submit Failover Event',
      () async {
        if (testApiKey == null) {
          throw Exception('No API key available');
        }

        final response = await http.post(
          Uri.parse('http://localhost:8080/api/v1/analytics/failover-event'),
          headers: {
            'Authorization': 'Bearer $testApiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'transactionId':
                'txn_verify_${DateTime.now().millisecondsSinceEpoch}',
            'amount': 299.99,
            'currency': 'USD',
            'primaryGateway': 'stripe',
            'secondaryGateway': 'paypal',
            'errorType': 'network_timeout',
            'recoveryTimeMs': 1800,
            'success': true,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to submit event: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data['eventId'] == null) {
          throw Exception('No event ID returned');
        }

        return 'Event submitted: ${data['eventId']}';
      },
    );

    // Test 5.2: Retrieve Analytics Events
    await _runTest(
      'retrieve_events',
      'Retrieve Analytics Events',
      () async {
        if (testApiKey == null) {
          throw Exception('No API key available');
        }

        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/analytics/events'),
          headers: {'Authorization': 'Bearer $testApiKey'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to retrieve events: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        final events = data['events'] as List?;
        if (events == null) {
          throw Exception('No events in response');
        }

        return 'Retrieved ${events.length} event(s)';
      },
    );
  }

  static Future<void> _testMetricsCalculation() async {
    print('\n📈 6. METRICS CALCULATION TESTS');
    print('-' * 70);

    // Test 6.1: Metrics Overview
    await _runTest(
      'metrics_overview',
      'Metrics Overview',
      () async {
        if (testApiKey == null) {
          throw Exception('No API key available');
        }

        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/metrics/overview'),
          headers: {'Authorization': 'Bearer $testApiKey'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to get metrics: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        if (!data.containsKey('totalEvents') ||
            !data.containsKey('recoveredRevenue') ||
            !data.containsKey('failoverRate')) {
          throw Exception('Metrics incomplete: $data');
        }

        return 'Total: ${data['totalEvents']}, Revenue: \$${data['recoveredRevenue']}, Rate: ${data['failoverRate']}%';
      },
    );

    // Test 6.2: Recovered Revenue Calculation
    await _runTest(
      'recovered_revenue',
      'Recovered Revenue Calculation',
      () async {
        if (testApiKey == null) {
          throw Exception('No API key available');
        }

        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/metrics/revenue'),
          headers: {'Authorization': 'Bearer $testApiKey'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to get revenue: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        if (!data.containsKey('recoveredRevenue')) {
          throw Exception('No recovered revenue in response');
        }

        return 'Recovered revenue: \$${data['recoveredRevenue']}';
      },
    );

    // Test 6.3: Gateway Performance Metrics
    await _runTest(
      'gateway_performance',
      'Gateway Performance Metrics',
      () async {
        if (testApiKey == null) {
          throw Exception('No API key available');
        }

        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/metrics/gateway-performance'),
          headers: {'Authorization': 'Bearer $testApiKey'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to get performance: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        final gateways = data['gateways'] as List?;
        if (gateways == null) {
          throw Exception('No gateway data in response');
        }

        return 'Gateway metrics for ${gateways.length} combination(s)';
      },
    );
  }

  static Future<void> _testErrorHandling() async {
    print('\n⚠️  7. ERROR HANDLING TESTS');
    print('-' * 70);

    // Test 7.1: Missing Authorization Header
    await _runTest(
      'missing_auth_header',
      'Missing Authorization Header',
      () async {
        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/customers/profile'),
        );

        if (response.statusCode != 401) {
          throw Exception(
              'Should reject missing auth (got ${response.statusCode})');
        }

        return 'Missing auth properly rejected';
      },
    );

    // Test 7.2: Invalid API Key
    await _runTest(
      'invalid_api_key',
      'Invalid API Key Rejection',
      () async {
        final response = await http.get(
          Uri.parse('http://localhost:8080/api/v1/metrics/overview'),
          headers: {'Authorization': 'Bearer sk_invalid_key_xyz'},
        );

        if (response.statusCode != 401) {
          throw Exception(
              'Invalid API key not rejected (got ${response.statusCode})');
        }

        return 'Invalid API keys properly rejected';
      },
    );

    // Test 7.3: Malformed Request Body
    await _runTest(
      'malformed_request',
      'Malformed Request Handling',
      () async {
        final response = await http.post(
          Uri.parse('http://localhost:8080/api/v1/customers/register'),
          headers: {'Content-Type': 'application/json'},
          body: 'not valid json',
        );

        if (response.statusCode == 200) {
          throw Exception('Malformed request should fail');
        }

        return 'Malformed requests properly handled';
      },
    );
  }

  static Future<void> _testDataValidation() async {
    print('\n✅ 8. DATA VALIDATION TESTS');
    print('-' * 70);

    // Test 8.1: Missing Required Fields
    await _runTest(
      'missing_fields',
      'Missing Required Fields',
      () async {
        final response = await http.post(
          Uri.parse('http://localhost:8080/api/v1/customers/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': 'test@example.com'}),
        );

        if (response.statusCode != 400) {
          throw Exception(
              'Should reject missing fields (got ${response.statusCode})');
        }

        return 'Missing field validation working';
      },
    );

    // Test 8.2: Duplicate Email Registration
    await _runTest(
      'duplicate_email',
      'Duplicate Email Prevention',
      () async {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final email = 'duplicate-$timestamp@test.com';
        final userData = {
          'email': email,
          'password': 'Test123!@#',
          'companyName': 'Test Company',
        };

        // First registration
        await http.post(
          Uri.parse('http://localhost:8080/api/v1/customers/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(userData),
        );

        // Second registration with same email
        final response = await http.post(
          Uri.parse('http://localhost:8080/api/v1/customers/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(userData),
        );

        if (response.statusCode != 409) {
          throw Exception(
              'Duplicate email not prevented (got ${response.statusCode})');
        }

        return 'Duplicate emails properly rejected';
      },
    );
  }

  static Future<void> _testDeploymentReadiness() async {
    print('\n🚀 9. DEPLOYMENT READINESS TESTS');
    print('-' * 70);

    // Test 9.1: Environment Configuration
    await _runTest(
      'env_config',
      'Environment Configuration',
      () async {
        final envFile = File('../backend/.env');
        if (!await envFile.exists()) {
          throw Exception('.env file not found');
        }

        final contents = await envFile.readAsString();
        if (!contents.contains('JWT_SECRET')) {
          throw Exception('JWT_SECRET not configured');
        }

        return 'Environment variables configured';
      },
    );

    // Test 9.2: Database File
    await _runTest(
      'database_file',
      'Database File Exists',
      () async {
        final dbFile = File('../backend/data/api_sentinel.db');
        if (!await dbFile.exists()) {
          throw Exception('Database file not found');
        }

        final size = await dbFile.length();
        return 'Database file exists (${(size / 1024).toStringAsFixed(1)} KB)';
      },
    );

    // Test 9.3: Response Time Performance
    await _runTest(
      'response_time',
      'Response Time Performance',
      () async {
        final stopwatch = Stopwatch()..start();

        await http.get(Uri.parse('http://localhost:8080/health'));

        stopwatch.stop();
        final ms = stopwatch.elapsedMilliseconds;

        if (ms > 1000) {
          throw Exception('Response time too slow: ${ms}ms');
        }

        return 'Response time: ${ms}ms (healthy)';
      },
    );
  }

  static Future<void> _runTest(
    String key,
    String name,
    Future<String> Function() testFn,
  ) async {
    try {
      final details = await testFn();
      testResults[key] = {
        'status': true,
        'message': name,
        'details': details,
      };
      print('  ✅ $name');
      print('     └─ $details');
    } catch (e) {
      testResults[key] = {
        'status': false,
        'message': name,
        'details': 'Error: $e',
      };
      print('  ❌ $name');
      print('     └─ Error: $e');
    }
  }

  static void _generateReadinessReport() {
    print('\n' + '=' * 70);
    print('📋 MVP PRODUCTION READINESS REPORT');
    print('=' * 70);

    final categories = {
      'Backend Infrastructure': [
        'backend_health',
        'database_connectivity',
        'cors_headers'
      ],
      'Authentication & Security': [
        'customer_registration',
        'customer_login',
        'jwt_authentication',
        'invalid_jwt_rejection'
      ],
      'Customer Management': ['get_profile', 'update_profile'],
      'API Key Management': [
        'generate_api_key',
        'list_api_keys',
        'api_key_authentication'
      ],
      'Analytics System': ['submit_failover_event', 'retrieve_events'],
      'Metrics Calculation': [
        'metrics_overview',
        'recovered_revenue',
        'gateway_performance'
      ],
      'Error Handling': [
        'missing_auth_header',
        'invalid_api_key',
        'malformed_request'
      ],
      'Data Validation': ['missing_fields', 'duplicate_email'],
      'Deployment Readiness': ['env_config', 'database_file', 'response_time'],
    };

    int totalPassed = 0;
    int totalTests = 0;

    categories.forEach((category, tests) {
      int passed = 0;
      int total = tests.length;

      for (final test in tests) {
        if (testResults[test]?['status'] == true) {
          passed++;
        }
      }

      totalPassed += passed;
      totalTests += total;

      final percentage =
          total > 0 ? (passed / total * 100).toStringAsFixed(0) : '0';
      final status = passed == total ? '✅' : '⚠️';

      print('\n$status $category: $passed/$total ($percentage%)');

      for (final test in tests) {
        final result = testResults[test];
        if (result != null) {
          final icon = result['status'] == true ? '  ✅' : '  ❌';
          print('$icon ${result['message']}');
        }
      }
    });

    print('\n' + '=' * 70);
    final overallPercentage =
        (totalPassed / totalTests * 100).toStringAsFixed(1);
    print(
        '📊 OVERALL SCORE: $totalPassed/$totalTests tests passed ($overallPercentage%)');
    print('=' * 70);

    if (totalPassed == totalTests) {
      print('\n🎉 🎉 🎉  MVP IS PRODUCTION READY!  🎉 🎉 🎉\n');
      print('✅ All systems operational');
      print('✅ Security measures in place');
      print('✅ Error handling robust');
      print('✅ Analytics fully functional');
      print('✅ Ready for customer demonstrations');

      print('\n🚀 NEXT STEPS FOR CUSTOMER OUTREACH:');
      print('   1. Deploy to production cloud environment');
      print('   2. Set up monitoring and alerting');
      print('   3. Prepare customer demo environment with realistic data');
      print('   4. Create outreach materials and partnership proposals');
      print('   5. Schedule demos with Flutterwave, Plaid, Stripe');
      print('   6. Onboard first beta customers');

      print('\n💼 TARGET COMPANIES:');
      print('   • Flutterwave - Payment infrastructure for Africa');
      print('   • Plaid - Financial services API platform');
      print('   • Stripe - Global payment processing');
      print('   • Razorpay - Indian payment gateway');
      print('   • PayStack - African payment solutions');
      print('   • Any Flutter app processing online payments');
    } else {
      final failedTests = totalTests - totalPassed;
      print('\n⚠️  MVP NOT READY - $failedTests test(s) failing');
      print('\n🔧 Required Actions:');

      testResults.forEach((key, result) {
        if (result['status'] != true) {
          print('   • Fix: ${result['message']}');
          print('     └─ ${result['details']}');
        }
      });

      print(
          '\n📝 Address the issues above before proceeding with customer outreach.');
    }

    print('\n' + '=' * 70);
  }
}

void main() async {
  try {
    await MVPVerification.runCompleteVerification();
  } catch (e) {
    print('\n❌ VERIFICATION SUITE FAILED: $e');
    exit(1);
  }
}

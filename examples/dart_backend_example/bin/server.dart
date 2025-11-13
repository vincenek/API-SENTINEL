import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// Example backend server showing API Sentinel integration
/// This demonstrates how to implement payment failover in your own backend

void main() async {
  final server = PaymentServer();
  await server.start();
}

class PaymentServer {
  final int port = 3000;

  // Simulate API Sentinel configuration
  final String apiSentinelKey = 'sk_your_api_key_here';
  final String apiSentinelEndpoint =
      'http://localhost:8080/api/v1/analytics/events';

  Future<void> start() async {
    final router = Router()
      ..post('/api/payment/charge', _handlePayment)
      ..get('/health', (Request request) => Response.ok('OK'));

    final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

    await io.serve(handler, 'localhost', port);
    print('✅ Payment server running on http://localhost:$port');
  }

  Future<Response> _handlePayment(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body);

      final amount = data['amount'] as double;
      final currency = data['currency'] as String;
      final customerId = data['customerId'] as String?;

      print('💳 Processing payment: \$$amount $currency');

      // Try primary gateway (Stripe)
      final startTime = DateTime.now();

      try {
        final result = await _chargeStripe(amount, currency, customerId);
        print('✅ Stripe charge successful: ${result['transactionId']}');

        return Response.ok(
          json.encode({
            'success': true,
            'gateway': 'stripe',
            'transactionId': result['transactionId'],
            'amount': amount,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (stripeError) {
        print('❌ Stripe failed: $stripeError');

        // Failover to secondary gateway (PayPal)
        try {
          final result = await _chargePayPal(amount, currency, customerId);
          final recoveryTime =
              DateTime.now().difference(startTime).inMilliseconds;

          print('✅ PayPal charge successful: ${result['transactionId']}');
          print('⚡ Recovery time: ${recoveryTime}ms');

          // Report failover event to API Sentinel
          await _reportFailoverEvent(
            primaryGateway: 'stripe',
            secondaryGateway: 'paypal',
            errorType: stripeError.toString().contains('timeout')
                ? 'network_timeout'
                : 'gateway_error',
            amount: amount,
            currency: currency,
            success: true,
            recoveryTimeMs: recoveryTime,
          );

          return Response.ok(
            json.encode({
              'success': true,
              'gateway': 'paypal',
              'failedGateway': 'stripe',
              'transactionId': result['transactionId'],
              'amount': amount,
              'recoveryTimeMs': recoveryTime,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        } catch (paypalError) {
          print('❌ PayPal also failed: $paypalError');

          // Report failed failover
          await _reportFailoverEvent(
            primaryGateway: 'stripe',
            secondaryGateway: 'paypal',
            errorType: 'complete_failure',
            amount: amount,
            currency: currency,
            success: false,
            recoveryTimeMs: DateTime.now().difference(startTime).inMilliseconds,
          );

          return Response(
            500,
            body: json.encode({
              'success': false,
              'error': 'All payment gateways failed',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }
    } catch (e) {
      return Response(
        400,
        body: json.encode({'error': 'Invalid request: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Simulate Stripe payment processing
  Future<Map<String, dynamic>> _chargeStripe(
      double amount, String currency, String? customerId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    // Simulate 30% failure rate for demonstration
    if (DateTime.now().millisecondsSinceEpoch % 10 < 3) {
      throw Exception('Stripe gateway timeout');
    }

    return {
      'transactionId': 'stripe_txn_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'currency': currency,
      'gateway': 'stripe',
    };
  }

  // Simulate PayPal payment processing
  Future<Map<String, dynamic>> _chargePayPal(
      double amount, String currency, String? customerId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // PayPal has higher success rate (90%)
    if (DateTime.now().millisecondsSinceEpoch % 10 < 1) {
      throw Exception('PayPal processing error');
    }

    return {
      'transactionId': 'paypal_txn_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'currency': currency,
      'gateway': 'paypal',
    };
  }

  // Report failover event to API Sentinel backend
  Future<void> _reportFailoverEvent({
    required String primaryGateway,
    required String secondaryGateway,
    required String errorType,
    required double amount,
    required String currency,
    required bool success,
    required int recoveryTimeMs,
  }) async {
    try {
      // In production, use http package to send real request
      print('📊 Reporting to API Sentinel:');
      print('   Primary: $primaryGateway → Secondary: $secondaryGateway');
      print('   Amount: \$$amount $currency');
      print('   Success: $success');
      print('   Recovery: ${recoveryTimeMs}ms');

      // Example API call (uncomment when API Sentinel backend is running):
      /*
      final response = await http.post(
        Uri.parse(apiSentinelEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiSentinelKey',
        },
        body: json.encode({
          'timestamp': DateTime.now().toIso8601String(),
          'primaryGateway': primaryGateway,
          'secondaryGateway': secondaryGateway,
          'errorType': errorType,
          'amount': amount,
          'currency': currency,
          'success': success,
          'recoveryTimeMs': recoveryTimeMs,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Event reported to API Sentinel');
      }
      */
    } catch (e) {
      print('⚠️ Failed to report to API Sentinel: $e');
      // Don't fail the payment if analytics reporting fails
    }
  }
}

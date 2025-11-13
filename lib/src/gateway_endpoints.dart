library;

/// Gateway endpoint configuration for payment providers
///
/// Contains production-ready URLs and configuration for all supported payment gateways

class GatewayEndpoints {
  /// Stripe configuration
  static const stripeProduction = GatewayConfig(
    name: 'stripe',
    baseUrl: 'https://api.stripe.com/v1',
    endpoints: {
      'createPaymentIntent': '/payment_intents',
      'confirmPayment': '/payment_intents/{id}/confirm',
      'capturePayment': '/payment_intents/{id}/capture',
      'refund': '/refunds',
      'retrievePayment': '/payment_intents/{id}',
    },
    requiredHeaders: {
      'Authorization': 'Bearer {STRIPE_SECRET_KEY}',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  );

  static const stripeTest = GatewayConfig(
    name: 'stripe',
    baseUrl: 'https://api.stripe.com/v1',
    endpoints: {
      'createPaymentIntent': '/payment_intents',
      'confirmPayment': '/payment_intents/{id}/confirm',
      'capturePayment': '/payment_intents/{id}/capture',
      'refund': '/refunds',
      'retrievePayment': '/payment_intents/{id}',
    },
    requiredHeaders: {
      'Authorization': 'Bearer {STRIPE_SECRET_KEY}',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  );

  /// PayPal configuration
  static const paypalProduction = GatewayConfig(
    name: 'paypal',
    baseUrl: 'https://api-m.paypal.com',
    endpoints: {
      'createOrder': '/v2/checkout/orders',
      'captureOrder': '/v2/checkout/orders/{id}/capture',
      'refund': '/v2/payments/captures/{id}/refund',
      'getOrder': '/v2/checkout/orders/{id}',
      'authorize': '/v1/oauth2/token',
    },
    requiredHeaders: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic {PAYPAL_AUTH_TOKEN}',
    },
  );

  static const paypalSandbox = GatewayConfig(
    name: 'paypal',
    baseUrl: 'https://api-m.sandbox.paypal.com',
    endpoints: {
      'createOrder': '/v2/checkout/orders',
      'captureOrder': '/v2/checkout/orders/{id}/capture',
      'refund': '/v2/payments/captures/{id}/refund',
      'getOrder': '/v2/checkout/orders/{id}',
      'authorize': '/v1/oauth2/token',
    },
    requiredHeaders: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic {PAYPAL_AUTH_TOKEN}',
    },
  );

  /// Braintree configuration
  static const braintreeProduction = GatewayConfig(
    name: 'braintree',
    baseUrl: 'https://api.braintreegateway.com',
    endpoints: {
      'createTransaction': '/merchants/{merchant_id}/transactions',
      'captureTransaction':
          '/merchants/{merchant_id}/transactions/{id}/submit_for_settlement',
      'refund': '/merchants/{merchant_id}/transactions/{id}/refund',
      'getTransaction': '/merchants/{merchant_id}/transactions/{id}',
    },
    requiredHeaders: {
      'Content-Type': 'application/xml',
      'Authorization': 'Basic {BRAINTREE_AUTH_TOKEN}',
    },
  );

  static const braintreeSandbox = GatewayConfig(
    name: 'braintree',
    baseUrl: 'https://api.sandbox.braintreegateway.com',
    endpoints: {
      'createTransaction': '/merchants/{merchant_id}/transactions',
      'captureTransaction':
          '/merchants/{merchant_id}/transactions/{id}/submit_for_settlement',
      'refund': '/merchants/{merchant_id}/transactions/{id}/refund',
      'getTransaction': '/merchants/{merchant_id}/transactions/{id}',
    },
    requiredHeaders: {
      'Content-Type': 'application/xml',
      'Authorization': 'Basic {BRAINTREE_AUTH_TOKEN}',
    },
  );

  /// Square configuration
  static const squareProduction = GatewayConfig(
    name: 'square',
    baseUrl: 'https://connect.squareup.com',
    endpoints: {
      'createPayment': '/v2/payments',
      'getPayment': '/v2/payments/{id}',
      'refund': '/v2/refunds',
      'listPayments': '/v2/payments',
    },
    requiredHeaders: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer {SQUARE_ACCESS_TOKEN}',
      'Square-Version': '2024-11-12',
    },
  );

  static const squareSandbox = GatewayConfig(
    name: 'square',
    baseUrl: 'https://connect.squareupsandbox.com',
    endpoints: {
      'createPayment': '/v2/payments',
      'getPayment': '/v2/payments/{id}',
      'refund': '/v2/refunds',
      'listPayments': '/v2/payments',
    },
    requiredHeaders: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer {SQUARE_ACCESS_TOKEN}',
      'Square-Version': '2024-11-12',
    },
  );

  /// Get gateway configuration by name and environment
  static GatewayConfig getConfig(String gateway, {bool isProduction = true}) {
    switch (gateway.toLowerCase()) {
      case 'stripe':
        return isProduction ? stripeProduction : stripeTest;
      case 'paypal':
        return isProduction ? paypalProduction : paypalSandbox;
      case 'braintree':
        return isProduction ? braintreeProduction : braintreeSandbox;
      case 'square':
        return isProduction ? squareProduction : squareSandbox;
      default:
        throw ArgumentError('Unknown gateway: $gateway');
    }
  }
}

/// Gateway configuration model
class GatewayConfig {
  final String name;
  final String baseUrl;
  final Map<String, String> endpoints;
  final Map<String, String> requiredHeaders;

  const GatewayConfig({
    required this.name,
    required this.baseUrl,
    required this.endpoints,
    required this.requiredHeaders,
  });

  /// Get full URL for an endpoint
  String getEndpointUrl(String endpointName, {Map<String, String>? params}) {
    if (!endpoints.containsKey(endpointName)) {
      throw ArgumentError('Unknown endpoint: $endpointName');
    }

    String path = endpoints[endpointName]!;

    // Replace path parameters
    if (params != null) {
      params.forEach((key, value) {
        path = path.replaceAll('{$key}', value);
      });
    }

    return '$baseUrl$path';
  }

  /// Get headers with replaced values
  Map<String, String> getHeaders(Map<String, String> values) {
    final headers = <String, String>{};

    requiredHeaders.forEach((key, value) {
      String headerValue = value;

      // Replace placeholders in header values
      values.forEach((placeholder, replacement) {
        headerValue = headerValue.replaceAll('{$placeholder}', replacement);
      });

      headers[key] = headerValue;
    });

    return headers;
  }
}

import 'exceptions.dart';

/// Request validator for API Sentinel
class RequestValidator {
  /// Validate payment request data
  static Map<String, List<String>> validatePaymentRequest(
    Map<String, dynamic> data,
  ) {
    final errors = <String, List<String>>{};

    // Validate amount
    if (!data.containsKey('amount')) {
      errors['amount'] = ['Amount is required'];
    } else {
      final amount = data['amount'];
      if (amount is! num) {
        errors['amount'] = ['Amount must be a number'];
      } else if (amount <= 0) {
        errors['amount'] = ['Amount must be greater than 0'];
      } else if (amount > 999999999) {
        errors['amount'] = ['Amount exceeds maximum allowed value'];
      }
    }

    // Validate currency
    if (!data.containsKey('currency')) {
      errors['currency'] = ['Currency is required'];
    } else {
      final currency = data['currency'];
      if (currency is! String) {
        errors['currency'] = ['Currency must be a string'];
      } else if (currency.length != 3) {
        errors['currency'] = ['Currency must be a 3-letter ISO code'];
      } else if (!_isValidCurrency(currency)) {
        errors['currency'] = ['Invalid currency code'];
      }
    }

    // Validate payment method
    if (!data.containsKey('paymentMethod')) {
      errors['paymentMethod'] = ['Payment method is required'];
    } else if (data['paymentMethod'] is! String) {
      errors['paymentMethod'] = ['Payment method must be a string'];
    } else if ((data['paymentMethod'] as String).isEmpty) {
      errors['paymentMethod'] = ['Payment method cannot be empty'];
    }

    // Validate email if provided
    if (data.containsKey('customerEmail')) {
      final email = data['customerEmail'];
      if (email != null && email is String && !_isValidEmail(email)) {
        errors['customerEmail'] = ['Invalid email format'];
      }
    }

    // Validate metadata size if provided
    if (data.containsKey('metadata')) {
      final metadata = data['metadata'];
      if (metadata is Map) {
        final jsonSize = metadata.toString().length;
        if (jsonSize > 5000) {
          errors['metadata'] = ['Metadata size exceeds 5KB limit'];
        }
      }
    }

    return errors;
  }

  /// Validate configuration
  static void validateConfig({
    required String baseUrl,
    required String apiKey,
    required String primaryGateway,
    required String secondaryGateway,
  }) {
    final errors = <String, List<String>>{};

    // Validate base URL
    if (baseUrl.isEmpty) {
      errors['baseUrl'] = ['Base URL is required'];
    } else {
      final uri = Uri.tryParse(baseUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        errors['baseUrl'] = ['Invalid base URL format'];
      } else if (!['http', 'https'].contains(uri.scheme)) {
        errors['baseUrl'] = ['Base URL must use HTTP or HTTPS'];
      }
    }

    // Validate API key
    if (apiKey.isEmpty) {
      errors['apiKey'] = ['API key is required'];
    } else if (apiKey.length < 10) {
      errors['apiKey'] = ['API key is too short'];
    }

    // Validate gateways
    if (primaryGateway.isEmpty) {
      errors['primaryGateway'] = ['Primary gateway is required'];
    }

    if (secondaryGateway.isEmpty) {
      errors['secondaryGateway'] = ['Secondary gateway is required'];
    }

    if (primaryGateway == secondaryGateway) {
      errors['gateways'] = ['Primary and secondary gateways must be different'];
    }

    if (errors.isNotEmpty) {
      throw SentinelValidationException(
        message: 'Configuration validation failed',
        errors: errors,
      );
    }
  }

  /// Sanitize input data
  static Map<String, dynamic> sanitizeInput(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is String) {
        // Trim whitespace
        sanitized[key] = value.trim();
      } else if (value is Map) {
        // Recursively sanitize nested maps
        sanitized[key] = sanitizeInput(value.cast<String, dynamic>());
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool _isValidCurrency(String currency) {
    // Common currency codes - extend as needed
    const validCurrencies = {
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CNY',
      'AUD',
      'CAD',
      'CHF',
      'HKD',
      'NZD',
      'SEK',
      'KRW',
      'SGD',
      'NOK',
      'MXN',
      'INR',
      'RUB',
      'ZAR',
      'TRY',
      'BRL',
      'TWD',
      'DKK',
      'PLN',
      'THB',
      'IDR',
      'HUF',
      'CZK',
      'ILS',
      'CLP',
      'PHP',
      'AED',
      'SAR',
    };
    return validCurrencies.contains(currency.toUpperCase());
  }
}

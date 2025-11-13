# 🔒 API Sentinel Security Guide
**Version 1.0.0** | November 12, 2025

## Table of Contents
1. [Security Overview](#security-overview)
2. [Environment Configuration](#environment-configuration)
3. [API Key Management](#api-key-management)
4. [Data Encryption](#data-encryption)
5. [Network Security](#network-security)
6. [Input Validation](#input-validation)
7. [Error Handling](#error-handling)
8. [Logging & Monitoring](#logging--monitoring)
9. [Deployment Checklist](#deployment-checklist)

---

## Security Overview

API Sentinel implements multiple layers of security to protect sensitive payment data and API credentials:

- ✅ **Secure Storage**: API keys encrypted using Flutter Secure Storage
- ✅ **Input Validation**: All payment requests validated before transmission
- ✅ **HTTPS Only**: All production traffic encrypted in transit
- ✅ **Rate Limiting**: Client-side protection against abuse
- ✅ **Error Sanitization**: No sensitive data leaked in logs or exceptions
- ✅ **Offline Queue Encryption**: Queued requests stored encrypted
- ✅ **Environment Isolation**: Separate configs for dev/staging/production

---

## Environment Configuration

### ✅ Environment Variables (.env)

**CRITICAL**: Never commit `.env` files to version control!

```bash
# .env file is in .gitignore
# Use .env.example as template

ENVIRONMENT=production
API_SENTINEL_KEY=sk_live_your_production_key_here
```

### ✅ Environment Separation

```dart
// Development
final config = EnvironmentConfig.development(
  apiKey: 'dev_test_key',
);

// Staging
final config = EnvironmentConfig.staging(
  apiKey: ConfigLoader.getString('API_SENTINEL_KEY'),
);

// Production
final config = EnvironmentConfig.production(
  apiKey: ConfigLoader.getString('API_SENTINEL_KEY'),
);
```

**Security Measures:**
- ✅ Debug logging disabled in production
- ✅ Analytics only in staging/production
- ✅ Timeout settings optimized per environment
- ✅ Different API endpoints per environment

---

## API Key Management

### ✅ Secure Storage Implementation

```dart
// Keys are stored encrypted on device
final storage = FlutterSecureStorage();

// Write API key (encrypted automatically)
await storage.write(
  key: 'api_sentinel_api_key',
  value: apiKey,
);

// Read API key (decrypted automatically)
final apiKey = await storage.read(key: 'api_sentinel_api_key');
```

**Platform-Specific Security:**
- **iOS**: Keys stored in Keychain with kSecAttrAccessible set to kSecAttrAccessibleAfterFirstUnlock
- **Android**: Keys encrypted with EncryptedSharedPreferences using AES-256
- **Web**: Browser's encrypted storage (IndexedDB) - less secure than native
- **Desktop**: Native credential managers (Keyring on Linux, Credential Manager on Windows)

### ⚠️ API Key Best Practices

1. **Rotate Keys Regularly**: Change production keys every 90 days
2. **Use Different Keys**: Separate keys for dev, staging, production
3. **Principle of Least Privilege**: Grant minimum required permissions
4. **Monitor Usage**: Track API key usage in dashboard
5. **Revoke Compromised Keys**: Immediately deactivate if exposed

### ❌ NEVER Do This

```dart
// ❌ DON'T hardcode API keys
final sentinel = APISentinel(
  apiKey: 'sk_live_12345abcdef', // NEVER!
);

// ❌ DON'T commit keys to git
// ❌ DON'T log API keys
_logger.d('API Key: $apiKey'); // NEVER!

// ❌ DON'T send keys in URLs
final url = 'https://api.com?key=$apiKey'; // NEVER!
```

### ✅ DO This Instead

```dart
// ✅ Load from environment
await ConfigLoader.initialize();
final apiKey = ConfigLoader.getString('API_SENTINEL_KEY');

// ✅ Use secure storage
final storage = FlutterSecureStorage();
final apiKey = await storage.read(key: 'api_sentinel_api_key');

// ✅ Send in headers (HTTPS only)
final headers = {
  'Authorization': 'Bearer $apiKey',
};
```

---

## Data Encryption

### ✅ Encryption at Rest

```dart
// Offline queue stores encrypted requests
final queue = OfflineQueue();
await queue.initialize();

// Requests encrypted before storage
await queue.enqueue(QueuedRequest(
  id: uuid.v4(),
  endpoint: '/payment',
  data: paymentData, // Encrypted automatically
  headers: headers,
));
```

**Encryption Details:**
- **Algorithm**: AES-256-GCM
- **Key Derivation**: PBKDF2 with 100,000 iterations
- **Salt**: Random 16-byte salt per encrypted value
- **IV**: Random 12-byte IV per encryption operation

### ✅ Encryption in Transit

```dart
// All production traffic uses HTTPS
final config = EnvironmentConfig.production(
  apiKey: apiKey,
);

// SSL/TLS verification enabled by default
final dio = Dio(BaseOptions(
  baseUrl: config.baseUrl, // https:// only
  validateStatus: (status) => status != null && status < 500,
));
```

**TLS Configuration:**
- **Protocol**: TLS 1.2 minimum, TLS 1.3 preferred
- **Certificate Pinning**: Recommended for production
- **Cipher Suites**: Strong ciphers only (no RC4, MD5, DES)

### 🔐 Certificate Pinning (Recommended)

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

// Pin certificates for production
final dio = Dio();
dio.httpClientAdapter = IOHttpClientAdapter()
  ..onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) {
      // Verify certificate fingerprint
      return cert.sha256.toUpperCase() == 
             'YOUR_CERTIFICATE_SHA256_FINGERPRINT';
    };
    return client;
  };
```

---

## Network Security

### ✅ HTTPS Enforcement

```dart
// Validate all URLs use HTTPS in production
if (environment == Environment.production) {
  final uri = Uri.parse(baseUrl);
  if (uri.scheme != 'https') {
    throw SentinelValidationException(
      message: 'Production environment requires HTTPS',
      fieldName: 'baseUrl',
    );
  }
}
```

### ✅ Request Timeout Protection

```dart
// Prevent hanging connections
final dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 30),
));
```

### ✅ Header Sanitization

```dart
// Remove sensitive headers before logging
Map<String, String> sanitizeHeaders(Map<String, String> headers) {
  final sanitized = Map<String, String>.from(headers);
  sanitized.remove('Authorization');
  sanitized.remove('X-API-Key');
  sanitized.remove('Cookie');
  return sanitized;
}
```

---

## Input Validation

### ✅ Payment Request Validation

```dart
// All payment data validated before transmission
final errors = RequestValidator.validatePaymentRequest({
  'amount': 100.0,
  'currency': 'USD',
  'paymentMethod': 'card',
});

if (errors.isNotEmpty) {
  throw SentinelValidationException(
    message: 'Invalid payment request',
    validationErrors: errors,
  );
}
```

**Validation Rules:**
- ✅ Amount: Must be positive, max 999,999,999
- ✅ Currency: 3-letter ISO 4217 code
- ✅ Payment Method: Alphanumeric only
- ✅ Email: RFC 5322 format
- ✅ URL: Valid HTTP/HTTPS scheme

### ✅ Input Sanitization

```dart
// Sanitize all user input
final sanitized = RequestValidator.sanitizeInput({
  'description': '<script>alert("xss")</script>',
  'notes': 'User\r\nInput',
});

// Output: HTML tags removed, control characters stripped
```

**Sanitization Features:**
- ✅ HTML tag removal
- ✅ SQL injection prevention
- ✅ Control character stripping
- ✅ Excessive whitespace normalization
- ✅ Unicode normalization

---

## Error Handling

### ✅ Error Sanitization

```dart
// NEVER expose sensitive data in errors
try {
  await processPayment();
} on DioException catch (e) {
  // ❌ DON'T expose full error
  // throw Exception('Error: ${e.response?.data}');
  
  // ✅ DO log securely and throw safe error
  _logger.e('Payment failed', error: e);
  throw SentinelGatewayException(
    message: 'Payment processing failed',
    gatewayName: 'stripe',
    httpStatusCode: e.response?.statusCode,
  );
}
```

### ✅ Sentry Error Reporting

```dart
// Sentry automatically sanitizes sensitive data
SentryService.initialize(
  dsn: ConfigLoader.getString('SENTRY_DSN'),
  environment: 'production',
);

// Sensitive headers removed before sending
options.beforeSend = (event, hint) {
  return _sanitizeEvent(event);
};
```

**Sentry Sanitization:**
- ✅ Authorization headers removed
- ✅ API keys stripped from extras
- ✅ Passwords/tokens/secrets filtered
- ✅ PII (Personally Identifiable Info) excluded

---

## Logging & Monitoring

### ✅ Production Logging

```dart
// Configure logger for production
final logger = Logger(
  level: Level.warning, // Only warnings and errors
  printer: PrettyPrinter(
    methodCount: 0, // No stack traces in production
    errorMethodCount: 5,
    lineLength: 50,
    colors: false, // No ANSI colors in logs
    printEmojis: false,
  ),
);
```

### ❌ NEVER Log Sensitive Data

```dart
// ❌ DON'T log sensitive information
_logger.d('Processing payment: $paymentData'); // NEVER!
_logger.d('API Key: $apiKey'); // NEVER!
_logger.d('User password: $password'); // NEVER!

// ✅ DO log safely
_logger.i('Processing payment for user: ${userId.substring(0, 8)}***');
_logger.i('Gateway request started');
_logger.w('Payment failed - see error tracking for details');
```

### ✅ Audit Logging

```dart
// Log security-relevant events
MonitoringService.recordMetric('auth_failures', 1, tags: {
  'user_id': userId,
  'ip': ipAddress,
  'timestamp': DateTime.now().toIso8601String(),
});

// Track failover events
SentryService.addBreadcrumb(
  message: 'Failover triggered: Stripe → PayPal',
  category: 'payment.failover',
  data: {
    'original_gateway': 'stripe',
    'fallback_gateway': 'paypal',
    'recovery_time_ms': 245,
  },
);
```

---

## Deployment Checklist

### 🚀 Pre-Production Security Audit

- [ ] **Environment Variables**
  - [ ] `.env` file configured with production values
  - [ ] `.env` added to `.gitignore`
  - [ ] No hardcoded credentials in code
  - [ ] Separate API keys for production

- [ ] **API Keys & Secrets**
  - [ ] Production API keys rotated recently (<90 days)
  - [ ] Keys stored in Flutter Secure Storage
  - [ ] Keys not logged anywhere
  - [ ] Keys not in version control

- [ ] **Network Security**
  - [ ] All endpoints use HTTPS
  - [ ] SSL/TLS certificate validation enabled
  - [ ] Certificate pinning implemented (recommended)
  - [ ] Request timeouts configured

- [ ] **Input Validation**
  - [ ] All payment requests validated
  - [ ] User input sanitized
  - [ ] SQL injection prevention
  - [ ] XSS prevention

- [ ] **Error Handling**
  - [ ] Sensitive data not exposed in errors
  - [ ] Error reporting configured (Sentry)
  - [ ] Error sanitization enabled
  - [ ] Stack traces limited in production

- [ ] **Logging & Monitoring**
  - [ ] Production log level set (warning/error only)
  - [ ] No sensitive data in logs
  - [ ] Monitoring service configured
  - [ ] Alert rules enabled

- [ ] **Code Security**
  - [ ] Dependency audit completed (`flutter pub outdated`)
  - [ ] Known vulnerabilities patched
  - [ ] Code obfuscation enabled
  - [ ] Debug code removed

- [ ] **Data Protection**
  - [ ] Offline queue encrypted
  - [ ] Secure storage for credentials
  - [ ] PII handling compliant with regulations
  - [ ] Data retention policies enforced

- [ ] **Testing**
  - [ ] Security penetration test completed
  - [ ] Load testing passed
  - [ ] All unit tests passing
  - [ ] Integration tests passing

### 🔐 Production Build Configuration

```bash
# Build with obfuscation and split debug info
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols
flutter build web --release --pwa-strategy=offline-first

# Upload symbols to Sentry for crash reporting
sentry-cli upload-dif --include-sources build/app/outputs/symbols
```

### 📊 Post-Deployment Monitoring

1. **Monitor Error Rates**: Check Sentry for spikes
2. **Track Performance**: Response times, failover rates
3. **Watch Alerts**: Configure PagerDuty/Slack alerts
4. **Review Logs**: Check for suspicious activity
5. **Audit Access**: Review API key usage monthly

---

## Security Contacts

- **Security Issues**: security@yourdomain.com
- **Bug Bounty Program**: https://bugcrowd.com/yourcompany
- **Incident Response**: +1-XXX-XXX-XXXX (24/7)

---

## Compliance

- ✅ **PCI DSS**: Level 1 Service Provider certified
- ✅ **GDPR**: EU data protection compliant
- ✅ **SOC 2 Type II**: Annual audit completed
- ✅ **ISO 27001**: Information security certified

---

**Last Updated**: November 12, 2025  
**Security Team**: security@apisentinel.com  
**Emergency Contact**: +1-800-SENTINEL

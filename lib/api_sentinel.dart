/// API Sentinel Flutter SDK
///
/// Automatic payment failover recovery for B2B FinTech applications.
///
/// This SDK provides intelligent payment gateway failover, automatically
/// switching to a backup gateway when the primary fails, ensuring maximum
/// payment success rates and revenue recovery.
///
/// ## Getting Started
///
/// 1. Get your API key from the API Sentinel dashboard
/// 2. Initialize the SDK in your app:
///
/// ```dart
/// import 'package:apisentinei/api_sentinel.dart';
///
/// final sentinel = APISentinel(
///   baseUrl: 'https://api.apisentinel.com',
///   apiKey: 'your-api-key-here',
///   primaryGateway: 'stripe',
///   secondaryGateway: 'paypal',
///   customerId: 'your-company-id',
/// );
///
/// await sentinel.init();
/// ```
///
/// 3. Use it for payment operations:
///
/// ```dart
/// final response = await sentinel.postWithFailover(
///   endpoint: '/process-payment',
///   data: {
///     'amount': 100.0,
///     'currency': 'USD',
///     'paymentMethod': 'pm_card_visa',
///   },
/// );
///
/// if (response.success) {
///   print('Payment successful!');
///   if (response.failoverUsed) {
///     print('Recovered via failover in ${response.recoveryTimeMs}ms');
///   }
/// }
/// ```
///
/// ## Features
///
/// - ✅ Automatic failover to secondary gateway
/// - ✅ Real-time analytics and tracking
/// - ✅ Secure API key storage
/// - ✅ Optional UI components
/// - ✅ Comprehensive error handling
/// - ✅ Recovery time metrics
///
/// For more information, visit: https://apisentinel.com/docs
library;

// Core functionality
export 'src/sentinel_core.dart';
export 'src/sentinel_config.dart';

// Models
export 'src/models/failover_event.dart';
export 'src/models/sentinel_response.dart';

// UI Components (optional)
export 'src/ui/loading_overlay.dart';

// Production features
export 'src/exceptions.dart';
export 'src/environment_config.dart';
export 'src/retry_policy.dart';
export 'src/validators.dart';
export 'src/rate_limiter.dart';
export 'src/offline_queue.dart';
export 'src/sentry_service.dart';
export 'src/config_loader.dart';
export 'src/gateway_endpoints.dart';
export 'src/monitoring_service.dart';

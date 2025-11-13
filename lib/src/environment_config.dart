library;

/// Environment configuration for API Sentinel
///
/// Manages environment-specific settings for development, staging, and production

enum Environment { development, staging, production }

class EnvironmentConfig {
  final Environment environment;
  final String baseUrl;
  final String apiKey;
  final bool enableDebugLogging;
  final bool enableAnalytics;
  final int requestTimeoutSeconds;
  final int maxRetryAttempts;
  final bool enableOfflineMode;

  const EnvironmentConfig({
    required this.environment,
    required this.baseUrl,
    required this.apiKey,
    this.enableDebugLogging = false,
    this.enableAnalytics = true,
    this.requestTimeoutSeconds = 30,
    this.maxRetryAttempts = 3,
    this.enableOfflineMode = true,
  });

  /// Development configuration
  static EnvironmentConfig development({String? apiKey}) {
    return EnvironmentConfig(
      environment: Environment.development,
      baseUrl: 'http://localhost:8080',
      apiKey: apiKey ?? 'dev_test_key',
      enableDebugLogging: true,
      enableAnalytics: false,
      enableOfflineMode: true,
    );
  }

  /// Staging configuration
  static EnvironmentConfig staging({required String apiKey}) {
    return EnvironmentConfig(
      environment: Environment.staging,
      baseUrl: 'https://api-staging.apisentinel.com',
      apiKey: apiKey,
      enableDebugLogging: true,
      enableAnalytics: true,
      enableOfflineMode: true,
    );
  }

  /// Production configuration
  static EnvironmentConfig production({required String apiKey}) {
    return EnvironmentConfig(
      environment: Environment.production,
      baseUrl: 'https://api.apisentinel.com',
      apiKey: apiKey,
      enableDebugLogging: false,
      enableAnalytics: true,
      requestTimeoutSeconds: 30,
      maxRetryAttempts: 3,
      enableOfflineMode: true,
    );
  }

  /// Create custom configuration
  factory EnvironmentConfig.custom({
    required Environment environment,
    required String baseUrl,
    required String apiKey,
    bool? enableDebugLogging,
    bool? enableAnalytics,
    int? requestTimeoutSeconds,
    int? maxRetryAttempts,
    bool? enableOfflineMode,
  }) {
    return EnvironmentConfig(
      environment: environment,
      baseUrl: baseUrl,
      apiKey: apiKey,
      enableDebugLogging: enableDebugLogging ?? false,
      enableAnalytics: enableAnalytics ?? true,
      requestTimeoutSeconds: requestTimeoutSeconds ?? 30,
      maxRetryAttempts: maxRetryAttempts ?? 3,
      enableOfflineMode: enableOfflineMode ?? true,
    );
  }

  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;

  @override
  String toString() {
    return 'EnvironmentConfig(environment: $environment, baseUrl: $baseUrl)';
  }
}

/// Load environment variables from .env file
///
/// Usage:
/// ```dart
/// final config = await loadEnvironmentConfig();
/// ```
Future<EnvironmentConfig> loadEnvironmentConfig() async {
  // In a real app, you'd use flutter_dotenv or similar
  // For now, we'll use const values

  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  const apiKey = String.fromEnvironment('API_SENTINEL_KEY', defaultValue: '');

  switch (environment.toLowerCase()) {
    case 'production':
      return EnvironmentConfig.production(
        apiKey: apiKey.isNotEmpty
            ? apiKey
            : throw Exception('API_SENTINEL_KEY required for production'),
      );
    case 'staging':
      return EnvironmentConfig.staging(
        apiKey: apiKey.isNotEmpty
            ? apiKey
            : throw Exception('API_SENTINEL_KEY required for staging'),
      );
    default:
      return EnvironmentConfig.development(apiKey: apiKey);
  }
}

library;

/// Configuration loader for environment variables
///
/// Loads configuration from .env file and provides type-safe access

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Configuration loader service
class ConfigLoader {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  /// Initialize configuration by loading .env file
  static Future<void> initialize({String fileName = '.env'}) async {
    if (_isInitialized) {
      _logger.w('ConfigLoader already initialized');
      return;
    }

    try {
      await dotenv.load(fileName: fileName);
      _isInitialized = true;
      _logger.i('Configuration loaded from $fileName');
    } catch (e) {
      _logger.e('Failed to load configuration', error: e);
      throw Exception('Configuration file not found: $fileName');
    }
  }

  /// Get string value from environment
  static String getString(String key, {String defaultValue = ''}) {
    if (!_isInitialized) {
      _logger.w('ConfigLoader not initialized');
      return defaultValue;
    }
    return dotenv.get(key, fallback: defaultValue);
  }

  /// Get integer value from environment
  static int getInt(String key, {int defaultValue = 0}) {
    if (!_isInitialized) return defaultValue;
    final value = dotenv.get(key, fallback: defaultValue.toString());
    return int.tryParse(value) ?? defaultValue;
  }

  /// Get double value from environment
  static double getDouble(String key, {double defaultValue = 0.0}) {
    if (!_isInitialized) return defaultValue;
    final value = dotenv.get(key, fallback: defaultValue.toString());
    return double.tryParse(value) ?? defaultValue;
  }

  /// Get boolean value from environment
  static bool getBool(String key, {bool defaultValue = false}) {
    if (!_isInitialized) return defaultValue;
    final value = dotenv
        .get(key, fallback: defaultValue.toString())
        .toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Get list value from environment (comma-separated)
  static List<String> getList(
    String key, {
    List<String> defaultValue = const [],
  }) {
    if (!_isInitialized) return defaultValue;
    final value = dotenv.get(key, fallback: '');
    if (value.isEmpty) return defaultValue;
    return value.split(',').map((e) => e.trim()).toList();
  }

  /// Check if configuration is initialized
  static bool get isInitialized => _isInitialized;

  /// Get all environment variables
  static Map<String, String> get all {
    if (!_isInitialized) return {};
    return dotenv.env;
  }
}

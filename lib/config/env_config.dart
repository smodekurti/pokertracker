// lib/config/env_config.dart

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  // Private constructor to prevent instantiation
  EnvironmentConfig._();

  // Initialize environment variables
  static Future<void> init() async {
    try {
      await dotenv.load(
        fileName: _getEnvFileName(),
        mergeWith:
            Platform.environment, // Merge with system environment variables
      );

      // Validate required variables
      _validateRequiredVariables();

      if (kDebugMode) {
        print('Environment loaded: ${dotenv.env['ENVIRONMENT']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading environment variables: $e');
      }
      rethrow;
    }
  }

  // Get environment file name based on configuration
  static String _getEnvFileName() {
    // Check for explicit environment override
    const envOverride = String.fromEnvironment('ENVIRONMENT');
    if (envOverride.isNotEmpty) {
      return '.env.$envOverride';
    }

    // Default to development in debug mode, production in release mode
    return kDebugMode ? '.env.development' : '.env.production';
  }

  // Validate required environment variables
  static void _validateRequiredVariables() {
    final requiredVariables = [
      'FIREBASE_API_KEY',
      'FIREBASE_APP_ID',
      'FIREBASE_MESSAGING_SENDER_ID',
      'FIREBASE_PROJECT_ID',
      'FIREBASE_AUTH_DOMAIN',
      'FIREBASE_STORAGE_BUCKET',
    ];

    final missingVariables = requiredVariables
        .where((variable) =>
            !dotenv.env.containsKey(variable) ||
            dotenv.env[variable]?.isEmpty == true)
        .toList();

    if (missingVariables.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingVariables.join(', ')}',
      );
    }
  }

  // Firebase Configuration
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';

  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  static String get firebaseAuthDomain =>
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';

  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

  static String get firebaseMeasurementId =>
      dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Poker Tracker';

  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'info';

  // Game Settings
  static double get defaultBuyIn =>
      double.parse(dotenv.env['DEFAULT_BUY_IN'] ?? '100');

  static String get defaultCurrency => dotenv.env['DEFAULT_CURRENCY'] ?? 'USD';

  static int get minPlayers => int.parse(dotenv.env['MIN_PLAYERS'] ?? '2');

  static int get maxPlayers => int.parse(dotenv.env['MAX_PLAYERS'] ?? '10');

  // Feature Flags
  static bool get enableOfflineMode =>
      dotenv.env['ENABLE_OFFLINE_MODE']?.toLowerCase() == 'true';

  static bool get enablePushNotifications =>
      dotenv.env['ENABLE_PUSH_NOTIFICATIONS']?.toLowerCase() == 'true';

  static bool get enableAnalytics =>
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';

  // Helper Methods
  static bool get isProduction => environment.toLowerCase() == 'production';

  static bool get isDevelopment => environment.toLowerCase() == 'development';

  static bool get isStaging => environment.toLowerCase() == 'staging';

  // Get all environment variables (for debugging)
  static Map<String, String> get allVariables =>
      Map<String, String>.from(dotenv.env);

  // Get specific environment variable safely
  static String? getVariable(String key) => dotenv.env[key];

  // Check if environment variable exists
  static bool hasVariable(String key) =>
      dotenv.env.containsKey(key) && dotenv.env[key]?.isNotEmpty == true;
}

// Extension for additional environment functionality
extension EnvironmentConfigExtension on EnvironmentConfig {
  // Check if running in debug mode
  static bool get isDebugMode => kDebugMode;

  // Get environment-specific API URL
  static String get apiUrl {
    switch (EnvironmentConfig.environment) {
      case 'production':
        return 'https://api.pokertracker.com';
      case 'staging':
        return 'https://staging-api.pokertracker.com';
      default:
        return 'https://dev-api.pokertracker.com';
    }
  }

  // Get environment-specific logging configuration
  static bool get enableDetailedLogs =>
      !EnvironmentConfig.isProduction || EnvironmentConfig.logLevel == 'debug';
}

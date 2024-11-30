// lib/core/constants/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Poker Tracker';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Route names
  static const String routeHome = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeGameSetup = '/game-setup';
  static const String routeActiveGame = '/game/:id';
  static const String routeGameHistory = '/history';
  static const String routeSettings = '/settings';
  static const String routeProfile = '/profile';
  static const String routePrivacyPolicy = '/privacy';
  static const String routeTerms = '/terms';

  // Firebase collections
  static const String colUsers = 'users';
  static const String colGames = 'games';
  static const String colSettings = 'settings';
  static const String colTransactions = 'transactions';
  static const String colPlayers = 'players';

  // Firestore document IDs
  static const String docAppSettings = 'app_settings';
  static const String docUserProfile = 'profile';

  // Shared preferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefIsDarkMode = 'is_dark_mode';
  static const String prefUseSystemTheme = 'use_system_theme';
  static const String prefDefaultBuyIn = 'default_buy_in';
  static const String prefCurrency = 'currency';
  static const String prefNotifications = 'notifications_enabled';
  static const String prefLastSync = 'last_sync';
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';

  // Validation constants
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 100;
  static const double minBuyInAmount = 1;
  static const double maxBuyInAmount = 10000;
  static const int maxPlayersPerGame = 20;
  static const int minPlayersPerGame = 2;

  // Default values
  static const double defaultBuyInAmount = 100.0;
  static const String defaultCurrency = 'USD';
  static const bool defaultNotificationSetting = true;
  static const bool defaultSystemTheme = true;
  static const bool defaultDarkMode = false;

  // Supported currencies
  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'INR',
    'AUD',
    'CAD',
  ];

  // Error messages
  static const String errorInvalidEmail = 'Please enter a valid email address';
  static const String errorWeakPassword =
      'Password must be at least $minPasswordLength characters';
  static const String errorNameRequired = 'Name is required';
  static const String errorNameTooLong =
      'Name cannot exceed $maxNameLength characters';
  static const String errorInvalidBuyIn =
      'Buy-in must be between \$$minBuyInAmount and \$$maxBuyInAmount';
  static const String errorInvalidPlayerCount =
      'Game must have between $minPlayersPerGame and $maxPlayersPerGame players';

  // Cache durations
  static const Duration cacheDuration = Duration(minutes: 15);
  static const Duration syncInterval = Duration(hours: 1);
  static const Duration sessionTimeout = Duration(hours: 24);

  // API timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;
  static const double defaultIconSize = 24.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}

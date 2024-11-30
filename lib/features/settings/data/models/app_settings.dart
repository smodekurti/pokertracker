// lib/features/settings/data/models/app_settings.dart

class AppSettings {
  final bool isDarkMode;
  final bool useSystemTheme;
  final double defaultBuyIn;
  final String currency;
  final bool enableNotifications;
  final DateTime? lastUpdated; // Add this field

  AppSettings({
    this.isDarkMode = false,
    this.useSystemTheme = true,
    this.defaultBuyIn = 100.0,
    this.currency = 'USD',
    this.enableNotifications = true,
    this.lastUpdated, // Add this
  });

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'useSystemTheme': useSystemTheme,
      'defaultBuyIn': defaultBuyIn,
      'currency': currency,
      'enableNotifications': enableNotifications,
      'lastUpdated': lastUpdated?.toIso8601String(), // Add this
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      useSystemTheme: map['useSystemTheme'] ?? true,
      defaultBuyIn: (map['defaultBuyIn'] ?? 100.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      enableNotifications: map['enableNotifications'] ?? true,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : null, // Add this
    );
  }

  AppSettings copyWith({
    bool? isDarkMode,
    bool? useSystemTheme,
    double? defaultBuyIn,
    String? currency,
    bool? enableNotifications,
    DateTime? lastUpdated, // Add this
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      defaultBuyIn: defaultBuyIn ?? this.defaultBuyIn,
      currency: currency ?? this.currency,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      lastUpdated: lastUpdated ?? this.lastUpdated, // Add this
    );
  }

  @override
  String toString() {
    return 'AppSettings('
        'isDarkMode: $isDarkMode, '
        'useSystemTheme: $useSystemTheme, '
        'defaultBuyIn: $defaultBuyIn, '
        'currency: $currency, '
        'enableNotifications: $enableNotifications, '
        'lastUpdated: $lastUpdated)'; // Add this
  }
}

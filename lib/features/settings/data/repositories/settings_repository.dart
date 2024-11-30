import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_tracker/core/constants/app_constants.dart';
import 'package:poker_tracker/features/settings/data/models/app_settings.dart';
import 'dart:async';

class SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  AppSettings? _cachedSettings;
  final _isDarkModeController = StreamController<bool>.broadcast();

  SettingsRepository({required this.userId}) {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
  }

  // Get settings document reference
  DocumentReference get _settingsDoc => _firestore
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colSettings)
      .doc('app_settings');

  // Stream for theme changes
  Stream<bool> get isDarkModeStream => _isDarkModeController.stream;

  // Load settings
  Future<AppSettings> loadSettings() async {
    try {
      // Return cached settings if available
      if (_cachedSettings != null) {
        return _cachedSettings!;
      }

      // Try to load from Firestore first
      final doc = await _settingsDoc.get();
      if (doc.exists) {
        _cachedSettings =
            AppSettings.fromMap(doc.data() as Map<String, dynamic>);
        return _cachedSettings!;
      }

      // If no Firestore data, try local preferences
      final prefs = await SharedPreferences.getInstance();
      final defaultBuyIn = prefs.getDouble(AppConstants.prefDefaultBuyIn);
      final isDarkMode = prefs.getBool(AppConstants.prefIsDarkMode) ?? false;
      final useSystemTheme =
          prefs.getBool(AppConstants.prefUseSystemTheme) ?? true;
      final currency = prefs.getString(AppConstants.prefCurrency) ?? 'USD';

      // Create default settings if none exist
      final defaultSettings = AppSettings(
        defaultBuyIn: defaultBuyIn ?? 100.0,
        isDarkMode: isDarkMode,
        useSystemTheme: useSystemTheme,
        currency: currency,
        enableNotifications: false,
        lastUpdated: DateTime.now(),
      );

      // Save default settings to Firestore
      await saveSettings(defaultSettings);
      _cachedSettings = defaultSettings;
      return defaultSettings;
    } catch (e) {
      print('Error loading settings: $e');
      // Return default settings if anything fails
      return AppSettings();
    }
  }

  // Save settings
  Future<void> saveSettings(AppSettings settings) async {
    try {
      // Update lastUpdated timestamp
      final updatedSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
      );

      // Save to Firestore
      await _settingsDoc.set(updatedSettings.toMap());

      // Update cache
      _cachedSettings = updatedSettings;

      // Save critical settings locally
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setDouble(AppConstants.prefDefaultBuyIn, settings.defaultBuyIn),
        prefs.setBool(AppConstants.prefIsDarkMode, settings.isDarkMode),
        prefs.setBool(AppConstants.prefUseSystemTheme, settings.useSystemTheme),
        prefs.setString(AppConstants.prefCurrency, settings.currency),
      ]);

      // Notify theme listeners if theme changed
      _isDarkModeController.add(settings.isDarkMode);
    } catch (e) {
      print('Error saving settings: $e');
      throw Exception('Failed to save settings: $e');
    }
  }

  // Update theme mode
  Future<void> updateThemeMode(bool isDark, bool useSystem) async {
    try {
      final settings = await loadSettings();
      await saveSettings(settings.copyWith(
        isDarkMode: isDark,
        useSystemTheme: useSystem,
      ));
    } catch (e) {
      print('Error updating theme mode: $e');
      throw Exception('Failed to update theme mode: $e');
    }
  }

  // Update default buy-in
  Future<void> updateDefaultBuyIn(double amount) async {
    if (amount <= 0) {
      throw ArgumentError('Buy-in amount must be greater than 0');
    }

    try {
      final settings = await loadSettings();
      await saveSettings(settings.copyWith(defaultBuyIn: amount));
    } catch (e) {
      print('Error updating default buy-in: $e');
      throw Exception('Failed to update default buy-in: $e');
    }
  }

  // Update notifications
  Future<void> updateNotifications(bool enabled) async {
    try {
      final settings = await loadSettings();
      await saveSettings(settings.copyWith(enableNotifications: enabled));
    } catch (e) {
      print('Error updating notifications: $e');
      throw Exception('Failed to update notifications: $e');
    }
  }

  // Update currency
  Future<void> updateCurrency(String currency) async {
    if (currency.isEmpty) {
      throw ArgumentError('Currency cannot be empty');
    }

    try {
      final settings = await loadSettings();
      await saveSettings(settings.copyWith(currency: currency));
    } catch (e) {
      print('Error updating currency: $e');
      throw Exception('Failed to update currency: $e');
    }
  }

  // Reset settings to default
  Future<void> resetSettings() async {
    try {
      final defaultSettings = AppSettings();
      await saveSettings(defaultSettings);

      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error resetting settings: $e');
      throw Exception('Failed to reset settings: $e');
    }
  }

  // Delete user settings
  Future<void> deleteSettings() async {
    try {
      await _settingsDoc.delete();
      _cachedSettings = null;

      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error deleting settings: $e');
      throw Exception('Failed to delete settings: $e');
    }
  }

  // Clear cache
  void clearCache() {
    _cachedSettings = null;
  }

  // Dispose
  void dispose() {
    _isDarkModeController.close();
  }
}

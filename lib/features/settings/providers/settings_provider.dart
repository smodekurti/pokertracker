import 'package:flutter/material.dart';
import 'package:poker_tracker/features/settings/data/models/app_settings.dart';
import 'package:poker_tracker/features/settings/data/repositories/settings_repository.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsRepository _repository;
  AppSettings? _settings;
  bool _isLoading = false;
  String? _error;

  SettingsProvider(String userId)
      : _repository = SettingsRepository(userId: userId) {
    _loadSettings();
  }

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add stream for theme changes
  Stream<bool> get isDarkMode => _repository.isDarkModeStream;

  Future<void> _loadSettings() async {
    try {
      _setLoading(true);
      _clearError();
      _settings = await _repository.loadSettings();
    } catch (e) {
      _setError('Failed to load settings: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateThemeMode(bool isDark, bool useSystem) async {
    try {
      _setLoading(true);
      _clearError();

      await _repository.updateThemeMode(isDark, useSystem);
      await _loadSettings();
    } catch (e) {
      _setError('Failed to update theme: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDefaultBuyIn(double amount) async {
    if (amount <= 0) {
      _setError('Buy-in amount must be greater than 0');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      await _repository.updateDefaultBuyIn(amount);
      await _loadSettings();
    } catch (e) {
      _setError('Failed to update buy-in amount: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateNotifications(bool enabled) async {
    try {
      _setLoading(true);
      _clearError();

      await _repository.updateNotifications(enabled);
      await _loadSettings();
    } catch (e) {
      _setError('Failed to update notifications: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCurrency(String currency) async {
    if (currency.isEmpty) {
      _setError('Currency cannot be empty');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      await _repository.updateCurrency(currency);
      await _loadSettings();
    } catch (e) {
      _setError('Failed to update currency: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Reset settings to default
  Future<void> resetSettings() async {
    try {
      _setLoading(true);
      _clearError();

      await _repository.resetSettings();
      await _loadSettings();
    } catch (e) {
      _setError('Failed to reset settings: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Handle user deletion
  Future<void> deleteUserSettings() async {
    try {
      _setLoading(true);
      _clearError();

      await _repository.deleteSettings();
      _settings = null;
    } catch (e) {
      _setError('Failed to delete settings: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods for state management
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh settings
  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}

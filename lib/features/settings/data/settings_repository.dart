import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _themeKey = 'theme_mode';
  static const String _privacyKey = 'privacy_mode';
  static const String _currencyKey = 'currency_symbol';
  static const String _notificationLogKey = 'pref_notification_logging_enabled';
  static const String _apiLogKey = 'pref_api_logging_enabled';

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex == null) return ThemeMode.system;
    return ThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<bool> getPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyKey) ?? false;
  }

  Future<void> setPrivacyMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, enabled);
  }

  Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? '\$';
  }

  Future<void> setCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
  }

  Future<bool> getNotificationLogEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationLogKey) ?? true;
  }

  Future<void> setNotificationLogEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationLogKey, enabled);
  }

  Future<bool> getApiLogEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_apiLogKey) ?? true;
  }

  Future<void> setApiLogEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_apiLogKey, enabled);
  }
}

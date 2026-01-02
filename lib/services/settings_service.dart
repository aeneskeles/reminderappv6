import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._init();
  
  SettingsService._init();

  // Keys
  static const String _keyDefaultSnoozeMinutes = 'default_snooze_minutes';
  static const String _keyDefaultNotificationMinutes = 'default_notification_minutes';
  static const String _keyNotificationSound = 'notification_sound';
  static const String _keyNotificationVibration = 'notification_vibration';
  static const String _keyThemeMode = 'theme_mode'; // 'light', 'dark', 'system'
  static const String _keyDefaultTab = 'default_tab'; // 0: Bugün, 1: Yaklaşanlar, 2: Tümü, 3: Tamamlananlar
  static const String _keyLanguage = 'language'; // 'tr', 'en'

  // Default values
  static const int defaultSnoozeMinutes = 10;
  static const int defaultNotificationMinutes = 15;
  static const bool defaultNotificationSound = true;
  static const bool defaultNotificationVibration = true;
  static const String defaultThemeMode = 'system';
  static const int defaultDefaultTab = 0;
  static const String defaultLanguage = 'tr';

  // Get SharedPreferences instance
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Notification Settings
  Future<int> getDefaultSnoozeMinutes() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyDefaultSnoozeMinutes) ?? defaultSnoozeMinutes;
  }

  Future<void> setDefaultSnoozeMinutes(int minutes) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyDefaultSnoozeMinutes, minutes);
  }

  Future<int> getDefaultNotificationMinutes() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyDefaultNotificationMinutes) ?? defaultNotificationMinutes;
  }

  Future<void> setDefaultNotificationMinutes(int minutes) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyDefaultNotificationMinutes, minutes);
  }

  Future<bool> getNotificationSound() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyNotificationSound) ?? defaultNotificationSound;
  }

  Future<void> setNotificationSound(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyNotificationSound, enabled);
  }

  Future<bool> getNotificationVibration() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyNotificationVibration) ?? defaultNotificationVibration;
  }

  Future<void> setNotificationVibration(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyNotificationVibration, enabled);
  }

  // Theme Settings
  Future<String> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyThemeMode) ?? defaultThemeMode;
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyThemeMode, mode);
  }

  // Default Tab
  Future<int> getDefaultTab() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyDefaultTab) ?? defaultDefaultTab;
  }

  Future<void> setDefaultTab(int tabIndex) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyDefaultTab, tabIndex);
  }

  // Language
  Future<String> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLanguage) ?? defaultLanguage;
  }

  Future<void> setLanguage(String language) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLanguage, language);
  }

  // Reset all settings
  Future<void> resetAllSettings() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  // Get all settings as map
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'defaultSnoozeMinutes': await getDefaultSnoozeMinutes(),
      'defaultNotificationMinutes': await getDefaultNotificationMinutes(),
      'notificationSound': await getNotificationSound(),
      'notificationVibration': await getNotificationVibration(),
      'themeMode': await getThemeMode(),
      'defaultTab': await getDefaultTab(),
      'language': await getLanguage(),
    };
  }
}


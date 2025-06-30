import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Keys for preferences
  static const String _backgroundEnabledKey = 'background_enabled';
  static const String _backgroundIntervalKey = 'background_interval';
  static const String _showBackgroundFeedbackKey = 'show_background_feedback';
  static const String _lastBackgroundTestKey = 'last_background_test';

  // Default values
  static const bool _defaultBackgroundEnabled = false;
  static const int _defaultBackgroundInterval = 15; // 15 minutes (enforcing Android's minimum)
  static const bool _defaultShowBackgroundFeedback = false;
  
  // Minimum interval enforced by Android WorkManager
  static const int _minimumBackgroundInterval = 15; // 15 minutes

  // Get whether background monitoring is enabled
  static Future<bool> isBackgroundMonitoringEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backgroundEnabledKey) ?? _defaultBackgroundEnabled;
  }

  // Set background monitoring enabled/disabled
  static Future<void> setBackgroundMonitoringEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundEnabledKey, enabled);
  }

  // Get background monitoring interval in minutes
  static Future<int> getBackgroundMonitoringInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final interval = prefs.getInt(_backgroundIntervalKey) ?? _defaultBackgroundInterval;
    
    // Enforce minimum interval required by Android WorkManager
    return interval < _minimumBackgroundInterval ? _minimumBackgroundInterval : interval;
  }

  // Set background monitoring interval in minutes
  static Future<void> setBackgroundMonitoringInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Enforce minimum interval required by Android WorkManager
    final enforcedMinutes = minutes < _minimumBackgroundInterval ? _minimumBackgroundInterval : minutes;
    await prefs.setInt(_backgroundIntervalKey, enforcedMinutes);
  }

  // Get whether to show feedback after background tests
  static Future<bool> shouldShowBackgroundFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showBackgroundFeedbackKey) ?? _defaultShowBackgroundFeedback;
  }

  // Set whether to show feedback after background tests
  static Future<void> setShowBackgroundFeedback(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showBackgroundFeedbackKey, show);
  }

  // Record the timestamp of the last background test
  static Future<void> setLastBackgroundTestTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackgroundTestKey, time.toIso8601String());
  }

  // Get the timestamp of the last background test
  static Future<DateTime?> getLastBackgroundTestTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastBackgroundTestKey);
    if (timeStr == null) return null;
    
    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      return null;
    }
  }
}

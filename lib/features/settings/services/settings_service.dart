import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import '../../../core/services/notification_service.dart';

class SettingsService {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _themeModeKey = 'theme_mode';

  Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsModel(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      themeMode: prefs.getString(_themeModeKey) ?? 'system',
    );
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, settings.notificationsEnabled);
    await prefs.setString(_themeModeKey, settings.themeMode);
    
    // Update notifications
    await NotificationService.toggleNotifications(settings.notificationsEnabled);
  }

  Future<void> updateNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    await NotificationService.toggleNotifications(enabled);
  }

  Future<void> updateThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode);
  }
} 
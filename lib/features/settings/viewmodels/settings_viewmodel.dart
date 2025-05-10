import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsService _service = SettingsService();
  late SettingsModel _settings;
  bool _isLoading = false;
  String? _error;

  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SettingsViewModel() {
    _settings = SettingsModel.defaultSettings();
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _service.loadSettings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNotifications(bool enabled) async {
    try {
      await _service.updateNotifications(enabled);
      _settings = _settings.copyWith(notificationsEnabled: enabled);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateThemeMode(String themeMode) async {
    try {
      await _service.updateThemeMode(themeMode);
      _settings = _settings.copyWith(themeMode: themeMode);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
} 
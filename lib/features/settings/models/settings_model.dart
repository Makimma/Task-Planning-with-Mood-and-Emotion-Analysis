  class SettingsModel {
  final bool notificationsEnabled;
  final String themeMode;

  SettingsModel({
    required this.notificationsEnabled,
    required this.themeMode,
  });

  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      notificationsEnabled: true,
      themeMode: 'system',
    );
  }

  SettingsModel copyWith({
    bool? notificationsEnabled,
    String? themeMode,
  }) {
    return SettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
} 
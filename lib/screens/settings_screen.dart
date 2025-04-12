import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/notification_service.dart';
import 'auth_screen.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  String _selectedTheme = 'system'; // default

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme_mode') ?? 'system';
    });
  }

  Future<void> _changeTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', value);
    setState(() {
      _selectedTheme = value;
    });

    // применяем в main.dart через глобальный доступ
    final mode = {
      'light': ThemeMode.light,
      'dark': ThemeMode.dark,
      'system': ThemeMode.system,
    }[value]!;

    MyApp.of(context).setThemeMode(mode);
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    await NotificationService.toggleNotifications(value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Настройки")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text("Уведомления о задачах"),
              subtitle: Text(_notificationsEnabled
                  ? "Включены"
                  : "Отключены — уведомления не будут приходить"),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Тема приложения"),
                DropdownButton<String>(
                  value: _selectedTheme,
                  items: [
                    DropdownMenuItem(value: 'system', child: Text("Системная")),
                    DropdownMenuItem(value: 'light', child: Text("Светлая")),
                    DropdownMenuItem(value: 'dark', child: Text("Тёмная")),
                  ],
                  onChanged: (value) {
                    if (value != null) _changeTheme(value);
                  },
                ),
              ],
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Выйти из аккаунта", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

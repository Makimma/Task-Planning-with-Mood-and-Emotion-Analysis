import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/screens/auth_screen.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
    _selectedTheme = _getCurrentThemeMode();
  }

  String _getCurrentThemeMode() {
    final mode = MyApp.of(context).themeMode;
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  Future<void> _changeTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', value);
    setState(() {
      _selectedTheme = value;
    });

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
    // Immediately update UI for better responsiveness
    setState(() {
      _notificationsEnabled = value;
    });
    
    // Save settings in background
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('notifications_enabled', value);
    });
    
    // Toggle notifications in background
    NotificationService.toggleNotifications(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Настройки",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            _buildSettingsSection(
              title: "Основные настройки",
              children: [
                _buildSettingsCard(
                  icon: Icons.notifications,
                  title: "Уведомления о задачах",
                  subtitle: _notificationsEnabled
                      ? "Включены"
                      : "Отключены — уведомления не будут приходить",
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 12),
                _buildSettingsCard(
                  icon: Icons.palette,
                  title: "Тема приложения",
                  subtitle: {
                    'system': 'Системная',
                    'light': 'Светлая',
                    'dark': 'Тёмная',
                  }[_selectedTheme] ?? 'Системная',
                  trailing: DropdownButton<String>(
                    value: _selectedTheme,
                    underline: SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'system', child: Text("Системная")),
                      DropdownMenuItem(value: 'light', child: Text("Светлая")),
                      DropdownMenuItem(value: 'dark', child: Text("Тёмная")),
                    ],
                    onChanged: (value) {
                      if (value != null) _changeTheme(value);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildSettingsSection(
              title: "Аккаунт",
              children: [
                _buildSettingsCard(
                  icon: Icons.account_circle,
                  title: "Выйти из аккаунта",
                  subtitle: "Все данные будут сохранены",
                  onTap: () async {
                    await _authService.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AuthScreen()),
                    );
                  },
                  trailing: Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 16),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

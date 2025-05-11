import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../auth/screens/auth_screen.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: _SettingsScreenContent(),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
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
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${viewModel.error}'),
                  ElevatedButton(
                    onPressed: () => viewModel.loadSettings(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            _buildSettingsSection(
                  context,
              title: "Основные настройки",
              children: [
                _buildSettingsCard(
                      context,
                  icon: Icons.notifications,
                  title: "Уведомления о задачах",
                      subtitle: viewModel.settings.notificationsEnabled
                      ? "Включены"
                      : "Отключены — уведомления не будут приходить",
                  trailing: Switch(
                        value: viewModel.settings.notificationsEnabled,
                        onChanged: viewModel.updateNotifications,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 12),
                _buildSettingsCard(
                      context,
                  icon: Icons.palette,
                  title: "Тема приложения",
                  subtitle: {
                    'system': 'Системная',
                    'light': 'Светлая',
                    'dark': 'Тёмная',
                      }[viewModel.settings.themeMode] ?? 'Системная',
                  trailing: DropdownButton<String>(
                        value: viewModel.settings.themeMode,
                    underline: SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'system', child: Text("Системная")),
                      DropdownMenuItem(value: 'light', child: Text("Светлая")),
                      DropdownMenuItem(value: 'dark', child: Text("Тёмная")),
                    ],
                    onChanged: (value) {
                          if (value != null) {
                            viewModel.updateThemeMode(value);
                            final mode = {
                              'light': ThemeMode.light,
                              'dark': ThemeMode.dark,
                              'system': ThemeMode.system,
                            }[value]!;
                            MyApp.of(context).setThemeMode(mode);
                          }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildSettingsSection(
                  context,
              title: "Аккаунт",
              children: [
                _buildSettingsCard(
                      context,
                  icon: Icons.account_circle,
                  title: "Выйти из аккаунта",
                  subtitle: "Все данные будут сохранены",
                  onTap: () async {
                    final viewModel = context.read<AuthViewModel>();
                    await viewModel.logout(context);
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
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
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

  Widget _buildSettingsCard(
    BuildContext context, {
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

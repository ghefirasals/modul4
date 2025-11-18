import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/theme_service.dart';
import '../../services/auth_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              Obx(() => ListTile(
                title: const Text('Theme Mode'),
                subtitle: Text(_getThemeText(themeService.themeMode)),
                leading: Icon(
                  themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showThemeDialog,
              )),
              const Divider(),
              Obx(() => SwitchListTile(
                title: const Text('Use Material 3'),
                subtitle: const Text('Use the latest Material Design'),
                secondary: const Icon(Icons.palette),
                value: themeService.useMaterial3,
                onChanged: (value) => themeService.toggleMaterial3(),
              )),
            ],
          ),

          _buildSection(
            title: 'Account',
            children: [
              Obx(() {
                final user = Get.find<AuthService>().currentUser;
                return ListTile(
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'Not logged in'),
                  leading: const Icon(Icons.email),
                );
              }),
              const Divider(),
              ListTile(
                title: const Text('Logout'),
                leading: const Icon(Icons.logout),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showLogoutDialog,
              ),
            ],
          ),

          _buildSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                leading: const Icon(Icons.info),
              ),
              const Divider(),
              ListTile(
                title: const Text('About This App'),
                subtitle: const Text('Personal productivity app with todo and notes'),
                leading: const Icon(Icons.description),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Get.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Get.theme.colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog() {
    final themeService = Get.find<ThemeService>();

    Get.dialog(
      AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeService.changeThemeMode(value);
                  Get.back();
                }
              },
            )),
            Obx(() => RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeService.changeThemeMode(value);
                  Get.back();
                }
              },
            )),
            Obx(() => RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follow system theme'),
              value: ThemeMode.system,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeService.changeThemeMode(value);
                  Get.back();
                }
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<AuthService>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/providers/settings_provider.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showLanguageDialog(String currentLang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Select Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'French', 'Spanish'].map((lang) {
            return ListTile(
              title: Text(lang, style: const TextStyle(color: Colors.white70)),
              leading: Radio<String>(
                value: lang,
                groupValue: currentLang,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).setLanguage(val!);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).setLanguage(lang);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Night Mode', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            {'label': 'System', 'value': ThemeMode.system},
            {'label': 'On', 'value': ThemeMode.dark},
            {'label': 'Off', 'value': ThemeMode.light},
          ].map((item) {
            final mode = item['value'] as ThemeMode;
            final label = item['label'] as String;
            return ListTile(
              title: Text(label, style: const TextStyle(color: Colors.white70)),
              leading: Radio<ThemeMode>(
                value: mode,
                groupValue: currentMode,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).setThemeMode(val!);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).setThemeMode(mode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. To confirm, type "DELETE" below.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                ),
                onChanged: (val) {
                  setState(() {
                    canDelete = val == 'DELETE';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: canDelete
                  ? () async {
                      Navigator.pop(context);
                      await ref.read(authServiceProvider).signOut();
                      if (mounted) context.go('/login');
                    }
                  : null,
              child: Text('Delete', style: TextStyle(color: canDelete ? Colors.red : Colors.white24)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), 
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Phone number'),
          _buildListTile(
            title: '+23*******155',
            onTap: () {},
          ),
          const Divider(height: 1, color: Colors.white10),
          
          _buildListTile(
            title: 'In-app calls',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
            onTap: () {},
          ),
          
          _buildSectionHeader('Language'),
          _buildListTile(
            title: 'Default language',
            subtitle: settings.language,
            onTap: () => _showLanguageDialog(settings.language),
          ),
          
          _buildListTile(
            title: 'Distances',
            trailing: const Text('Kilometers', style: TextStyle(color: Colors.white54)),
            onTap: () {},
          ),
          
          _buildSectionHeader('Night mode'),
          _buildListTile(
            title: 'System',
            subtitle: _getThemeLabel(settings.themeMode),
            onTap: () => _showThemeDialog(settings.themeMode),
          ),
          
          _buildListTile(
            title: 'Navigation',
            onTap: () {},
          ),
          
          _buildListTile(
            title: 'Rules and terms',
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          _buildListTile(
            title: 'Log out',
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (mounted) context.go('/login');
            },
          ),
          
          _buildListTile(
            title: 'Delete account',
            textColor: Colors.red,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System';
      case ThemeMode.dark: return 'On';
      case ThemeMode.light: return 'Off';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white70,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

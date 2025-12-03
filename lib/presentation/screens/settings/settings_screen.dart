import 'package:fast_delivery/core/providers/providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu), // Menu icon as per reference, or Back? Reference has Menu icon but it's a sub-screen. Usually back. Let's stick to Back for UX, or Menu if it opens drawer. Reference shows Menu icon.
          onPressed: () => context.pop(), 
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Phone number'),
          _buildListTile(
            title: '+23*******155', // Mocked as per reference
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
            subtitle: 'English',
            onTap: () {},
          ),
          
          _buildListTile(
            title: 'Distances',
            onTap: () {},
          ),
          
          _buildSectionHeader('Night mode'),
          _buildListTile(
            title: 'System',
            onTap: () {},
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
              if (context.mounted) context.go('/login');
            },
          ),
          
          _buildListTile(
            title: 'Delete account',
            textColor: Colors.red,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white, // Using white for dark theme
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

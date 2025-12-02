import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(
              'User Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              '+234 800 000 0000',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            
            // Stats
            Row(
              children: [
                Expanded(child: _buildStatCard('Rides', '12')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Rating', '4.8')),
              ],
            ),
            const SizedBox(height: 32),
            
            // Menu Options
            GlassCard(
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: FontAwesomeIcons.car,
                    title: 'Driver Mode',
                    onTap: () => context.push('/driver'),
                  ),
                  const Divider(color: Colors.white10),
                  _buildMenuItem(
                    context,
                    icon: FontAwesomeIcons.wallet,
                    title: 'Wallet',
                    onTap: () => context.push('/wallet'),
                  ),
                  const Divider(color: Colors.white10),
                  _buildMenuItem(
                    context,
                    icon: FontAwesomeIcons.clockRotateLeft,
                    title: 'History',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10),
                  _buildMenuItem(
                    context,
                    icon: FontAwesomeIcons.gear,
                    title: 'Settings',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10),
                  _buildMenuItem(
                    context,
                    icon: FontAwesomeIcons.rightFromBracket,
                    title: 'Logout',
                    onTap: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}

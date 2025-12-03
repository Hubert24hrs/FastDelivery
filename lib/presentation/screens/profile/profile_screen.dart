
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hubert Idoko',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // Update Account Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9), // Light green
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50), // Green
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Let's update your account",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Improve your app experience',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '2 new suggestions',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(),

            const SizedBox(height: 24),

            // Settings List
            _buildSettingsItem(Icons.person_outline, 'Personal info'),
            _buildSettingsItem(Icons.favorite_border, 'Family profile'),
            _buildSettingsItem(Icons.shield_outlined, 'Safety'),
            _buildSettingsItem(Icons.lock_outline, 'Login & security'),
            _buildSettingsItem(Icons.handshake_outlined, 'Privacy'), // Using handshake as proxy for privacy hand icon

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Divider(),
            ),

            // Saved Places
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text(
                'Saved places',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 8),

            _buildSettingsItem(Icons.home_outlined, 'Enter home location'),
            _buildSettingsItem(Icons.work_outline, 'Enter work location'),
            _buildSettingsItem(Icons.add, 'Add a place'),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Divider(),
            ),

             // Other settings
             _buildSettingsItem(Icons.language, 'Language', subtitle: 'English - US'),
             _buildSettingsItem(Icons.volume_up_outlined, 'Communication preferences'),
             _buildSettingsItem(Icons.calendar_today_outlined, 'Calendars'),

            const SizedBox(height: 24),

            // Logout & Delete
            _buildSettingsItem(Icons.logout, 'Log out', onTap: () => context.go('/login')),
            _buildSettingsItem(Icons.delete_outline, 'Delete account'),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap ?? () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

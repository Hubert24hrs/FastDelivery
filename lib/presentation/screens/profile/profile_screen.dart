
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController(text: 'Hubert Idoko');
  final _phoneController = TextEditingController(text: '+234 801 234 5678');
  final _emailController = TextEditingController(text: 'hubert@example.com');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
              if (!_isEditing) {
                // Save logic would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile Updated')),
                );
              }
            },
            child: Text(
              _isEditing ? 'Done' : 'Edit',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Image Picker not implemented')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: 'Enter Name',
                        ),
                      ),
                    )
                  else
                    Text(
                      _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // Info Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildInfoField(Icons.phone, 'Phone', _phoneController),
                  const SizedBox(height: 16),
                  _buildInfoField(Icons.email, 'Email', _emailController),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Settings List
            _buildSettingsItem(Icons.shield_outlined, 'Safety'),
            _buildSettingsItem(Icons.lock_outline, 'Login & security'),
            _buildSettingsItem(Icons.handshake_outlined, 'Privacy'),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Divider(),
            ),

            // Saved Places
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved places',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 8),

            _buildSettingsItem(Icons.home_outlined, 'Enter home location'),
            _buildSettingsItem(Icons.work_outline, 'Enter work location'),
            _buildSettingsItem(Icons.add, 'Add a place'),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(IconData icon, String label, TextEditingController controller) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (_isEditing)
                TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    controller.text,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ],
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
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

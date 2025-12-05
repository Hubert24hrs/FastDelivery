
import 'package:fast_delivery/core/models/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeControllers(UserModel user) {
    if (!_isEditing) {
      if (_nameController.text != user.displayName) {
        _nameController.text = user.displayName ?? '';
      }
      if (_phoneController.text != user.phoneNumber) {
        _phoneController.text = user.phoneNumber ?? '';
      }
      if (_emailController.text != user.email) {
        _emailController.text = user.email;
      }
    }
  }

  Future<void> _saveProfile(UserModel currentUser) async {
    try {
      final updatedUser = UserModel(
        id: currentUser.id,
        email: currentUser.email, // Email usually shouldn't change here
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: currentUser.photoUrl,
        role: currentUser.role,
        walletBalance: currentUser.walletBalance,
        homeAddress: currentUser.homeAddress,
        workAddress: currentUser.workAddress,
        createdAt: currentUser.createdAt,
      );

      await ref.read(databaseServiceProvider).updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated')),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _updateAddress(UserModel currentUser, String type, String address) async {
    try {
      final updatedUser = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        displayName: currentUser.displayName,
        phoneNumber: currentUser.phoneNumber,
        photoUrl: currentUser.photoUrl,
        role: currentUser.role,
        walletBalance: currentUser.walletBalance,
        homeAddress: type == 'home' ? address : currentUser.homeAddress,
        workAddress: type == 'work' ? address : currentUser.workAddress,
        createdAt: currentUser.createdAt,
      );

      await ref.read(databaseServiceProvider).updateUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == 'home' ? 'Home' : 'Work'} address updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating address: $e')),
        );
      }
    }
  }

  void _showAddressDialog(UserModel user, String type) {
    final controller = TextEditingController(
      text: type == 'home' ? user.homeAddress : user.workAddress
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter ${type == 'home' ? 'Home' : 'Work'} Location'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g., 123 Main St, Lagos',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateAddress(user, type, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await ref.read(authServiceProvider).signOut();
      // Router will handle redirect to login
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final userAsync = userId != null 
        ? ref.watch(databaseServiceProvider).getUserStream(userId)
        : const Stream<UserModel?>.empty();

    return StreamBuilder<UserModel?>(
      stream: userAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }

        // Initialize controllers with user data if not editing
        _initializeControllers(user);

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
                  if (_isEditing) {
                    _saveProfile(user);
                  } else {
                    setState(() => _isEditing = true);
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
                          user.displayName?.isNotEmpty == true ? user.displayName! : 'No Name',
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
                      _buildInfoField(Icons.phone, 'Phone', _phoneController, enabled: _isEditing),
                      const SizedBox(height: 16),
                      _buildInfoField(Icons.email, 'Email', _emailController, enabled: false), // Email not editable
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

                _buildSettingsItem(
                  Icons.home_outlined, 
                  user.homeAddress?.isNotEmpty == true ? user.homeAddress! : 'Enter home location',
                  subtitle: user.homeAddress?.isNotEmpty == true ? 'Home' : null,
                  onTap: () => _showAddressDialog(user, 'home'),
                ),
                _buildSettingsItem(
                  Icons.work_outline, 
                  user.workAddress?.isNotEmpty == true ? user.workAddress! : 'Enter work location',
                  subtitle: user.workAddress?.isNotEmpty == true ? 'Work' : null,
                  onTap: () => _showAddressDialog(user, 'work'),
                ),
                _buildSettingsItem(Icons.add, 'Add a place'),

                const SizedBox(height: 40),
                
                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Log Out', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildInfoField(IconData icon, String label, TextEditingController controller, {required bool enabled}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (enabled)
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
                    controller.text.isNotEmpty ? controller.text : 'Not set',
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

import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserIdProvider) != null
        ? ref.watch(databaseServiceProvider).getUser(ref.watch(currentUserIdProvider)!)
        : null;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Profile Header
          FutureBuilder(
            future: userAsync,
            builder: (context, snapshot) {
              final name = snapshot.data?.displayName ?? 'Hubert';
              final rating = 4.8; // Mock rating as it's not in UserModel
              
              return Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '$rating (0)',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
              );
            },
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.wallet, 
                  title: 'Payment', 
                  subtitle: 'Manage payment methods & balance',
                  onTap: () {
                    context.pop();
                    context.push('/wallet');
                  },
                ),
                _buildMenuItem(context, icon: FontAwesomeIcons.car, title: 'City', onTap: () => context.pop()),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.clockRotateLeft, 
                  title: 'Request history', 
                  subtitle: 'View your past trips and deliveries',
                  onTap: () {},
                ),
                _buildMenuItem(context, icon: FontAwesomeIcons.box, title: 'Couriers', onTap: () {
                  context.pop();
                  context.push('/courier');
                }),
                
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.bell, 
                  title: 'Notifications', 
                  subtitle: 'Trip updates, promos & alerts',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.shieldHalved, 
                  title: 'Safety', 
                  subtitle: 'Emergency contacts & ride sharing',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.gear, 
                  title: 'Settings', 
                  onTap: () {
                    context.pop();
                    context.push('/settings');
                  }
                ),
                _buildMenuItem(context, icon: FontAwesomeIcons.circleInfo, title: 'Help', onTap: () {}),
              ],
            ),
          ),

          // Driver Mode Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pop();
                      context.push('/driver-selection');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCCFF00), // Neon Lime
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Driver mode',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Earn money driving or delivering',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Social Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(FontAwesomeIcons.facebook),
                    const SizedBox(width: 24),
                    _buildSocialIcon(FontAwesomeIcons.instagram),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 12,
        ),
      ) : null,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue, // Placeholder color, image shows blue/gradient
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

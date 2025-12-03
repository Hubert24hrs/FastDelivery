import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/app_drawer.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:fast_delivery/presentation/screens/home/service_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0E21), Color(0xFF1A1E33)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                      ),
                      
                      // Profile Avatar
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                    ],
                  ).animate().fadeIn().slideX(),

                  const Spacer(),

                  // Recent Activity / Stats (Glass Card)
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 10),
                          const ListTile(
                            leading: Icon(Icons.history, color: Colors.white70),
                            title: Text('Ride to Downtown'),
                            subtitle: Text('Yesterday, 2:30 PM'),
                            trailing: Text('₦1,250'),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 24),

                  // Service Selector (Bottom Sheet style)
                  ServiceSelector(
                    selectedService: 'Ride', // Default
                    onServiceSelected: (service) {
                      if (service == 'Ride') {
                        context.go('/map');
                      } else if (service == 'Couriers') {
                        context.go('/courier');
                      }
                    },
                  ).animate().slideY(begin: 1, duration: 500.ms, curve: Curves.easeOutQuart),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRidesAsync = ref.watch(activeRidesProvider);
    final activeCouriersAsync = ref.watch(activeCouriersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Rides', icon: Icon(FontAwesomeIcons.car)),
                  Tab(text: 'Couriers', icon: Icon(FontAwesomeIcons.box)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Rides Tab
                    activeRidesAsync.when(
                      data: (rides) => rides.isEmpty
                          ? _buildEmptyState('No active ride requests')
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: rides.length,
                              itemBuilder: (context, index) => _buildRideCard(context, ref, rides[index]),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                    
                    // Couriers Tab
                    activeCouriersAsync.when(
                      data: (couriers) => couriers.isEmpty
                          ? _buildEmptyState('No active courier requests')
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: couriers.length,
                              itemBuilder: (context, index) => _buildCourierCard(context, ref, couriers[index]),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, WidgetRef ref, RideModel ride) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ride Request', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor)),
                  Text('₦${ride.price}', style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _buildLocationRow(Icons.my_location, ride.pickupAddress),
              const SizedBox(height: 8),
              _buildLocationRow(Icons.flag, ride.dropoffAddress),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _acceptRide(context, ref, ride),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('ACCEPT RIDE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourierCard(BuildContext context, WidgetRef ref, CourierModel courier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${courier.packageSize} Package', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryColor)),
                  Text('₦${courier.price}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _buildLocationRow(Icons.my_location, courier.pickupAddress),
              const SizedBox(height: 8),
              _buildLocationRow(Icons.flag, courier.dropoffAddress),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _acceptCourier(context, ref, courier),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                  child: const Text('ACCEPT DELIVERY'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Future<void> _acceptRide(BuildContext context, WidgetRef ref, RideModel ride) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await ref.read(databaseServiceProvider).updateRideStatus(ride.id, 'accepted', userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride Accepted!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _acceptCourier(BuildContext context, WidgetRef ref, CourierModel courier) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await ref.read(databaseServiceProvider).updateCourierStatus(courier.id, 'accepted', userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Courier Request Accepted!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Rides'),
            Tab(text: 'Deliveries'),
          ],
        ),
      ),
      body: userId == null
          ? const Center(child: Text('Please login to view history'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRidesList(userId),
                _buildCouriersList(userId),
              ],
            ),
    );
  }

  Widget _buildRidesList(String userId) {
    final ridesStream = ref.watch(databaseServiceProvider).getUserRides(userId);

    return StreamBuilder<List<RideModel>>(
      stream: ridesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return const Center(child: Text('No past rides'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return _buildHistoryCard(
              title: 'Ride to ${ride.dropoffAddress}',
              subtitle: DateFormat('MMM d, y • h:mm a').format(ride.createdAt),
              price: ride.price,
              status: ride.status,
              icon: Icons.directions_car,
              onTap: () => context.push('/history/details', extra: {'ride': ride}),
            );
          },
        );
      },
    );
  }

  Widget _buildCouriersList(String userId) {
    final couriersStream = ref.watch(databaseServiceProvider).getUserCouriers(userId);

    return StreamBuilder<List<CourierModel>>(
      stream: couriersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final couriers = snapshot.data ?? [];
        if (couriers.isEmpty) {
          return const Center(child: Text('No past deliveries'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: couriers.length,
          itemBuilder: (context, index) {
            final courier = couriers[index];
            return _buildHistoryCard(
              title: 'Delivery: ${courier.packageSize}',
              subtitle: DateFormat('MMM d, y • h:mm a').format(courier.createdAt),
              price: courier.price,
              status: courier.status,
              icon: Icons.local_shipping,
              onTap: () => context.push('/history/details', extra: {'courier': courier}),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String subtitle,
    required double price,
    required String status,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    Color statusColor = Colors.grey;
    if (status == 'completed' || status == 'delivered') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'accepted' || status == 'picked_up' || status == 'arrived' || status == 'in_progress') statusColor = Colors.orange;

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Text(
          '₦${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

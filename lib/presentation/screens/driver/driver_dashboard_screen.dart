import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/app_drawer.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Mock Data for Couriers (Still mock for now as we focused on Rides)
  final List<CourierModel> _mockCouriers = [
    CourierModel(
      id: '1',
      pickupAddress: 'Ikeja City Mall',
      dropoffAddress: 'Magodo Phase 2',
      price: 1500,
      status: 'pending',
      riderId: null,
      userId: 'user3',
      pickupLocation: const GeoPoint(6.6018, 3.3515),
      dropoffLocation: const GeoPoint(6.6209, 3.3831),
      createdAt: DateTime.now(),
      packageSize: 'Medium',
      receiverName: 'John Doe',
      receiverPhone: '08012345678',
    ),
  ];

  bool _isAccepting = false;



  @override
  void initState() {
    super.initState();
    _checkActiveRide();
  }

  Future<void> _checkActiveRide() async {
    // Small delay to ensure providers are ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    final driverId = ref.read(authServiceProvider).currentUser?.uid ?? 'driver_1';
    final ride = await ref.read(rideServiceProvider).getActiveRideForDriver(driverId);
    
    if (ride != null && mounted) {
      debugPrint('DriverDashboard: Active ride found (${ride.id}). Resuming navigation.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resuming active ride...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      context.push('/driver-navigation', extra: {'ride': ride});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(driverOnlineProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.black, // Dark background for dashboard
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Driver Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Column(
        children: [
          // Status Toggle
          Container(
            margin: const EdgeInsets.all(16),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isOnline ? 'You are ONLINE' : 'You are OFFLINE',
                      style: TextStyle(
                        color: isOnline ? Colors.greenAccent : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Switch(
                      value: isOnline,
                      activeColor: Colors.greenAccent,
                      onChanged: (val) => ref.read(driverOnlineProvider.notifier).set(val),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: isOnline ? _buildOnlineView() : _buildOfflineView(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.white24),
          const SizedBox(height: 20),
          const Text(
            'Go Online to receive requests',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => ref.read(driverOnlineProvider.notifier).set(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Text(
                'GO ONLINE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shimmer(duration: 2000.ms, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineView() {
    return Stack(
      children: [
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.white54,
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  Tab(text: 'Rides'),
                  Tab(text: 'Couriers'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRidesList(),
                    _buildCouriersList(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'clear_btn',
            backgroundColor: Colors.orange,
            child: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () => _clearAllRides(),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'debug_btn',
            backgroundColor: Colors.red,
            child: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () => _createDebugRide(),
          ),
        ),
      ],
    );
  }

  Widget _buildRidesList() {
    final ridesAsync = ref.watch(ridesStreamProvider);

    return ridesAsync.when(
      data: (rides) {
        if (rides.isEmpty) {
          return const Center(
            child: Text(
              'No ride requests nearby',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _buildRideCard(rides[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Future<void> _createDebugRide() async {
    try {
      final ride = RideModel(
        id: 'debug_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'debug_user',
        pickupLocation: const GeoPoint(6.5244, 3.3792),
        dropoffLocation: const GeoPoint(6.4281, 3.4241),
        pickupAddress: 'Debug Pickup',
        dropoffAddress: 'Debug Dropoff',
        price: 500,
        createdAt: DateTime.now(),
        status: 'pending',
      );
      await ref.read(rideServiceProvider).createRide(ride);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debug Ride Created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debug Error: $e')));
      }
    }
  }

  Future<void> _clearAllRides() async {
    try {
      final rides = await ref.read(rideServiceProvider).getAvailableRides().first;
      for (var ride in rides) {
        await ref.read(rideServiceProvider).updateRideStatus(ride.id, 'cancelled');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All rides cleared')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing rides: $e')));
      }
    }
  }

  Widget _buildCouriersList() {
    if (_mockCouriers.isEmpty) {
      return const Center(
        child: Text(
          'No courier requests nearby',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockCouriers.length,
      itemBuilder: (context, index) {
        return _buildCourierCard(_mockCouriers[index]);
      },
    );
  }

  Widget _buildRideCard(RideModel ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(FontAwesomeIcons.user, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ride Request', // Could fetch user name if we had User Service
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '₦${ride.price.toStringAsFixed(0)}',
                    style: GoogleFonts.roboto(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildLocationRow(Icons.my_location, ride.pickupAddress, Colors.greenAccent),
              const SizedBox(height: 12),
              _buildLocationRow(Icons.location_on, ride.dropoffAddress, Colors.redAccent),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineRide(ride),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('DECLINE'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAccepting ? null : () => _acceptRide(ride),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isAccepting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('ACCEPT'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourierCard(CourierModel courier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(FontAwesomeIcons.box, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Courier: ${courier.packageSize}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '₦${courier.price.toStringAsFixed(0)}',
                    style: GoogleFonts.roboto(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildLocationRow(Icons.my_location, courier.pickupAddress, Colors.greenAccent),
              const SizedBox(height: 12),
              _buildLocationRow(Icons.location_on, courier.dropoffAddress, Colors.redAccent),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineCourier(courier),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('DECLINE'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptCourier(courier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('ACCEPT'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptRide(RideModel ride) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final driverId = ref.read(authServiceProvider).currentUser?.uid ?? 'driver_1';
      
      await ref.read(rideServiceProvider).updateRideStatus(
        ride.id, 
        'accepted', 
        driverId: driverId,
        driverName: 'John Doe',
        driverPhone: '08012345678',
        driverPhoto: 'https://i.pravatar.cc/150?img=11',
        carModel: 'Toyota Camry (Silver)',
        plateNumber: 'LND-823-XA',
      );

      debugPrint('DriverDashboard: Ride accepted. Navigating to /driver-navigation');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride Accepted!')));
        context.push('/driver-navigation', extra: {'ride': ride});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error accepting ride: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  void _declineRide(RideModel ride) {
    // In a real app, we might update a "declinedDrivers" list in Firestore
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride Declined')));
  }

  void _acceptCourier(CourierModel courier) {
    setState(() {
      _mockCouriers.remove(courier);
    });
    context.push('/driver-navigation', extra: {'courier': courier});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Courier Request Accepted!')));
  }

  void _declineCourier(CourierModel courier) {
    setState(() {
      _mockCouriers.remove(courier);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Courier Request Declined')));
  }
}

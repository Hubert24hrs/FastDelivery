import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/app_drawer.dart';
import 'package:fast_delivery/presentation/screens/booking/booking_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  mapbox.MapboxMap? _mapboxMap;

  RideModel? _activeRide;

  @override
  void initState() {
    super.initState();
    _checkActiveRide();
  }

  Future<void> _checkActiveRide() async {
    // Small delay to ensure providers are ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    if (userId != null) {
      debugPrint('HomeScreen: Checking active ride for userId: $userId');
      final ride = await ref.read(rideServiceProvider).getActiveRideForUser(userId);
      if (ride != null && mounted) {
        debugPrint('HomeScreen: Active ride found (${ride.id}). Showing banner.');
        setState(() {
          _activeRide = ride;
        });
      }
    }
  }

  _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Map Background
          mapbox.MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: _onMapCreated,
            styleUri: mapbox.MapboxStyles.DARK,
            cameraOptions: mapbox.CameraOptions(
              center: mapbox.Point(coordinates: mapbox.Position(3.3792, 6.5244)), // Lagos
              zoom: 13.0,
            ),
          ),
          
          // Menu Button (Top Left)
          Positioned(
            top: 50,
            left: 24,
            child: Container(
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
          ).animate().fadeIn().slideX(),

          // Draggable Booking Sheet (Only if no active ride banner is dismissed or we want to allow booking new rides?)
          // For now, let's keep it, but maybe hide it if active ride is shown? 
          // Actually, let's just overlay the banner on top.
          const BookingSheet(),

          // Active Ride Banner
          if (_activeRide != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.black),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Ride in Progress',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Heading to ${_activeRide?.dropoffAddress ?? "Destination"}',
                            style: const TextStyle(color: Colors.black87, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () {
                        setState(() {
                          _activeRide = null;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.go(
                          '/tracking', 
                          extra: {
                            'rideId': _activeRide!.id, 
                            'destinationName': _activeRide!.dropoffAddress,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('TRACK'),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 1, end: 0),
            ),
        ],
      ),
    );
  }
}

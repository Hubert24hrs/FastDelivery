import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class DriverNavigationScreen extends ConsumerStatefulWidget {
  final RideModel? ride;
  final CourierModel? courier;

  const DriverNavigationScreen({
    super.key,
    this.ride,
    this.courier,
  });

  @override
  ConsumerState<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends ConsumerState<DriverNavigationScreen> {
  mapbox.MapboxMap? _mapboxMap;
  String _currentStatus = 'accepted'; 
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _firestoreUpdateTimer;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    if (widget.ride?.status != null) {
      _currentStatus = widget.ride!.status;
      // Map 'pending' (if passed by mistake) to 'accepted' for this screen
      if (_currentStatus == 'pending') _currentStatus = 'accepted';
    }
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _firestoreUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _lastPosition = position;
        _updateMapLocation(position);
      },
    );

    // Update Firestore every 10 seconds to avoid spamming writes
    _firestoreUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_lastPosition != null && widget.ride != null) {
        _updateDriverLocationInFirestore(_lastPosition!);
      }
    });
  }

  Future<void> _updateDriverLocationInFirestore(Position position) async {
    try {
      await ref.read(rideServiceProvider).updateRideStatus(
        widget.ride!.id, 
        _currentStatus,
        driverLocation: GeoPoint(position.latitude, position.longitude),
      );
    } catch (e) {
      debugPrint('Error updating driver location: $e');
    }
  }

  void _updateMapLocation(Position position) {
    // Ideally update a puck or marker on the map
    // For now, we can just center the camera if in navigation mode
    // But let's not force camera updates too aggressively to allow user panning
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // If no ride/courier, show error
    if (widget.ride == null && widget.courier == null) {
      return const Scaffold(body: Center(child: Text('Error: No ride data')));
    }

    // If courier, we might not have a stream yet (mock), so keep existing logic or wrap similarly
    // For now, focusing on RIDE flow as per user request.
    if (widget.courier != null) {
      return _buildCourierView();
    }

    final rideStream = ref.watch(rideServiceProvider).streamRide(widget.ride!.id);

    return Scaffold(
      body: StreamBuilder<RideModel>(
        stream: rideStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ride = snapshot.data!;
          final status = ride.status;
          
          // Update local status for logic if needed, but better to use 'ride.status' directly
          _currentStatus = status;

          return Stack(
            children: [
              mapbox.MapWidget(
                onMapCreated: _onMapCreated,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(
                    coordinates: mapbox.Position(ride.pickupLocation.longitude, ride.pickupLocation.latitude),
                  ),
                  zoom: 13.0,
                ),
              ),
              
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getStatusText(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Ride Request',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _advanceState(ride),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                disabledBackgroundColor: Colors.grey,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : Text(
                                    _getNextButtonText(status),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Info Sheet (Steps)
              Positioned(
                bottom: 30,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStepRow(Icons.my_location, 'Pickup', status == 'accepted'),
                        if (ride.stopLocations.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (int i = 0; i < ride.stopLocations.length; i++)
                            _buildStepRow(Icons.stop_circle_outlined, 'Stop ${i + 1}', false),
                        ],
                        const SizedBox(height: 8),
                        _buildStepRow(Icons.flag, 'Dropoff', status == 'in_progress'),
                      ],
                    ),
                  ),
                ),
              ),

              // Debug: Simulate Movement Button
              Positioned(
                bottom: 180,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'debug_move',
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.directions_run, color: Colors.white),
                  onPressed: _simulateMovement,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

    // Keep existing courier view logic separate or refactor later
    Widget _buildCourierView() {
      // ... (Reuse existing logic for courier, but simplified for now to avoid errors)
      return const Scaffold(body: Center(child: Text('Courier Navigation Placeholder')));
    }

  String _getStatusText(String status) {
    if (status == 'accepted') return 'Heading to Pickup';
    if (status == 'arrived') return 'Waiting for Passenger';
    if (status == 'in_progress') return 'Heading to Dropoff';
    return 'Trip Completed';
  }

  String _getNextButtonText(String status) {
    if (status == 'accepted') return 'ARRIVED AT PICKUP';
    if (status == 'arrived') return 'START TRIP';
    if (status == 'in_progress') return 'COMPLETE TRIP';
    return 'COMPLETE';
  }

  Future<void> _advanceState(RideModel ride) async {
    setState(() => _isLoading = true);
    
    try {
      String nextStatus = '';
      if (ride.status == 'accepted') nextStatus = 'arrived';
      else if (ride.status == 'arrived') nextStatus = 'in_progress';
      else if (ride.status == 'in_progress') nextStatus = 'completed';

      debugPrint('DriverNavigation: Transitioning to nextStatus=$nextStatus');

      if (nextStatus.isNotEmpty) {
        await ref.read(rideServiceProvider).updateRideStatus(ride.id, nextStatus);
        
        if (nextStatus == 'completed') {
          if (mounted) context.pop();
        }
      }
    } catch (e) {
      debugPrint('DriverNavigation: Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _drawRoute();
  }

  Future<void> _drawRoute() async {
    if (_mapboxMap == null) return;

    final pickup = widget.ride?.pickupLocation ?? widget.courier!.pickupLocation;
    final dropoff = widget.ride?.dropoffLocation ?? widget.courier!.dropoffLocation;
    final stops = widget.ride?.stopLocations ?? widget.courier!.stopLocations;

    List<mapbox.Point> points = [
      mapbox.Point(coordinates: mapbox.Position(pickup.longitude, pickup.latitude)),
      ...stops.map((s) => mapbox.Point(coordinates: mapbox.Position(s.longitude, s.latitude))),
      mapbox.Point(coordinates: mapbox.Position(dropoff.longitude, dropoff.latitude)),
    ];

    // Draw Polyline (Mock straight lines for now)
    await _mapboxMap?.annotations.createPolylineAnnotationManager().then((manager) {
      manager.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: points.map((p) => p.coordinates).toList()),
          lineColor: AppTheme.primaryColor.value,
          lineWidth: 5.0,
        ),
      );
    });

    // Fit Camera
    await _mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            (pickup.longitude + dropoff.longitude) / 2,
            (pickup.latitude + dropoff.latitude) / 2,
          ),
        ),
        zoom: 11.0,
      ),
      mapbox.MapAnimationOptions(duration: 1000),
    );
  }
  
  void _simulateMovement() {
    // Mock movement: Move slightly north-east
    final currentLat = _lastPosition?.latitude ?? 6.5244;
    final currentLng = _lastPosition?.longitude ?? 3.3792;
    
    final newLat = currentLat + 0.001;
    final newLng = currentLng + 0.001;
    
    final newPosition = Position(
      latitude: newLat,
      longitude: newLng,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      heading: 0,
      speed: 10,
      speedAccuracy: 0, 
      altitudeAccuracy: 0, 
      headingAccuracy: 0,
    );
    
    _lastPosition = newPosition;
    _updateDriverLocationInFirestore(newPosition);
    _updateMapLocation(newPosition);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Debug: Moved to $newLat, $newLng')),
    );
  }

  Widget _buildStepRow(IconData icon, String text, bool isActive) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isActive ? AppTheme.primaryColor : Colors.white54),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

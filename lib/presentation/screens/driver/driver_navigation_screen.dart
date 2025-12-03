import 'package:fast_delivery/core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.ride?.status != null) {
      _currentStatus = widget.ride!.status;
      // Map 'pending' (if passed by mistake) to 'accepted' for this screen
      if (_currentStatus == 'pending') _currentStatus = 'accepted';
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DriverNavigation: build. status=$_currentStatus');
    final pickup = widget.ride?.pickupLocation ?? widget.courier!.pickupLocation;
    final dropoff = widget.ride?.dropoffLocation ?? widget.courier!.dropoffLocation;
    final stops = widget.ride?.stopLocations ?? widget.courier!.stopLocations;

    // Update UI text based on _currentStatus
    String statusText = '';
    if (_currentStatus == 'accepted') statusText = 'Heading to Pickup';
    else if (_currentStatus == 'arrived') statusText = 'Waiting for Passenger';
    else if (_currentStatus == 'in_progress') statusText = 'Heading to Dropoff';
    else statusText = 'Trip Completed';

    return Scaffold(
      body: Stack(
        children: [
          mapbox.MapWidget(
            onMapCreated: _onMapCreated,
            cameraOptions: mapbox.CameraOptions(
              center: mapbox.Point(
                coordinates: mapbox.Position(pickup.longitude, pickup.latitude),
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
                                  statusText,
                                  style: const TextStyle(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStepRow(Icons.my_location, 'Pickup', _currentStatus == 'accepted'),
                    if (stops.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (int i = 0; i < stops.length; i++)
                        _buildStepRow(Icons.stop_circle_outlined, 'Stop ${i + 1}', false),
                    ],
                    const SizedBox(height: 8),
                    _buildStepRow(Icons.flag, 'Dropoff', _currentStatus == 'in_progress'),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, end: 0),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _advanceState,
        backgroundColor: Colors.red,
        child: const Icon(Icons.fast_forward),
      ),
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

  String _getNextButtonText() {
    if (_currentStatus == 'accepted') return 'ARRIVED AT PICKUP';
    if (_currentStatus == 'arrived') return 'START TRIP';
    if (_currentStatus == 'in_progress') return 'COMPLETE TRIP';
    return 'COMPLETE';
  }

  Future<void> _advanceState() async {
    final rideId = widget.ride?.id;
    debugPrint('DriverNavigation: _advanceState called. rideId=$rideId, currentStatus=$_currentStatus');
    
    if (rideId == null) {
      // Mock flow
      setState(() {
        if (_currentStatus == 'accepted') _currentStatus = 'arrived';
        else if (_currentStatus == 'arrived') _currentStatus = 'in_progress';
        else if (_currentStatus == 'in_progress') context.pop();
      });
      return;
    }

    try {
      String nextStatus = '';
      if (_currentStatus == 'accepted') nextStatus = 'arrived';
      else if (_currentStatus == 'arrived') nextStatus = 'in_progress';
      else if (_currentStatus == 'in_progress') nextStatus = 'completed';

      debugPrint('DriverNavigation: Transitioning to nextStatus=$nextStatus');

      if (nextStatus.isNotEmpty) {
        await ref.read(rideServiceProvider).updateRideStatus(rideId, nextStatus);
        debugPrint('DriverNavigation: Firestore update success');
        
        if (nextStatus == 'completed') {
          if (mounted) context.pop();
        } else {
          setState(() => _currentStatus = nextStatus);
        }
      }
    } catch (e) {
      debugPrint('DriverNavigation: Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
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
    // Simple fit to start/end for now
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
}

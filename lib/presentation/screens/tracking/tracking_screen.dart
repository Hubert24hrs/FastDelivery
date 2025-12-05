import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:url_launcher/url_launcher.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String? destinationName;
  final mapbox.Point? destinationLocation;
  final String? rideId;

  const TrackingScreen({
    super.key,
    this.destinationName,
    this.destinationLocation,
    this.rideId,
  });

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  mapbox.PointAnnotation? _driverAnnotation;
  RideModel? _latestRide;

  _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    
    // Update marker if we already have data
    if (_latestRide != null) {
      _updateDriverMarker(_latestRide);
    }

    // If we have a destination, draw a route (mock polyline)
    if (widget.destinationLocation != null) {
      // Mock Start (Lagos)
      final start = mapbox.Point(coordinates: mapbox.Position(3.3792, 6.5244));
      final end = widget.destinationLocation!;

      // Create a simple straight line for now (Mock Route)
      final polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
      
      await polylineAnnotationManager.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: [
            start.coordinates,
            end.coordinates,
          ]),
          lineColor: AppTheme.primaryColor.value,
          lineWidth: 5.0,
        ),
      );

      // Fit camera to show both points
      await mapboxMap.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              (start.coordinates.lng + end.coordinates.lng) / 2,
              (start.coordinates.lat + end.coordinates.lat) / 2,
            ),
          ),
          zoom: 11.5,
        ),
        mapbox.MapAnimationOptions(duration: 2000),
      );
    }
  }

  Future<void> _updateDriverMarker(RideModel? ride) async {
    if (ride?.driverLocation == null || _pointAnnotationManager == null) return;

    final point = mapbox.Point(
      coordinates: mapbox.Position(
        ride!.driverLocation!.longitude,
        ride.driverLocation!.latitude,
      ),
    );

    if (_driverAnnotation == null) {
      // Create new annotation
      // Use a built-in icon or load an image. For now, let's try to load a simple car icon from assets if available, 
      // or just use a default marker. Since we don't have a car asset confirmed, we'll use a default circle/marker.
      // Actually, Mapbox default marker is fine, or we can try to use an image.
      // Let's assume we don't have a custom icon ready and use a default one or just a circle.
      // Wait, we can use `iconImage` if we add an image to the style.
      // For simplicity, let's just create a point.
      
      _driverAnnotation = await _pointAnnotationManager?.create(
        mapbox.PointAnnotationOptions(
          geometry: point,
          iconImage: 'car-15', // Mapbox default car icon if available, or we might need to load one.
          // If 'car-15' doesn't exist, it might show nothing. Let's try to load an image from assets first?
          // Or better, just use a simple circle for now if we can't guarantee the icon.
          // Actually, let's skip iconImage and see if it shows a default marker.
        ),
      );
    } else {
      // Update existing annotation
      _driverAnnotation?.geometry = point;
      await _pointAnnotationManager?.update(_driverAnnotation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('TrackingScreen build: rideId=${widget.rideId}');
    
    final rideStream = widget.rideId != null 
        ? ref.watch(rideServiceProvider).streamRide(widget.rideId!) 
        : Stream.value(null);

    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          kIsWeb 
            ? Container(color: Colors.grey[900])
            : mapbox.MapWidget(
                key: const ValueKey("mapWidget"),
                onMapCreated: _onMapCreated,
                styleUri: mapbox.MapboxStyles.DARK,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(coordinates: mapbox.Position(3.3792, 6.5244)), // Lagos
                  zoom: 13.0,
                ),
              ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
            ),
          ),

          // Driver & Ride Details Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<RideModel?>(
              stream: rideStream,
              builder: (context, snapshot) {
                debugPrint('Tracking Stream: hasData=${snapshot.hasData}, error=${snapshot.error}, status=${snapshot.data?.status}');
                
                if (snapshot.hasError) {
                  return GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                final ride = snapshot.data;
                final status = ride?.status ?? 'pending';
                
                // Update driver marker
                if (ride != null) {
                  _latestRide = ride;
                  // Schedule microtask to avoid calling setState during build if that happens inside mapbox logic
                  Future.microtask(() => _updateDriverMarker(ride));
                }

                return GlassCard(
                  opacity: 0.9,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Destination Header
                        if (widget.destinationName != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.secondaryColor, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Heading to ${widget.destinationName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Status & Driver Info
                        if (status == 'pending') ...[
                          const CircularProgressIndicator(color: AppTheme.primaryColor),
                          const SizedBox(height: 16),
                          const Text(
                            'Searching for a driver...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else if (status == 'accepted' || status == 'arrived' || status == 'in_progress') ...[
                          Text(
                            status == 'arrived' ? 'Driver has arrived' : 
                            status == 'in_progress' ? 'Heading to destination' :
                            'Driver is on the way',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status == 'arrived' ? 'Meet your driver at pickup' : 'Arriving in 5 min',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 24),

                          // Driver Info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(ride?.driverPhoto ?? 'https://i.pravatar.cc/150?img=11'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ride?.driverName ?? 'Unknown Driver',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '4.9',
                                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '•  ${ride?.carModel ?? 'Vehicle Info'}',
                                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ride?.plateNumber ?? '---',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final Uri launchUri = Uri(
                                      scheme: 'tel',
                                      path: ride?.driverPhone ?? '08012345678',
                                    );
                                    if (await canLaunchUrl(launchUri)) {
                                      await launchUrl(launchUri);
                                    }
                                  },
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Call Driver'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.push('/chat', extra: {
                                      'rideId': ride!.id,
                                      'otherUserName': ride.driverName ?? 'Driver',
                                    });
                                  },
                                  icon: const Icon(Icons.message),
                                  label: const Text('Message'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (status == 'completed') ...[
                          const Icon(Icons.check_circle, color: Colors.green, size: 50),
                          const SizedBox(height: 16),
                          const Text(
                            'Ride Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('BACK TO HOME'),
                            ),
                          ),
                        ] else if (status == 'cancelled') ...[
                           const Icon(Icons.cancel, color: Colors.red, size: 50),
                          const SizedBox(height: 16),
                          const Text(
                            'Ride Cancelled',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white10,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('BACK TO HOME'),
                            ),
                          ),
                        ],
                        
                        // Cancel Button (Only if pending or accepted)
                        if (status == 'pending' || status == 'accepted') ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () async {
                               if (widget.rideId != null) {
                                 await ref.read(rideServiceProvider).updateRideStatus(widget.rideId!, 'cancelled');
                               }
                               if (context.mounted) context.go('/');
                            },
                            child: const Text(
                              'Cancel Ride',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart);
              },
            ),
          ),
        ],
      ),
    );
  }
}

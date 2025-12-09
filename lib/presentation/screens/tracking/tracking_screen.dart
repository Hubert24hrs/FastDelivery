import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/services/notification_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:fast_delivery/presentation/screens/rating/rating_sheet.dart';
import 'package:fast_delivery/presentation/screens/tracking/trip_share_sheet.dart';
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
  // ignore: unused_field - stored for potential map operations
  mapbox.MapboxMap? _mapboxMap;
  mapbox.CircleAnnotationManager? _circleAnnotationManager;
  mapbox.CircleAnnotation? _driverAnnotation;
  RideModel? _latestRide;

  // Calculate estimated time of arrival based on driver location
  int _calculateETA(RideModel? ride) {
    if (ride == null || ride.driverLocation == null) return 5; // Default
    
    // Simple distance-based ETA calculation
    // In production, you'd use a routing API for accurate estimates
    final driverLat = ride.driverLocation!.latitude;
    final driverLng = ride.driverLocation!.longitude;
    final destLat = ride.dropoffLocation.latitude;
    final destLng = ride.dropoffLocation.longitude;
    
    // Rough distance calculation (Haversine would be better)
    final distance = ((destLat - driverLat).abs() + (destLng - driverLng).abs()) * 111; // km approximation
    
    // Assume average speed of 30 km/h in city
    final etaMinutes = (distance / 30 * 60).round();
    return etaMinutes.clamp(1, 60); // Between 1 and 60 minutes
  }

  _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    
    // If we have a ride ID, start monitoring for notifications
    if (widget.rideId != null) {
      ref.read(rideServiceProvider).monitorRideForNotifications(
        widget.rideId!,
        ref.read(notificationServiceProvider),
      ).listen((event) {}); // Just listen to trigger the side effects
    }

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
          lineColor: AppTheme.primaryColor.toARGB32(),
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
    if (ride == null || ride.driverLocation == null || _circleAnnotationManager == null) return;
    
    final point = mapbox.Point(
      coordinates: mapbox.Position(
        ride.driverLocation!.longitude,
        ride.driverLocation!.latitude,
      ),
    );

    if (_driverAnnotation == null) {
      _driverAnnotation = await _circleAnnotationManager?.create(
        mapbox.CircleAnnotationOptions(
          geometry: point,
          circleColor: AppTheme.primaryColor.toARGB32(),
          circleRadius: 10.0,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.0,
        ),
      );
    } else {
      _driverAnnotation?.geometry = point;
      await _circleAnnotationManager?.update(_driverAnnotation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('TrackingScreen build: rideId=${widget.rideId}');
    
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
                if (kDebugMode) debugPrint('Tracking Stream: hasData=${snapshot.hasData}, error=${snapshot.error}, status=${snapshot.data?.status}');
                
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
                            status == 'arrived' 
                                ? 'Meet your driver at pickup' 
                                : status == 'in_progress'
                                    ? 'ETA: ${_calculateETA(ride)} min'
                                    : 'Arriving in ${_calculateETA(ride)} min',
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
                                      path: ride?.driverPhone ?? '08012345678', // Fallback only if totally missing, but ideally we check null
                                    );
                                    if (ride?.driverPhone == null) {
                                       if (context.mounted) {
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver number not found')));
                                       }
                                       return;
                                    }
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
                              const SizedBox(width: 12),
                              // Share Trip Button
                              IconButton(
                                onPressed: () {
                                  if (ride != null) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => TripShareSheet(ride: ride),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.share, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => RatingSheet(
                                    driverName: ride?.driverName ?? 'Driver',
                                    driverPhoto: ride?.driverPhoto,
                                    onSubmit: (rating, feedback, tip) async {
                                      // Save rating to Firestore via RatingService
                                      try {
                                        await ref.read(ratingServiceProvider).submitRating(
                                          rideId: ride!.id,
                                          driverId: ride.driverId!,
                                          passengerId: ride.userId,
                                          stars: rating,
                                          feedback: feedback,
                                          tip: tip,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Thanks for your rating!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          // Show add to favorites dialog
                                          _showAddToFavoritesDialog(context, ref, ride);
                                        }
                                      } catch (e) {
                                        if (kDebugMode) debugPrint('Error saving rating: $e');
                                      }
                                    },
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('RATE YOUR TRIP'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go('/'),
                            child: const Text('Skip to Home', style: TextStyle(color: Colors.white54)),
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

  void _showAddToFavoritesDialog(BuildContext context, WidgetRef ref, RideModel ride) {
    if (ride.driverId == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Add to Favorites?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Would you like to add ${ride.driverName ?? "this driver"} to your favorite drivers?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No Thanks', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = ref.read(currentUserIdProvider);
              if (userId != null) {
                await ref.read(favoriteDriversServiceProvider).addFavorite(
                  userId: userId,
                  driverId: ride.driverId!,
                  driverName: ride.driverName ?? 'Driver',
                  driverPhoto: ride.driverPhoto,
                  carModel: ride.carModel,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Driver added to favorites!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add to Favorites'),
          ),
        ],
      ),
    );
  }
}

import 'package:fast_delivery/core/config/mapbox_init_stub.dart'
    if (dart.library.io) 'package:fast_delivery/core/config/mapbox_init_mobile.dart'
    if (dart.library.html) 'package:fast_delivery/core/config/mapbox_init_web.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  MapboxMap? _mapboxMap;
  Point? _selectedPoint;
  String _address = 'Move map to select location';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    // Ensure Mapbox is initialized with token
    MapboxInit.init();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _onCameraChangeListener(CameraChangedEventData event) {
    // Only update address when camera stops moving (idle) causes less api calls
    // But for better UX we might want to do it on idle
  }

  Future<void> _onMapIdle(MapIdleEventData event) async {
    if (_mapboxMap == null) return;

    final cameraState = await _mapboxMap!.getCameraState();
    final center = cameraState.center;
    
    setState(() {
      _selectedPoint = center;
      _isLoadingAddress = true;
    });

    try {
      // Reverse geocoding
      final placemarks = await placemarkFromCoordinates(
        center.coordinates.lat.toDouble(),
        center.coordinates.lng.toDouble(),
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = '${place.street}, ${place.locality}';
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _address = 'Unknown location';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _address = 'Could not determine address';
        _isLoadingAddress = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedPoint != null) {
      context.pop(_address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            onMapCreated: _onMapCreated,
            
            initialCameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  6.5244, // Lagos
                  3.3792,
                ),
              ),
              zoom: 13.0,
            ),
             onMapIdle: _onMapIdle, 
          ),
          
          // Center Marker
          Center(
            child: Icon(
              Icons.location_on,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          
          // Top Bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.surfaceColor,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Pin your location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Address Card
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingAddress
                            ? const LinearProgressIndicator(color: AppTheme.primaryColor)
                            : Text(
                                _address,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoadingAddress ? null : _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

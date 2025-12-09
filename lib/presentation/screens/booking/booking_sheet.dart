import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class BookingSheet extends ConsumerStatefulWidget {
  const BookingSheet({super.key});

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {
  bool _isLoading = false;
  final TextEditingController _destinationController = TextEditingController();

  Future<void> _bookRide() async {
    setState(() => _isLoading = true);

    try {
      // Mock Destination Coordinates (e.g., Victoria Island, Lagos)
      // In a real app, this would come from the selected destination
      final mockDestination = mapbox.Point(coordinates: mapbox.Position(3.4241, 6.4281)); 
      final mockPickup = mapbox.Point(coordinates: mapbox.Position(3.3792, 6.5244)); // Mock pickup

      final ride = RideModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: ref.read(authServiceProvider).currentUser?.uid ?? 'guest',
        pickupLocation: GeoPoint(mockPickup.coordinates.lat.toDouble(), mockPickup.coordinates.lng.toDouble()),
        dropoffLocation: GeoPoint(mockDestination.coordinates.lat.toDouble(), mockDestination.coordinates.lng.toDouble()),
        pickupAddress: 'Current Location', // Should be real address
        dropoffAddress: _destinationController.text.isEmpty ? 'Victoria Island' : _destinationController.text,
        price: 2500,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      await ref.read(rideServiceProvider).createRide(ride);

      if (mounted) {
        context.go(
          '/tracking', 
          extra: {
            'destinationName': ride.dropoffAddress,
            'destinationLocation': mockDestination,
            'rideId': ride.id, // Pass ride ID for tracking
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return GlassCard(
          opacity: 0.95,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Service Selector (Centered and Spaced)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildServiceTab('Ride', true),
                        const SizedBox(width: 24), // Increased spacing
                        _buildServiceTab('Couriers', false, onTap: () => context.go('/courier')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Destination Input (Read Only - Navigates to Search)
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final result = await context.push('/destination-search');
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            _destinationController.text = result['name'] ?? '';
                            // We could also store the location coordinates here if returned
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppTheme.primaryColor),
                            const SizedBox(width: 16),
                            Text(
                              _destinationController.text.isEmpty 
                                ? 'Where to?' 
                                : _destinationController.text,
                              style: TextStyle(
                                color: _destinationController.text.isEmpty 
                                  ? Colors.white.withValues(alpha: 0.7) 
                                  : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: Colors.white70),
                                  SizedBox(width: 4),
                                  Text(
                                    'Later',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Recent Places (Optional - for quick access)
                    const SizedBox(height: 24),
                    _buildRecentItem('First Bank Lekki', '3 Chris Efunyemi Onanuga Street'),
                    _buildRecentItem('15 Nike Art Gallery Road', 'Lagos, Nigeria'),
                    
                    const SizedBox(height: 24),
                    
                    // Ride Options (Only show if expanded or user interacts - simplified for now)
                    // For now, just a big "Book Ride" button if we want to simulate the flow
                     SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _bookRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('BOOK RIDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentItem(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.access_time, color: Colors.white70, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      onTap: () => context.push('/destination-search'),
    );
  }

  Widget _buildServiceTab(String label, bool isSelected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
    );
  }
}

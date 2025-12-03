import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:go_router/go_router.dart';

class BookingSheet extends ConsumerStatefulWidget {
  const BookingSheet({super.key});

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {
  int _selectedRideIndex = 0;
  bool _isLoading = false;
  final TextEditingController _destinationController = TextEditingController();

  final List<Map<String, dynamic>> _rideOptions = [
    {'name': 'Standard', 'price': 1200.0, 'time': '5 min', 'icon': FontAwesomeIcons.car},
    {'name': 'Premium', 'price': 2500.0, 'time': '8 min', 'icon': FontAwesomeIcons.carSide},
    {'name': 'Van', 'price': 4000.0, 'time': '15 min', 'icon': FontAwesomeIcons.vanShuttle},
  ];

  Future<void> _bookRide() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a ride')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Get Current Location
      final position = await ref.read(locationServiceProvider).determinePosition();
      if (!mounted) return;

      // 2. Process Payment
      final userEmail = ref.read(authServiceProvider).currentUser?.email ?? 'user@example.com';
      final price = _rideOptions[_selectedRideIndex]['price'] as double;
      
      final paymentSuccess = await ref.read(paymentServiceProvider).chargeCard(
        context: context,
        amount: price,
        email: userEmail,
      );

      if (!paymentSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Failed or Cancelled')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
      
      // 3. Create Ride Request
      final ride = RideModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID generation
        userId: userId,
        pickupLocation: GeoPoint(position.latitude, position.longitude),
        dropoffLocation: const GeoPoint(6.5244, 3.3792), // Mock Dropoff (Lagos)
        pickupAddress: 'Current Location',
        dropoffAddress: _destinationController.text.isEmpty ? 'Selected Destination' : _destinationController.text,
        price: _rideOptions[_selectedRideIndex]['price'],
        createdAt: DateTime.now(),
      );

      await ref.read(databaseServiceProvider).createRideRequest(ride);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride Requested Successfully!')),
        );
        // Reset or Navigate
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: 0.8,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),

            // Service Selector (Visual Only here since we are already in Booking)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildServiceTab('Ride', true),
                  const SizedBox(width: 16),
                  _buildServiceTab('Couriers', false, onTap: () => context.go('/courier')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Destination Input
            TextField(
              controller: _destinationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Where to?',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Ride Options
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _rideOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final option = _rideOptions[index];
                  final isSelected = _selectedRideIndex == index;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRideIndex = index),
                    child: AnimatedContainer(
                      duration: 300.ms,
                      width: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.white10,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            option['icon'],
                            color: isSelected ? AppTheme.primaryColor : Colors.white70,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            option['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₦${option['price']}',
                            style: TextStyle(
                              color: isSelected ? AppTheme.secondaryColor : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Book Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _bookRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  elevation: 10,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('BOOK RIDE'),
              ),
            ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutQuart);
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
    );
  }
}

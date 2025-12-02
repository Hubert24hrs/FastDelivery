import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourierScreen extends ConsumerStatefulWidget {
  const CourierScreen({super.key});

  @override
  ConsumerState<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends ConsumerState<CourierScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  String _selectedSize = 'Motorcycle';
  bool _isLoading = false;

  Future<void> _requestCourier() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request a courier')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Get Current Location (Mocking Pickup for now if empty)
      final position = await ref.read(locationServiceProvider).determinePosition();

      // 2. Process Payment
      final userEmail = ref.read(authServiceProvider).currentUser?.email ?? 'user@example.com';
      final price = _calculatePrice(_selectedSize);
      
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
      
      // 3. Create Courier Request
      final courier = CourierModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        pickupLocation: GeoPoint(position.latitude, position.longitude),
        dropoffLocation: const GeoPoint(6.5244, 3.3792), // Mock Dropoff
        pickupAddress: _pickupController.text.isEmpty ? 'Current Location' : _pickupController.text,
        dropoffAddress: _dropoffController.text.isEmpty ? 'Selected Dropoff' : _dropoffController.text,
        packageSize: _selectedSize, // Now storing Vehicle Type
        receiverName: 'Receiver Name', // Placeholder
        receiverPhone: '08000000000', // Placeholder
        price: _calculatePrice(_selectedSize),
        createdAt: DateTime.now(),
      );

      await ref.read(databaseServiceProvider).createCourierRequest(courier);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Courier Requested Successfully!')),
        );
        context.go('/'); // Go back home
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

  double _calculatePrice(String vehicleType) {
    switch (vehicleType) {
      case 'Car': return 2500.0;
      case 'Motorcycle': return 1000.0;
      default: return 1000.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Different variant for Courier)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0E21), Color(0xFF330033)], // Purple tint
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          shape: BoxShape.circle,
                          boxShadow: [AppTheme.neonShadow],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.go('/'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Courier Service',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),

                  // Package Details Form
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _pickupController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Pickup Location',
                              prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _dropoffController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Drop-off Location',
                              prefixIcon: Icon(Icons.flag, color: AppTheme.secondaryColor),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Vehicle Type Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSizeOption('Motorcycle', Icons.two_wheeler),
                              _buildSizeOption('Car', Icons.directions_car),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestCourier,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black) 
                        : const Text('Find Courier'),
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

  Widget _buildSizeOption(String label, IconData icon) {
    final isSelected = _selectedSize == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSize = label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: isSelected ? Colors.black : Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.white70,
              fontWeight: FontWeight.bold,
            )
          ),
        ],
      ),
    );
  }
}

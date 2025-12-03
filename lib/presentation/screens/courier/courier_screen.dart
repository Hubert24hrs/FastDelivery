import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';

import 'package:fast_delivery/presentation/screens/courier/package_details_sheet.dart';
import 'package:fast_delivery/presentation/screens/courier/propose_price_sheet.dart';
import 'package:fast_delivery/presentation/screens/courier/route_entry_sheet.dart';
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
      if (!mounted) return;

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

  void _openRouteEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RouteEntrySheet(),
    );
  }

  void _openPackageDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PackageDetailsSheet(),
    );
  }

  void _openProposePrice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProposePriceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed base to white as per reference
      body: Stack(
        children: [
          // Map Background Placeholder (Simulating the map behind)
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text('Map View Placeholder', style: TextStyle(color: Colors.grey)),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.go('/'),
              ),
            ),
          ),

          // Main Content Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Courier delivery',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Vehicle Selection
                  Row(
                    children: [
                      _buildVehicleOption('Car', Icons.directions_car),
                      const SizedBox(width: 12),
                      _buildVehicleOption('Motorcycle', Icons.two_wheeler),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Current Location Display
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Prince Samuel Adedoyin St 2', // Mock current location
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // To Input with Add Stops
                  GestureDetector(
                    onTap: _openRouteEntry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black54),
                          const SizedBox(width: 12),
                          const Text(
                            'To',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Add stops',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.add, color: Colors.black54, size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Order Details
                  _buildListTile(
                    'Package details', 
                    Icons.tune, 
                    onTap: _openPackageDetails,
                  ),
                  const SizedBox(height: 8),
                  
                  // Offer your fare
                  _buildListTile(
                    'Propose your price', 
                    Icons.money,
                    onTap: _openProposePrice,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestCourier,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCCFF00), // Lime green
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black) 
                        : const Text(
                            'Find a courier',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildVehicleOption(String label, IconData icon) {
    final isSelected = _selectedSize == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSize = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEFFCC) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 18,
              color: Colors.black,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

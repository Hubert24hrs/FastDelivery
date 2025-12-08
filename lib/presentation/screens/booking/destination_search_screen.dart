import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _pickupController = TextEditingController(text: "Current Location");
  final TextEditingController _dropoffController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  Future<void> _selectDestination(String destinationName) async {
    setState(() => _isLoading = true);

    try {
      // 1. Try to get real coordinates
      List<Location> locations = await locationFromAddress(destinationName);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final destinationPoint = mapbox.Point(
          coordinates: mapbox.Position(location.longitude, location.latitude),
        );

        if (mounted) {
          context.pop({
            'name': destinationName,
            'location': destinationPoint,
          });
        }
      } else {
        // Fallback if no location found
        _showError('Location not found. Using mock destination.');
        _returnMock(destinationName);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (mounted) {
         _returnMock(destinationName);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _returnMock(String destinationName) {
    // Mock Destination Coordinates (e.g., Victoria Island, Lagos)
    final mockDestination = mapbox.Point(coordinates: mapbox.Position(3.4241, 6.4281));

    context.pop({
      'name': destinationName,
      'location': mockDestination,
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar (since we want full control)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Your route',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _addStop,
                    ),
                  ],
                ),
              ),

              // Input Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  opacity: 0.1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        // Pickup
                        _buildInputRow(
                          controller: _pickupController,
                          icon: Icons.my_location,
                          iconColor: AppTheme.secondaryColor,
                          hint: 'Pickup location',
                          isReadOnly: true,
                        ),
                        const SizedBox(height: 12),

                        // Stops
                        for (int i = 0; i < _stopControllers.length; i++) ...[
                          _buildInputRow(
                            controller: _stopControllers[i],
                            icon: Icons.stop_circle_outlined,
                            iconColor: Colors.orange,
                            hint: 'Add stop',
                            onRemove: () => _removeStop(i),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Dropoff
                        _buildInputRow(
                          controller: _dropoffController,
                          icon: Icons.location_on_outlined,
                          iconColor: AppTheme.primaryColor,
                          hint: 'Dropoff location',
                          autofocus: true,
                          isLoading: _isLoading,
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _selectDestination(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Saved Destinations Quick Access
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSavedDestinationCard(
                        icon: Icons.home,
                        label: 'Home',
                        address: 'Set home location',
                        onTap: () => _selectDestination('Home'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSavedDestinationCard(
                        icon: Icons.work,
                        label: 'Work',
                        address: 'Set work location',
                        onTap: () => _selectDestination('Work'),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              // Recent Places Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RECENT PLACES',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Recent Places List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildRecentPlace(
                      'First Bank Lekki',
                      '3 Chris Efunyemi Onanuga Street, Lekki',
                      '3 km',
                    ),
                    _buildRecentPlace(
                      '15 Nike Art Gallery Road',
                      'Lagos, Nigeria',
                      '< 1 km',
                    ),
                    _buildRecentPlace(
                      'Murtala Muhammed Airport',
                      '1 Airport Road, Ikeja',
                      '24.4 km',
                      icon: Icons.local_airport,
                    ),
                    _buildRecentPlace(
                      'Eko Hotel',
                      '1415 Adetokunbo Ademola Street',
                      '6.2 km',
                    ),
                    _buildRecentPlace(
                      'Lekki Phase One',
                      'Lekki, Lagos',
                      '2.1 km',
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
    bool isReadOnly = false,
    bool autofocus = false,
    bool isLoading = false,
    VoidCallback? onRemove,
    Function(String)? onSubmitted,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              readOnly: isReadOnly,
              autofocus: autofocus,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                          ),
                        ),
                      )
                    : (onRemove != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                            onPressed: onRemove,
                          )
                        : null),
              ),
            ),
          ),
        ),
        if (onRemove == null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.add, color: Colors.white54, size: 24),
        ],
      ],
    );
  }

  Widget _buildRecentPlace(String title, String subtitle, String distance, {IconData icon = Icons.access_time}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white10,
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Text(
        distance,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      onTap: () => _selectDestination(title),
    );
  }

  Widget _buildSavedDestinationCard({
    required IconData icon,
    required String label,
    required String address,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    address,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/app_drawer.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:url_launcher/url_launcher.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAccepting = false;
  int _selectedIndex = 0; // For NavigationRail
  
  // For the earnings chart mock data
  final List<Color> gradientColors = [
    const Color(0xFF6C63FF), // Purple
    const Color(0xFF00E5FF), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    // Removed _checkActiveRide() to fix "glitch" of auto-navigating on startup
  }

  @override
  Widget build(BuildContext context) {
    final ridesAsync = ref.watch(ridesStreamProvider);
    final couriersAsync = ref.watch(activeCouriersProvider);
    final isOnline = ref.watch(driverOnlineProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8F9FE), // Light Blue-ish White
      body: ridesAsync.when(
        data: (rides) {
          // Check for courier requests as well
          final couriers = couriersAsync.maybeWhen(
            data: (data) => data,
            orElse: () => <CourierModel>[],
          );
          
          // Debug output
          debugPrint('DriverDashboard: isOnline=$isOnline, rides=${rides.length}, couriers=${couriers.length}');
          
          // Only switch to Request View if online AND there are pending requests
          if (isOnline) {
            if (rides.isNotEmpty) {
              debugPrint('DriverDashboard: Showing ride request');
              return _buildRequestView(rides.first);
            } else if (couriers.isNotEmpty) {
              debugPrint('DriverDashboard: Showing courier request');
              return _buildCourierRequestView(couriers.first);
            }
          }
          return _buildDashboardView(isOnline);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildDashboardView(isOnline), // Fallback
      ),
    );
  }

  // --- REFERENCE IMAGE 1: DASHBOARD / STATS ---
  Widget _buildDashboardView(bool isOnline) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Stack(
      children: [
        Row(
          children: [
            // Sidebar (Navigation Rail) - Matches the "Purple Sidebar" description
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
                // Navigate to appropriate screens
                switch (index) {
                  case 0: // Home - stay here
                    break;
                  case 1: // Wallet
                    context.push('/wallet');
                    break;
                  case 2: // Trips/History
                    context.push('/history');
                    break;
                  case 3: // Settings
                    context.push('/settings');
                    break;
                }
              },
              backgroundColor: const Color(0xFF6C63FF), // FastPro Purple
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.5)),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
              unselectedLabelTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
              labelType: NavigationRailLabelType.all,
              minWidth: 70,
              groupAlignment: -0.8, // Top aligned
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Icon(FontAwesomeIcons.bolt, color: Colors.white, size: 28), // Logo
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined, size: 22),
                  selectedIcon: Icon(Icons.dashboard, size: 22),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.wallet_outlined, size: 22),
                  selectedIcon: Icon(Icons.wallet, size: 22),
                  label: Text('Wallet'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined, size: 22),
                  selectedIcon: Icon(Icons.history, size: 22),
                  label: Text('Trips'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined, size: 22),
                  selectedIcon: Icon(Icons.settings, size: 22),
                  label: Text('Settings'),
                ),
              ],
            ),

            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Top Bar
                  _buildDashboardAppBar(isOnline),
                  
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEarningsChartCard(),
                          const SizedBox(height: 24),
                          Text(
                            'Stats Overview',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatsGrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Mobile menu FAB for drawer access
        if (isMobile)
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDashboardAppBar(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Driver Mode',
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Compact toggle
          GestureDetector(
            onTap: () => ref.read(driverOnlineProvider.notifier).toggle(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isOnline ? Colors.green : Colors.red),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: isOnline ? Colors.green : Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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

  Widget _buildEarningsChartCard() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦ 4,336',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.show_chart, color: Color(0xFF6C63FF)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(2, 3.5),
                      FlSpot(4, 2),
                      FlSpot(6, 4.5),
                      FlSpot(8, 3.8),
                      FlSpot(10, 5),
                      FlSpot(11, 4),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(colors: gradientColors),
                    barWidth: 6,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: gradientColors.map((color) => color.withValues(alpha: 0.2)).toList(),
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _buildStatsGrid() {
    // Responsive grid
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1; 
        // Keeping it 2 collumns max for cards to be wide and informative
        
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2, // Taller cards to prevent overflow
          children: [
            _buildStatCard('Trips', '34', Icons.directions_car, Colors.blue),
            _buildStatCard('Time', '5h 12m', Icons.timer, Colors.orange),
            _buildStatCard('Rating', '4.9', Icons.star, Colors.amber),
            _buildStatCard('Accept', '94%', Icons.check_circle, Colors.green),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- REFERENCE IMAGE 2: REQUEST / NEGOTIATION ---
  Widget _buildRequestView(RideModel ride) {
    return Stack(
      children: [
        // Full Screen Map with Padding for the left rail if we wanted... 
        // But Ref 2 usually shows full screen map. We'll do full screen.
        mapbox.MapWidget(
          key: ValueKey("request_map_${ride.id}"),
          styleUri: mapbox.MapboxStyles.LIGHT, 
          cameraOptions: mapbox.CameraOptions(
            center: mapbox.Point(
              coordinates: mapbox.Position(
                ride.pickupLocation.longitude, 
                ride.pickupLocation.latitude
              )
            ),
            zoom: 14.5,
          ),
        ),

        // Floating Panel
        // Centered or Bottom Sheet style? Ref 2 implies a nice card on the side or bottom.
        // Let's use a nice floating card on the left-bottom for larger screens, bottom for mobile.
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            margin: const EdgeInsets.all(16),
            height: 400,
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildRequestPanel(ride),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestPanel(RideModel ride) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Accent
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF), // Purple Header
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 24,
                  child: Icon(FontAwesomeIcons.user, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Request',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'John Doe', // Mock Name
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '2.5 km',
                    style: TextStyle(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Price
                  Text(
                    '₦${ride.price.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    'Estimated Fare',
                     style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  // Timeline
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTimelineTile(
                            isFirst: true,
                            isLast: false,
                            title: 'Pickup',
                            subtitle: ride.pickupAddress,
                            color: const Color(0xFF6C63FF),
                          ),
                          _buildTimelineTile(
                            isFirst: false,
                            isLast: true,
                            title: 'Dropoff',
                            subtitle: ride.dropoffAddress,
                            color: const Color(0xFF00E5FF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _declineRide(ride),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            foregroundColor: Colors.grey[700],
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAccepting ? null : () => _acceptRide(ride),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          ),
                          child: _isAccepting 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Accept Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required bool isFirst,
    required bool isLast,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 2),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[200],
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRide(RideModel ride) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final driverId = ref.read(authServiceProvider).currentUser?.uid ?? 'driver_1';
      
      await ref.read(rideServiceProvider).updateRideStatus(
        ride.id, 
        'accepted', 
        driverId: driverId,
        driverName: 'John Doe',
        driverPhone: '08012345678',
        driverPhoto: 'https://i.pravatar.cc/150?img=11',
        carModel: 'Toyota Camry (Silver)',
        plateNumber: 'LND-823-XA',
      );

      if (mounted) {
        context.push('/driver-navigation', extra: {'ride': ride});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _declineRide(RideModel ride) async {
    try {
      await ref.read(rideServiceProvider).updateRideStatus(ride.id, 'cancelled');
    } catch (e) {
      debugPrint('Error declining: $e');
    }
  }

  // --- COURIER HANDLING ---

  Widget _buildCourierRequestView(CourierModel courier) {
    return Stack(
      children: [
        // Background (Light or Map) - Using light color for courier
        Container(color: const Color(0xFFF8F9FE)),

        // Floating Panel
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildCourierRequestPanel(courier),
          ),
        ),
      ],
    );
  }

  Widget _buildCourierRequestPanel(CourierModel courier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Accent - Orange for Courier
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.orange, // Orange for Courier
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 24,
                  child: Icon(FontAwesomeIcons.box, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Courier Request',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        courier.receiverName.isNotEmpty ? courier.receiverName : 'Package Delivery',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    courier.packageSize,
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Price
                Text(
                  '₦${courier.price.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Proposed Fare',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 20),
                
                // Locations
                _buildTimelineTile(
                  isFirst: true,
                  isLast: false,
                  title: 'Pickup',
                  subtitle: courier.pickupAddress,
                  color: Colors.orange,
                ),
                _buildTimelineTile(
                  isFirst: false,
                  isLast: true,
                  title: 'Deliver to',
                  subtitle: courier.dropoffAddress,
                  color: Colors.green,
                ),
                
                const SizedBox(height: 20),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _declineCourier(courier),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAccepting ? null : () => _acceptCourier(courier),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isAccepting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Accept', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCourier(CourierModel courier) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final driverId = ref.read(authServiceProvider).currentUser?.uid ?? 'driver_1';
      
      await ref.read(databaseServiceProvider).updateCourierStatus(
        courier.id, 
        'accepted', 
        driverId,
      );

      if (mounted) {
        context.push('/driver-navigation', extra: {'courier': courier});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _declineCourier(CourierModel courier) async {
    try {
      final driverId = ref.read(authServiceProvider).currentUser?.uid ?? '';
      await ref.read(databaseServiceProvider).updateCourierStatus(courier.id, 'cancelled', driverId);
    } catch (e) {
      debugPrint('Error declining courier: $e');
    }
  }
}

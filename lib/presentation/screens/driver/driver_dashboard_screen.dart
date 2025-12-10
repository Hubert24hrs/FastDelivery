import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/app_drawer.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
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
  
  // For the earnings chart - matching green theme
  final List<Color> gradientColors = [
    AppTheme.primaryColor,
    const Color(0xFF00E5FF), // Cyan accent
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ridesAsync = ref.watch(ridesStreamProvider);
    final couriersAsync = ref.watch(activeCouriersProvider);
    final isOnline = ref.watch(driverOnlineProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            const BackgroundOrbs(),
            ridesAsync.when(
              data: (rides) {
                final couriers = couriersAsync.maybeWhen(
                  data: (data) => data,
                  orElse: () => <CourierModel>[],
                );
                
                debugPrint('DriverDashboard: isOnline=$isOnline, rides=${rides.length}, couriers=${couriers.length}');
                
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
              loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              error: (err, stack) => _buildDashboardView(isOnline),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODERN DARK DASHBOARD ---
  Widget _buildDashboardView(bool isOnline) {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar with menu and status toggle
          _buildDashboardAppBar(isOnline),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Earnings Card
                  _buildEarningsChartCard()
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  
                  // Stats Title
                  Text(
                    'Stats Overview',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Grid
                  _buildStatsGrid()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.wallet,
                          label: 'Wallet',
                          onTap: () => context.push('/wallet'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.history,
                          label: 'Trips',
                          onTap: () => context.push('/history'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () => context.push('/settings'),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.neomorphicShadow(),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardAppBar(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Menu Button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.neomorphicShadow(),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              'Driver Dashboard',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Online/Offline Toggle
          GestureDetector(
            onTap: () => ref.read(driverOnlineProvider.notifier).toggle(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isOnline 
                    ? AppTheme.primaryColor.withValues(alpha: 0.2) 
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isOnline ? AppTheme.primaryColor : Colors.red,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline ? AppTheme.primaryColor : Colors.red).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isOnline ? AppTheme.primaryColor : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isOnline ? AppTheme.primaryColor : Colors.red).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'ONLINE' : 'OFFLINE',
                    style: GoogleFonts.spaceGrotesk(
                      color: isOnline ? AppTheme.primaryColor : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
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
      height: 280,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.neomorphicShadow(),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      padding: const EdgeInsets.all(20),
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
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₦',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4,336',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(Icons.trending_up, color: AppTheme.primaryColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: gradientColors.map((color) => color.withValues(alpha: 0.15)).toList(),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('Trips', '34', Icons.directions_car, const Color(0xFF4FC3F7)),
        _buildStatCard('Time', '5h 12m', Icons.schedule, const Color(0xFFFF8A65)),
        _buildStatCard('Rating', '4.9', Icons.star_rounded, const Color(0xFFFFD54F)),
        _buildStatCard('Accept', '94%', Icons.check_circle, AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.neomorphicShadow(),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
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

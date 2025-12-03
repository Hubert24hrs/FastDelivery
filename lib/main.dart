import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/screens/auth/login_screen.dart';
import 'package:fast_delivery/presentation/screens/courier/courier_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_dashboard_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_mode_selection_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_pending_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_registration_screen.dart';
import 'package:fast_delivery/presentation/screens/home/home_screen.dart';
import 'package:fast_delivery/presentation/screens/map/map_screen.dart';
import 'package:fast_delivery/presentation/screens/profile/profile_screen.dart';
import 'package:fast_delivery/presentation/screens/settings/settings_screen.dart';
import 'package:fast_delivery/presentation/screens/splash/splash_screen.dart';
import 'package:fast_delivery/presentation/screens/wallet/add_card_screen.dart';
import 'package:fast_delivery/presentation/screens/wallet/transaction_history_screen.dart';
import 'package:fast_delivery/presentation/screens/wallet/wallet_screen.dart';
import 'package:fast_delivery/presentation/screens/tracking/tracking_screen.dart';
import 'package:fast_delivery/presentation/screens/booking/destination_search_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_navigation_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fast_delivery/core/config/mapbox_init_stub.dart'
    if (dart.library.io) 'package:fast_delivery/core/config/mapbox_init_mobile.dart'
    if (dart.library.html) 'package:fast_delivery/core/config/mapbox_init_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxInit.init();
  
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, // Uncomment if using flutterfire configure
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const ProviderScope(child: FastDeliveryApp()));
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/courier',
      builder: (context, state) => const CourierScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletScreen(),
      routes: [
        GoRoute(
          path: 'add-card',
          builder: (context, state) => const AddCardScreen(),
        ),
        GoRoute(
          path: 'transactions',
          builder: (context, state) => const TransactionHistoryScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/driver-selection',
      builder: (context, state) => const DriverModeSelectionScreen(),
    ),
    GoRoute(
      path: '/driver-registration',
      builder: (context, state) {
        final type = state.uri.queryParameters['type'] ?? 'driver';
        return DriverRegistrationScreen(type: type);
      },
    ),
    GoRoute(
      path: '/driver-pending',
      builder: (context, state) => const DriverPendingScreen(),
    ),
    GoRoute(
      path: '/driver',
      builder: (context, state) => const DriverDashboardScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TrackingScreen(
          destinationName: extra?['destinationName'],
          destinationLocation: extra?['destinationLocation'],
          rideId: extra?['rideId'],
        );
      },
    ),
    GoRoute(
      path: '/destination-search',
      builder: (context, state) => const DestinationSearchScreen(),
    ),
    GoRoute(
      path: '/driver-navigation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DriverNavigationScreen(
          ride: extra?['ride'],
          courier: extra?['courier'],
        );
      },
    ),
  ],
);

class FastDeliveryApp extends ConsumerWidget {
  const FastDeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Fast Delivery',
      theme: AppTheme.futuristicTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

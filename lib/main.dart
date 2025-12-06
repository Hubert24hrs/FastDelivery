import 'package:fast_delivery/core/services/notification_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:fast_delivery/core/utils/router_utils.dart';
import 'package:fast_delivery/core/router/app_router.dart';
import 'package:fast_delivery/firebase_options.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:fast_delivery/presentation/screens/auth/login_screen.dart';
import 'package:fast_delivery/presentation/screens/chat/chat_screen.dart';
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
import 'package:fast_delivery/presentation/screens/history/history_details_screen.dart';
import 'package:fast_delivery/presentation/screens/history/history_screen.dart';
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
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const ProviderScope(child: FastDeliveryApp()));
}

class FastDeliveryApp extends ConsumerStatefulWidget {
  const FastDeliveryApp({super.key});

  @override
  ConsumerState<FastDeliveryApp> createState() => _FastDeliveryAppState();
}

class _FastDeliveryAppState extends ConsumerState<FastDeliveryApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Notification Service
    if (!kIsWeb) {
      ref.read(notificationServiceProvider).initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Fast Delivery',
      theme: AppTheme.futuristicTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}





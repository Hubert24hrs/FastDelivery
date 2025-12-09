import 'package:fast_delivery/core/services/notification_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:fast_delivery/core/router/app_router.dart';
import 'package:fast_delivery/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fast_delivery/core/config/mapbox_init_stub.dart'
    if (dart.library.io) 'package:fast_delivery/core/config/mapbox_init_mobile.dart'
    if (dart.library.html) 'package:fast_delivery/core/config/mapbox_init_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxInit.init();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Could not load .env file: $e");
  }
  
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

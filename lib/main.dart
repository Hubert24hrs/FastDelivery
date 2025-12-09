import 'dart:async';
import 'dart:ui';

import 'package:fast_delivery/core/services/notification_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/error_boundary.dart';
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
  // Wrap entire app in error zone
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    MapboxInit.init();
    
    // Set up global error handlers
    _setupErrorHandlers();
    
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
  }, (error, stackTrace) {
    // Handle uncaught async errors
    debugPrint('Uncaught async error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

/// Set up global error handlers for Flutter errors
void _setupErrorHandlers() {
  // Override the default error widget builder for release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // In debug mode, show the default red error screen
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    // In release mode, show a user-friendly error widget
    return GlobalErrorWidget(errorDetails: details);
  };

  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    // In production, you might want to send this to a crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error');
    debugPrint('Stack trace: $stack');
    // Return true to indicate the error was handled
    return true;
  };
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
      builder: (context, child) {
        // Wrap with error boundary for additional protection
        return ErrorBoundary(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}


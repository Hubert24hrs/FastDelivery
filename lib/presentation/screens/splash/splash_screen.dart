import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3D Logo Animation
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.5))
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(0.9, 0.9),
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  ),
            ),
            const SizedBox(height: 40),
            Text(
              'FAST DELIVERY',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
            ).animate().fadeIn(duration: 1.seconds).slideY(begin: 0.5, end: 0),
            const SizedBox(height: 10),
            Text(
              'LAGOS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    letterSpacing: 8,
                  ),
            ).animate().fadeIn(delay: 500.ms, duration: 1.seconds),
          ],
        ),
      ),
    );
  }
}

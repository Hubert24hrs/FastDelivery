
import 'dart:ui';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Animated Background Orbs
          const Positioned(
            top: -100,
            left: -100,
            child: _AnimatedOrb(color: Color(0xFFCCFF00), size: 300),
          ),
          const Positioned(
            bottom: -50,
            right: -50,
            child: _AnimatedOrb(color: Colors.cyanAccent, size: 250),
          ),
          const Positioned(
            top: 200,
            right: -100,
            child: _AnimatedOrb(color: Colors.purpleAccent, size: 200),
          ),

          // 2. Blur Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: BackdropFilter(
                filter:  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  // Actually, let's just use a dark gradient overlay to smooth things out
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
              ),
            ),
          ),

          // 3. Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60), // Spacing since logo is gone
                  
                  // Login Card
                  GlassCard(
                    opacity: 0.05,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Sign in to continue',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.3, end: 0),
                          
                          const SizedBox(height: 40),
                          
                          // Email Input
                          _buildTextField(
                            label: 'Email',
                            icon: Icons.email_outlined,
                            delay: 400.ms,
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Input
                          _buildTextField(
                            label: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            delay: 600.ms,
                          ),
                          const SizedBox(height: 40),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => context.go('/'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                                elevation: 20,
                                shadowColor: const Color(0xFFCCFF00).withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                        ],
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuint)
                    .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.1)),
                  
                  const SizedBox(height: 40),
                  
                  // Social Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(icon: FontAwesomeIcons.google, onPressed: () {}, delay: 1000.ms),
                      const SizedBox(width: 24),
                      _SocialButton(icon: FontAwesomeIcons.apple, onPressed: () {}, delay: 1200.ms),
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

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    required Duration delay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: const Color(0xFFCCFF00)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}

class _AnimatedOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _AnimatedOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 4.seconds, curve: Curves.easeInOut)
      .move(begin: const Offset(-20, -20), end: const Offset(20, 20), duration: 5.seconds, curve: Curves.easeInOut);
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Duration delay;

  const _SocialButton({required this.icon, required this.onPressed, required this.delay});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    ).animate().fadeIn(delay: delay).scale(begin: const Offset(0, 0), curve: Curves.elasticOut);
  }
}

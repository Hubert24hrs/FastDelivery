
import 'dart:ui';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:ui';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/models/user_model.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      
      if (_isLogin) {
        final credential = await authService.signIn(email: email, password: password);
        // Self-healing: Check if user doc exists, if not create it
        if (credential.user != null) {
          final userDoc = await dbService.getUser(credential.user!.uid);
          if (userDoc == null) {
            final newUser = UserModel(
              id: credential.user!.uid,
              email: email,
              displayName: email.split('@')[0],
              phoneNumber: '',
              role: 'user',
              walletBalance: 0.0,
              createdAt: DateTime.now(),
            );
            await dbService.saveUser(newUser);
          }
        }
      } else {
        final credential = await authService.signUp(email: email, password: password);
        // Create user document in Firestore
        if (credential.user != null) {
          final newUser = UserModel(
            id: credential.user!.uid,
            email: email,
            displayName: email.split('@')[0],
            phoneNumber: '',
            role: 'user',
            walletBalance: 0.0,
            createdAt: DateTime.now(),
          );
          await dbService.saveUser(newUser);
        }
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  const SizedBox(height: 60),
                  
                  // Login Card
                  GlassCard(
                    opacity: 0.05,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text(
                            _isLogin ? 'Welcome Back' : 'Create Account',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            _isLogin ? 'Sign in to continue' : 'Sign up to get started',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.3, end: 0),
                          
                          const SizedBox(height: 40),
                          
                          // Email Input
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            delay: 400.ms,
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Input
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            delay: 600.ms,
                          ),
                          const SizedBox(height: 40),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                disabledBackgroundColor: const Color(0xFFCCFF00).withOpacity(0.5),
                                foregroundColor: Colors.black,
                                elevation: 20,
                                shadowColor: const Color(0xFFCCFF00).withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : Text(
                                _isLogin ? 'LOGIN' : 'SIGN UP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8)),

                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? 'Create an account' : 'Already have an account? Login',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuint)
                    .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.1)),
                ],
              ),
            ),
          ),


        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/admin'),
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        elevation: 0,
        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
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
        controller: controller,
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

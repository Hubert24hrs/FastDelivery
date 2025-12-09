import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _obscurePassword = true;

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
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background orbs
          Positioned(
            top: -50,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Floating shapes
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 40,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo with glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Logo container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.grey[300]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                              offset: const Offset(6, 6),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 20),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.bolt,
                          size: 56,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Brand name
                  Text(
                    'FastDelivery',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Powered by Nigerian Speed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Email/Phone Input
                  _buildInputField(
                    label: 'Phone Number or Email',
                    placeholder: '+234 800 000 0000',
                    controller: _emailController,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Input
                  _buildInputField(
                    label: 'Password',
                    placeholder: 'Enter your password',
                    controller: _passwordController,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // OR divider
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                      ),
                      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Biometric Login Button
                  _buildNeomorphicButton(
                    onTap: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.fingerprint, color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Login with Biometrics',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    isPrimary: false,
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // LOGIN Button
                  _buildNeomorphicButton(
                    onTap: _isLoading ? null : _submit,
                    child: _isLoading 
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryForeground),
                        )
                      : Text(
                          _isLogin ? 'LOGIN' : 'SIGN UP',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.primaryForeground,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                    isPrimary: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Forgot Password
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Social Login
                  Text(
                    'Or continue with',
                    style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(Icons.g_mobiledata),
                      const SizedBox(width: 16),
                      _buildSocialButton(Icons.facebook),
                      const SizedBox(width: 16),
                      _buildSocialButton(Icons.apple),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Create Account Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'New to Fast Delivery?',
                          style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin ? 'Create Account' : 'Already have an account? Login',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
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

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.inputColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF18181B).withValues(alpha: 0.8),
                offset: const Offset(0, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              TextField(
                controller: controller,
                obscureText: isPassword && _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(color: AppTheme.mutedForeground),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.mutedForeground,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      )
                    : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeomorphicButton({
    required Widget child,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryColor : AppTheme.secondaryColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: isPrimary
            ? AppTheme.primaryNeomorphicShadow
            : AppTheme.neomorphicShadow(),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF18181B).withValues(alpha: 0.8),
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

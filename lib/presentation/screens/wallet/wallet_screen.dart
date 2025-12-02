import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isCashEnabled = true;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserIdProvider) != null 
        ? ref.watch(databaseServiceProvider).getUser(ref.watch(currentUserIdProvider)!)
        : null;

    return Scaffold(
      backgroundColor: Colors.white, // Matching reference light theme or keep dark? Reference is light. Let's try to adapt to dark or stick to reference. User said "features seen in the first reference image". I'll use a light theme for this screen to match reference closely, or maybe a dark version of it. Let's stick to the AppTheme (Dark) but layout of reference.
      // Actually, the app is dark mode. A stark white screen might look out of place. I will use the AppTheme background but the LAYOUT of the reference.
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'), // Back to Home since it's from Drawer
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fast Delivery balance',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder(
                    future: userAsync,
                    builder: (context, snapshot) {
                      final balance = snapshot.data?.walletBalance ?? 0.0;
                      return Text(
                        '₦${balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'Fast Delivery balance is not available with this payment method',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Help Links
            _buildLinkItem(Icons.help_outline, 'What is Fast Delivery balance?'),
            const SizedBox(height: 16),
            _buildLinkItem(Icons.history, 'See Fast Delivery balance transactions'),
            
            const SizedBox(height: 40),
            
            // Payment Methods Header
            const Text(
              'Payment methods',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Cash Option
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(FontAwesomeIcons.moneyBill, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Cash',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Switch(
                    value: _isCashEnabled,
                    onChanged: (val) => setState(() => _isCashEnabled = val),
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Add Card Option
            InkWell(
              onTap: () {
                // TODO: Implement Add Card
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 24),
                    const SizedBox(width: 16),
                    const Text(
                      'Add debit/credit card',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Work Profile
            InkWell(
              onTap: () {},
              child: Row(
                children: [
                  const Icon(Icons.work_outline, color: Colors.white54),
                  const SizedBox(width: 16),
                  const Text(
                    'Set up work profile',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}

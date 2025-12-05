import 'package:fast_delivery/core/models/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isCashEnabled = true;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final userStream = userId != null 
        ? ref.watch(databaseServiceProvider).getUserStream(userId)
        : const Stream<UserModel?>.empty();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
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
                  StreamBuilder<UserModel?>(
                    stream: userStream,
                    builder: (context, snapshot) {
                      final balance = snapshot.data?.walletBalance ?? 0.0;
                      return Text(
                        '₦${balance.toStringAsFixed(0)}',
                        style: GoogleFonts.roboto(
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
            _buildLinkItem(
              context,
              Icons.help_outline, 
              'What is Fast Delivery balance?',
              () {},
            ),
            const SizedBox(height: 16),
            _buildLinkItem(
              context,
              Icons.history, 
              'See Fast Delivery balance transactions',
              () => context.go('/wallet/transactions'),
            ),
            
            const SizedBox(height: 40),
            
            // Payment Methods Header
            const Text(
              'Payment methods',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(FontAwesomeIcons.moneyBill, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Cash',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  Switch(
                    value: _isCashEnabled,
                    onChanged: (val) => setState(() => _isCashEnabled = val),
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Add Card Option
            InkWell(
              onTap: () => context.go('/wallet/add-card'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.black, size: 24),
                    const SizedBox(width: 16),
                    const Text(
                      'Add debit/credit card',
                      style: TextStyle(color: Colors.black, fontSize: 16),
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
                  const Icon(Icons.work_outline, color: Colors.black54),
                  const SizedBox(width: 16),
                  const Text(
                    'Set up work profile',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

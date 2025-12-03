
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final transactions = [
      {'title': 'Ride Payment', 'date': 'Today, 10:30 AM', 'amount': '-₦1,500', 'isCredit': false},
      {'title': 'Wallet Top Up', 'date': 'Yesterday, 4:15 PM', 'amount': '+₦5,000', 'isCredit': true},
      {'title': 'Courier Service', 'date': 'Dec 1, 2:00 PM', 'amount': '-₦2,200', 'isCredit': false},
      {'title': 'Ride Payment', 'date': 'Nov 28, 9:45 AM', 'amount': '-₦800', 'isCredit': false},
      {'title': 'Wallet Top Up', 'date': 'Nov 25, 11:00 AM', 'amount': '+₦10,000', 'isCredit': true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isCredit = tx['isCredit'] as bool;

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
                color: isCredit ? Colors.green : Colors.red,
                size: 16,
              ),
            ),
            title: Text(
              tx['title'] as String,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              tx['date'] as String,
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Text(
              tx['amount'] as String,
              style: GoogleFonts.roboto(
                color: isCredit ? Colors.green : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}

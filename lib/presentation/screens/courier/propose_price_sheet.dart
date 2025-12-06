import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProposePriceSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const ProposePriceSheet({
    super.key,
    required this.onSave,
  });

  @override
  State<ProposePriceSheet> createState() => _ProposePriceSheetState();
}

class _ProposePriceSheetState extends State<ProposePriceSheet> {
  bool _receiverPays = false;
  String _paymentMethod = 'Cash'; // Cash or Transfer
  final _amountController = TextEditingController();

  void _handleSave() {
    final price = double.tryParse(_amountController.text) ?? 0.0;
    final data = {
      'price': price,
      'paymentMethod': _paymentMethod,
      'receiverPays': _receiverPays,
    };
    widget.onSave(data);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Balance close button
                  const Text(
                    'Propose your price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Amount Input
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    prefixText: 'NGN ',
                    prefixStyle: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                    ),
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white12),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // Payment Method
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.money, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      _paymentMethod,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      color: AppTheme.surfaceColor,
                      onSelected: (value) => setState(() => _paymentMethod = value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'Transfer', child: Text('Transfer', style: TextStyle(color: Colors.white))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Receiver Pays Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receiver settles fee',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'To courier, when package arrives',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  CupertinoSwitch(
                    value: _receiverPays,
                    onChanged: (value) => setState(() => _receiverPays = value),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor, // Lime green
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

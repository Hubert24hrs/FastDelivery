
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteEntrySheet extends StatefulWidget {
  const RouteEntrySheet({super.key});

  @override
  State<RouteEntrySheet> createState() => _RouteEntrySheetState();
}

class _RouteEntrySheetState extends State<RouteEntrySheet> {
  final _toController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Balance the close button
                const Text(
                  'Enter your route',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Location (Read-only)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Prince Samuel Adedoyin St 2', // Mock current location
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // To Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.black),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _toController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'To',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Choose on map
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement map picker
                  },
                  icon: const Icon(Icons.map_outlined, color: Colors.blue),
                  label: const Text(
                    'Choose on map',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

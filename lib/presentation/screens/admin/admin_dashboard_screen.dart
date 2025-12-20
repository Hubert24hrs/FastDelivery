import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/driver_application_model.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const BackgroundOrbs(),
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: StreamBuilder<QuerySnapshot>(
              // CHANGED: Query driver_applications instead of users
              stream: FirebaseFirestore.instance
                  .collection('driver_applications')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pending applications',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    // CHANGED: Use DriverApplicationModel
                    final app = DriverApplicationModel.fromMap(data, docs[index].id);
                    return _buildDriverCard(app);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(DriverApplicationModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white10,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.fullName, // CHANGED: Display Name from App
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${app.vehicleMake} ${app.vehicleModel} (${app.vehicleYear})',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          app.phoneNumber,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(app.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: const Text('DECLINE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDriverDocuments(context, app),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(color: Colors.blueAccent),
                      ),
                      child: const Text('DOCS'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(app.id, 'approved', app),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDriverDocuments(BuildContext context, DriverApplicationModel app) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceColor,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(child: Text('${app.fullName}\'s Documents', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                   IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
               ),
               const SizedBox(height: 16),
               _buildDocItem('License', app.licenseUrl),
               _buildDocItem('Registration', app.registrationUrl),
               _buildDocItem('Insurance', app.insuranceUrl),
               _buildDocItem('Permit (Courier)', app.permitUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocItem(String label, String? url) {
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.white10,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (c, o, s) => Container(
                height: 200,
                color: Colors.red.withValues(alpha: 0.1),
                child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String userId, String status, [DriverApplicationModel? app]) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Update Application Status
      final appRef = FirebaseFirestore.instance.collection('driver_applications').doc(userId);
      batch.update(appRef, {'status': status});

      // 2. If Approved, Update User Role & Details in Users Collection
      if (status == 'approved' && app != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        batch.update(userRef, {
          'role': 'driver',
          // Optionally update other details if you want searchability
          'carModel': '${app.vehicleMake} ${app.vehicleModel}',
          'plateNumber': app.licensePlate,
          // 'status': 'active', // If you use status on user model
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $status successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

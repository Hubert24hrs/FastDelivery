import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:url_launcher/url_launcher.dart';

class CourierTrackingScreen extends ConsumerStatefulWidget {
  final String? courierId;

  const CourierTrackingScreen({super.key, this.courierId});

  @override
  ConsumerState<CourierTrackingScreen> createState() => _CourierTrackingScreenState();
}

class _CourierTrackingScreenState extends ConsumerState<CourierTrackingScreen> {
  // ignore: unused_field - assigned in onMapCreated for potential future use
  mapbox.MapboxMap? _mapboxMap;

  _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.courierId == null) {
      return const Scaffold(body: Center(child: Text('No courier ID provided')));
    }

    final courierStream = ref.watch(databaseServiceProvider).streamCourier(widget.courierId!);

    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          kIsWeb
              ? Container(color: Colors.grey[900])
              : mapbox.MapWidget(
                  key: const ValueKey("courierMapWidget"),
                  onMapCreated: _onMapCreated,
                  styleUri: mapbox.MapboxStyles.DARK,
                  cameraOptions: mapbox.CameraOptions(
                    center: mapbox.Point(coordinates: mapbox.Position(3.3792, 6.5244)),
                    zoom: 13.0,
                  ),
                ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
            ),
          ),

          // Courier Details Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<CourierModel?>(
              stream: courierStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                final courier = snapshot.data;
                if (courier == null) {
                  return GlassCard(
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                    ),
                  );
                }

                return _buildCourierDetailsSheet(courier);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierDetailsSheet(CourierModel courier) {
    final status = courier.status;
    final hasDriver = courier.riderId != null && courier.riderId!.isNotEmpty;

    return GlassCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Status Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusSubtitle(status),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress Indicator
            _buildProgressIndicator(status),
            const SizedBox(height: 24),

            // Package Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.inventory_2, 'Package', courier.packageSize),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.my_location, 'From', courier.pickupAddress),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.flag, 'To', courier.dropoffAddress),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            if (hasDriver)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Call receiver using their phone number
                        final phoneNumber = courier.receiverPhone.replaceAll(RegExp(r'[^\d+]'), '');
                        if (phoneNumber.isNotEmpty) {
                          final uri = Uri.parse('tel:$phoneNumber');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch phone dialer')),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No phone number available')),
                          );
                        }
                      },
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('CALL'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to chat screen with courier ID
                        context.push('/chat', extra: {
                          'recipientId': courier.riderId,
                          'recipientName': 'Dispatch Rider',
                          'courierId': courier.id,
                        });
                      },
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('CHAT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),

            if (!hasDriver && status == 'pending')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Looking for nearby dispatch riders...',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String status) {
    final int step;
    switch (status) {
      case 'pending': step = 0; break;
      case 'accepted': step = 1; break;
      case 'picked_up': step = 2; break;
      case 'delivered': step = 3; break;
      default: step = 0;
    }

    return Row(
      children: [
        _buildProgressStep(0, step, 'Order', Icons.receipt_long),
        _buildProgressLine(step > 0),
        _buildProgressStep(1, step, 'Pickup', Icons.storefront),
        _buildProgressLine(step > 1),
        _buildProgressStep(2, step, 'Transit', Icons.local_shipping),
        _buildProgressLine(step > 2),
        _buildProgressStep(3, step, 'Delivered', Icons.check_circle),
      ],
    );
  }

  Widget _buildProgressStep(int index, int currentStep, String label, IconData icon) {
    final isActive = index <= currentStep;
    final isCurrent = index == currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : Colors.white12,
              shape: BoxShape.circle,
              border: isCurrent ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white38,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      width: 20,
      color: isActive ? AppTheme.primaryColor : Colors.white12,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'picked_up': return AppTheme.primaryColor;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'accepted': return Icons.person;
      case 'picked_up': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      default: return Icons.info;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'pending': return 'Finding Rider';
      case 'accepted': return 'Rider Assigned';
      case 'picked_up': return 'Package in Transit';
      case 'delivered': return 'Delivered!';
      default: return 'Processing';
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'pending': return 'We\'re finding a dispatch rider nearby';
      case 'accepted': return 'Rider is heading to pickup';
      case 'picked_up': return 'Your package is on the way';
      case 'delivered': return 'Successfully delivered';
      default: return 'Please wait';
    }
  }
}

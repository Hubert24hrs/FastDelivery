
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/services/auth_service.dart';
import 'package:fast_delivery/core/services/database_service.dart';
import 'package:fast_delivery/core/services/location_service.dart';
import 'package:fast_delivery/core/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fast_delivery/core/services/ride_service.dart';
import 'package:fast_delivery/core/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ... other providers

final rideServiceProvider = Provider<RideService>((ref) {
  return RideService();
});

final ridesStreamProvider = StreamProvider<List<RideModel>>((ref) {
  return ref.watch(rideServiceProvider).getAvailableRides();
});


// Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

// Auth State
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User ID
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

// Active Requests Streams
final activeRidesProvider = StreamProvider<List<RideModel>>((ref) {
  return ref.watch(databaseServiceProvider).getActiveRides();
});

final activeCouriersProvider = StreamProvider<List<CourierModel>>((ref) {
  return ref.watch(databaseServiceProvider).getActiveCouriers();
});

// Driver Online Status
// Driver Online Status
class DriverStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
  void toggle() => state = !state;
}

final driverOnlineProvider = NotifierProvider<DriverStatusNotifier, bool>(DriverStatusNotifier.new);

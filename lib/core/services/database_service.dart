import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateWalletBalance(String uid, double amount) async {
    await _db.collection('users').doc(uid).update({
      'walletBalance': FieldValue.increment(amount),
    });
  }

  // --- Rides ---
  Future<void> createRideRequest(RideModel ride) async {
    await _db.collection('rides').doc(ride.id).set(ride.toMap());
  }

  Stream<List<RideModel>> getActiveRides() {
    return _db
        .collection('rides')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateRideStatus(String rideId, String status, String driverId) async {
    await _db.collection('rides').doc(rideId).update({
      'status': status,
      'driverId': driverId,
    });
  }

  // --- Couriers ---
  Future<void> createCourierRequest(CourierModel courier) async {
    await _db.collection('couriers').doc(courier.id).set(courier.toMap());
  }

  Stream<List<CourierModel>> getActiveCouriers() {
    return _db
        .collection('couriers')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourierModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateCourierStatus(String courierId, String status, String riderId) async {
    await _db.collection('couriers').doc(courierId).update({
      'status': status,
      'riderId': riderId,
    });
  }
}

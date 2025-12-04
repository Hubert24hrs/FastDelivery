import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/ride_model.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference
  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection('rides');

  // Create a new ride request
  Future<void> createRide(RideModel ride) async {
    await _ridesCollection.doc(ride.id).set(ride.toMap());
  }

  // Stream of available rides (status == 'pending')
  Stream<List<RideModel>> getAvailableRides() {
    return _ridesCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RideModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Update ride status and assign driver
  Future<void> updateRideStatus(
    String rideId, 
    String status, {
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    String? carModel,
    String? plateNumber,
    GeoPoint? driverLocation,
  }) async {
    print('RideService: Updating ride $rideId to status $status');
    final Map<String, dynamic> data = {'status': status};
    
    if (driverId != null) data['driverId'] = driverId;
    if (driverName != null) data['driverName'] = driverName;
    if (driverPhone != null) data['driverPhone'] = driverPhone;
    if (driverPhoto != null) data['driverPhoto'] = driverPhoto;
    if (carModel != null) data['carModel'] = carModel;
    if (plateNumber != null) data['plateNumber'] = plateNumber;
    if (driverLocation != null) data['driverLocation'] = driverLocation;

    await _ridesCollection.doc(rideId).update(data);
  }

  // Stream a specific ride by ID (for tracking)
  Stream<RideModel> streamRide(String rideId) {
    return _ridesCollection.doc(rideId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Ride not found');
      }
      return RideModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Get active ride for user
  Future<RideModel?> getActiveRideForUser(String userId) async {
    try {
      final snapshot = await _ridesCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'arrived', 'in_progress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RideModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
    } catch (e) {
      print('Error getting active ride: $e');
    }
    return null;
  }

  // Get active ride for driver
  Future<RideModel?> getActiveRideForDriver(String driverId) async {
    try {
      final snapshot = await _ridesCollection
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['accepted', 'arrived', 'in_progress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RideModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
    } catch (e) {
      print('Error getting active driver ride: $e');
    }
    return null;
  }
}

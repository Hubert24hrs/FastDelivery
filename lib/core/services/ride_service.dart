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
  Future<void> updateRideStatus(String rideId, String status, {String? driverId}) async {
    print('RideService: Updating ride $rideId to status $status');
    final Map<String, dynamic> data = {'status': status};
    if (driverId != null) {
      data['driverId'] = driverId;
    }
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
}

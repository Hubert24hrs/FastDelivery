import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/services/notification_service.dart';

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

  // Cancel ALL active rides for a user (cleanup utility)
  Future<int> cancelAllActiveRidesForUser(String userId) async {
    int cancelledCount = 0;
    try {
      final snapshot = await _ridesCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'arrived', 'in_progress'])
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'status': 'cancelled'});
        cancelledCount++;
        print('RideService: Cancelled ride ${doc.id}');
      }
    } catch (e) {
      print('Error cancelling all rides: $e');
    }
    return cancelledCount;
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
  // Listen to ride updates and trigger notifications (Client-Side Logic)
  // call this when a user has an active ride
  Stream<RideModel> monitorRideForNotifications(String rideId, NotificationService notificationService) {
    String? lastStatus;
    
    return _ridesCollection.doc(rideId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Ride not found');
      
      final ride = RideModel.fromMap(doc.data()!, doc.id);
      
      // Check for status changes
      if (lastStatus != null && lastStatus != ride.status) {
         _triggerNotificationForStatus(ride.status, notificationService);
      }
      lastStatus = ride.status; // Update tracker
      
      return ride;
    });
  }

  void _triggerNotificationForStatus(String status, NotificationService notificationService) {
    switch (status) {
      case 'accepted':
        notificationService.showLocalNotification(
          title: 'Driver Found!',
          body: 'A driver has accepted your request.',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
      case 'arrived':
        notificationService.showLocalNotification(
          title: 'Driver Arrived',
          body: 'Your driver is waiting at the pickup location.',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
      case 'in_progress':
        notificationService.showLocalNotification(
          title: 'Ride Started',
          body: 'You are on your way to the destination.',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
      case 'completed':
         notificationService.showLocalNotification(
          title: 'Ride Completed',
          body: 'You have arrived safely. Thank you for riding with us!',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
       case 'cancelled':
         notificationService.showLocalNotification(
          title: 'Ride Cancelled',
          body: 'The ride was cancelled.',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
    }
  }
}

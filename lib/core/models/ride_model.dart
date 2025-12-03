import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String userId;
  final String? driverId;
  final GeoPoint pickupLocation;
  final GeoPoint dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final double price;
  final String status; // 'pending', 'accepted', 'ongoing', 'completed', 'cancelled'
  final DateTime createdAt;

  final List<String> stops;
  final List<GeoPoint> stopLocations;

  RideModel({
    required this.id,
    required this.userId,
    this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.price,
    this.status = 'pending',
    required this.createdAt,
    this.stops = const [],
    this.stopLocations = const [],
  });

  factory RideModel.fromMap(Map<String, dynamic> data, String id) {
    return RideModel(
      id: id,
      userId: data['userId'] ?? '',
      driverId: data['driverId'],
      pickupLocation: data['pickupLocation'] as GeoPoint,
      dropoffLocation: data['dropoffLocation'] as GeoPoint,
      pickupAddress: data['pickupAddress'] ?? '',
      dropoffAddress: data['dropoffAddress'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      stops: List<String>.from(data['stops'] ?? []),
      stopLocations: List<GeoPoint>.from(data['stopLocations'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'driverId': driverId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'price': price,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'stops': stops,
      'stopLocations': stopLocations,
    };
  }
}

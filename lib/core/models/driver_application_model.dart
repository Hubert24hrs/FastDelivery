import 'package:cloud_firestore/cloud_firestore.dart';

class DriverApplicationModel {
  final String id; // Same as userId
  final String status; // 'pending', 'approved', 'rejected'
  final String fullName;
  final String phoneNumber;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleYear;
  final String licensePlate;
  final DateTime createdAt;

  DriverApplicationModel({
    required this.id,
    this.status = 'pending',
    required this.fullName,
    required this.phoneNumber,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.licensePlate,
    required this.createdAt,
  });

  factory DriverApplicationModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedCreatedAt;
    try {
      if (data['createdAt'] is Timestamp) {
        parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedCreatedAt = DateTime.parse(data['createdAt']);
      } else {
        parsedCreatedAt = DateTime.now();
      }
    } catch (e) {
      parsedCreatedAt = DateTime.now();
    }

    return DriverApplicationModel(
      id: id,
      status: data['status'] ?? 'pending',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      vehicleMake: data['vehicleMake'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      vehicleYear: data['vehicleYear'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'licensePlate': licensePlate,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

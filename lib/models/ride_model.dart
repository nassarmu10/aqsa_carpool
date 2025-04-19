// lib/models/ride_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String originAddress;      // Human-readable address
  final GeoPoint originLocation;   // GeoPoint for mapping/calculations
  final String destinationAddress; // Human-readable address
  final GeoPoint destinationLocation; // GeoPoint for mapping/calculations
  final DateTime departureTime;
  final int availableSeats;
  final List<String> passengers;
  final List<String> pendingRequests;
  final String? notes;
  final bool isCompleted;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.originAddress,
    required this.originLocation,
    required this.destinationAddress,
    required this.destinationLocation,
    required this.departureTime,
    required this.availableSeats,
    this.passengers = const [],
    this.pendingRequests = const [],
    this.notes,
    this.isCompleted = false,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'],
      driverId: json['driverId'],
      driverName: json['driverName'],
      originAddress: json['originAddress'],
      originLocation: json['originLocation'],
      destinationAddress: json['destinationAddress'],
      destinationLocation: json['destinationLocation'],
      departureTime: (json['departureTime'] as Timestamp).toDate(),
      availableSeats: json['availableSeats'],
      passengers: List<String>.from(json['passengers'] ?? []),
      pendingRequests: List<String>.from(json['pendingRequests'] ?? []),
      notes: json['notes'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'originAddress': originAddress,
      'originLocation': originLocation,
      'destinationAddress': destinationAddress,
      'destinationLocation': destinationLocation,
      'departureTime': Timestamp.fromDate(departureTime),
      'availableSeats': availableSeats,
      'passengers': passengers,
      'pendingRequests': pendingRequests,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }
}

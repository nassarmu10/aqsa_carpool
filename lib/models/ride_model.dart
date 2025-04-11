import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final int availableSeats;
  final double price;
  final List<String> passengers;
  final List<String> pendingRequests;
  final String? notes;
  final bool isCompleted;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.availableSeats,
    required this.price,
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
      origin: json['origin'],
      destination: json['destination'],
      departureTime: (json['departureTime'] as Timestamp).toDate(),
      availableSeats: json['availableSeats'],
      price: json['price'].toDouble(),
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
      'origin': origin,
      'destination': destination,
      'departureTime': Timestamp.fromDate(departureTime),
      'availableSeats': availableSeats,
      'price': price,
      'passengers': passengers,
      'pendingRequests': pendingRequests,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }
}

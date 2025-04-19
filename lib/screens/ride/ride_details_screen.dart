// lib/screens/ride/ride_details_screen.dart
import 'package:aqsa_carpool/screens/ride/ride_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic>? directRouteInfo;
  final Map<String, dynamic>? pickupRouteInfo;
  final String? userRequestLocation;

  const RideDetailsScreen({
    Key? key,
    required this.rideId,
    this.directRouteInfo,
    this.pickupRouteInfo,
    this.userRequestLocation,
  }) : super(key: key);

  @override
  _RideDetailsScreenState createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _rideData;
  bool _isLoading = true;
  bool _isRequestingRide = false;
  bool _isDriver = false;
  bool _isPassenger = false;
  bool _hasPendingRequest = false;

  @override
  void initState() {
    super.initState();
    _loadRideData();
  }

  Future<void> _loadRideData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get ride data
      DocumentSnapshot rideDoc =
          await _firestore.collection('rides').doc(widget.rideId).get();

      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      Map<String, dynamic> rideData = rideDoc.data() as Map<String, dynamic>;

      // Check user's relationship to this ride
      bool isDriver = rideData['driverId'] == currentUser.uid;
      bool isPassenger =
          (rideData['passengers'] as List).contains(currentUser.uid);
      bool hasPendingRequest =
          (rideData['pendingRequests'] as List).contains(currentUser.uid);

      setState(() {
        _rideData = rideData;
        _isDriver = isDriver;
        _isPassenger = isPassenger;
        _hasPendingRequest = hasPendingRequest;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading ride: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading ride details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestRide() async {
    if (_rideData == null) return;

    setState(() {
      _isRequestingRide = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user name from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      // Add user to pending requests
      await _firestore.collection('rides').doc(widget.rideId).update({
        'pendingRequests': FieldValue.arrayUnion([currentUser.uid]),
      });

      // Reload ride data
      await _loadRideData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error requesting ride: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request ride: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRequestingRide = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_rideData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Details')),
        body: const Center(
          child: Text('Ride not found'),
        ),
      );
    }

    DateTime departureTime =
        (_rideData!['departureTime'] as Timestamp).toDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver info
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rideData!['driverName'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDriver ? 'You are the driver' : 'Driver',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ride details
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ride Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.location_on_outlined, 'From',
                        _rideData!['originAddress']),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.location_on, 'To',
                        _rideData!['destinationAddress']),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.calendar_today, 'Date',
                        DateFormat('EEEE, MMM dd, yyyy').format(departureTime)),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.access_time, 'Time',
                        DateFormat('hh:mm a').format(departureTime)),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.event_seat, 'Available Seats',
                        _rideData!['availableSeats'].toString()),
                    const SizedBox(height: 12),
                    // _buildDetailRow(
                    //   Icons.attach_money,
                    //   'Price',
                    //   '${_rideData!['price']} ILS'
                    // ),

                    if (_rideData!['notes'] != null &&
                        _rideData!['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_rideData!['notes']),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_isDriver) {
      int pendingRequestsCount = (_rideData!['pendingRequests'] as List).length;

      return Column(
        children: [
          CustomButton(
            text: 'You are the driver',
            onPressed: () {},
            icon: Icons.drive_eta,
            color: Colors.green,
          ),
          if (pendingRequestsCount > 0) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: 'View $pendingRequestsCount Pending Requests',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RideRequestsScreen(rideId: widget.rideId),
                  ),
                ).then((_) => _loadRideData());
              },
              icon: Icons.people,
              isOutlined: true,
            ),
          ],
        ],
      );
    } else if (_isPassenger) {
      return CustomButton(
        text: 'You are booked on this ride',
        onPressed: () {},
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } else if (_hasPendingRequest) {
      return CustomButton(
        text: 'Request pending',
        onPressed: () {},
        icon: Icons.hourglass_bottom,
        color: Colors.orange,
      );
    } else {
      // Check if there are available seats
      int availableSeats = _rideData!['availableSeats'] ?? 0;

      return _isRequestingRide
          ? const Center(child: CircularProgressIndicator())
          : CustomButton(
              text: availableSeats > 0 ? 'Request Ride' : 'No Seats Available',
              onPressed: availableSeats > 0
                  ? () {
                      _requestRide();
                    }
                  : null,
              icon: availableSeats > 0
                  ? Icons.directions_car
                  : Icons.do_not_disturb,
              color: availableSeats > 0 ? null : Colors.grey,
            );
    }
  }
}

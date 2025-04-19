// lib/screens/my_rides_screen.dart
import 'package:aqsa_carpool/screens/ride/ride_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  _MyRidesScreenState createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _myRides = [];
  List<Map<String, dynamic>> _myBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get rides where user is driver
      QuerySnapshot driverRides = await _firestore
          .collection('rides')
          .where('driverId', isEqualTo: currentUser.uid)
          .orderBy('departureTime', descending: true)
          .get();

      // Get rides where user is passenger
      QuerySnapshot passengerRides = await _firestore
          .collection('rides')
          .where('passengers', arrayContains: currentUser.uid)
          .orderBy('departureTime', descending: true)
          .get();

      List<Map<String, dynamic>> myRides = driverRides.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      List<Map<String, dynamic>> myBookings = passengerRides.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      setState(() {
        _myRides = myRides;
        _myBookings = myBookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading rides: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading rides: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'As Driver'),
            Tab(text: 'As Passenger'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRidesList(_myRides, 'You haven\'t offered any rides yet'),
                _buildRidesList(
                    _myBookings, 'You haven\'t booked any rides yet'),
              ],
            ),
    );
  }

  Widget _buildRidesList(
      List<Map<String, dynamic>> rides, String emptyMessage) {
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRides,
      child: ListView.builder(
        itemCount: rides.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> ride = rides[index];
          DateTime departureTime =
              (ride['departureTime'] as Timestamp).toDate();
          bool isCompleted = ride['isCompleted'] ?? false;
          bool isPast = departureTime.isBefore(DateTime.now());

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RideDetailsScreen(rideId: ride['id']),
                  ),
                ).then((_) => _loadRides());
              },
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ride['originAddress']} to ${ride['destinationAddress']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isCompleted || isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Past',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Departure: ${DateFormat('MMM dd, yyyy - hh:mm a').format(departureTime)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seats: ${ride['availableSeats']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (_tabController.index == 0 &&
                      (ride['pendingRequests'] as List).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(ride['pendingRequests'] as List).length} pending requests',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      ),
    );
  }
}

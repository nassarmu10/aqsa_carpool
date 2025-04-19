// lib/screens/ride/my_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ride_details_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  _MyRequestsScreenState createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get rides where user has pending requests
      QuerySnapshot pendingRides = await _firestore
          .collection('rides')
          .where('pendingRequests', arrayContains: currentUser.uid)
          .orderBy('departureTime')
          .get();

      List<Map<String, dynamic>> requests = pendingRides.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRequest(String rideId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('rides').doc(rideId).update({
        'pendingRequests': FieldValue.arrayRemove([currentUser.uid]),
      });

      // Reload requests
      await _loadRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request canceled'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error canceling request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ride Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> ride = _pendingRequests[index];
                      DateTime departureTime =
                          (ride['departureTime'] as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${ride['origin']} to ${ride['destination']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Driver: ${ride['driverName']}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy - hh:mm a')
                                              .format(departureTime),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'Pending',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _cancelRequest(ride['id']),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: Text('Cancel Request'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RideDetailsScreen(
                                                  rideId: ride['id']),
                                        ),
                                      ).then((_) => _loadRequests());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                    ),
                                    child: Text('View Details'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

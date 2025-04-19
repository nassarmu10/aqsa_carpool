import 'package:aqsa_carpool/screens/ride/create_ride_screen.dart';
import 'package:aqsa_carpool/screens/ride/my_requests_screen.dart';
import 'package:aqsa_carpool/screens/ride/my_rides_screen.dart';
import 'package:aqsa_carpool/screens/ride/search_ride_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  String _userName = 'User';
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    // Only proceed if the widget is still mounted
    if (!mounted) return;

    int count = await _getPendingRequestsCount();

    // Check again before calling setState
    if (mounted) {
      setState(() {
        _pendingRequestsCount = count;
      });
    }
  }

  Future<void> _loadUserName() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        String? name = await _authService.getUserName(user.uid);

        // Check if still mounted before updating state
        if (mounted) {
          setState(() {
            _userName = name ?? 'User';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user name: $e');

      // Check if still mounted before updating state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<int> _getPendingRequestsCount() async {
    try {
      User? currentUser = _authService.getCurrentUser();
      if (currentUser == null) return 0;

      // Get rides where user is driver and has pending requests
      QuerySnapshot pendingRides = await _firestore
          .collection('rides')
          .where('driverId', isEqualTo: currentUser.uid)
          .get();

      int totalPendingRequests = 0;

      for (var doc in pendingRides.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalPendingRequests += (data['pendingRequests'] as List).length;
      }

      return totalPendingRequests;
    } catch (e) {
      print('Error getting pending requests: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Al-Aqsa Carpooling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.search),
          //   label: 'Search',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
      ),
      // floatingActionButton: Stack(
      //   children: [
      //     FloatingActionButton(
      //       backgroundColor: Theme.of(context).primaryColor,
      //       // child: Icon(Icons.add),
      //       // onPressed: () {
      //       //   Navigator.push(
      //       //     context,
      //       //     MaterialPageRoute(
      //       //       builder: (context) => CreateRideScreen(),
      //       //     ),
      //       //   ).then((_) => setState(() {}));
      //       // },
      //     ),
      //     if (_pendingRequestsCount > 0)
      //       Positioned(
      //         right: 0,
      //         top: 0,
      //         child: Container(
      //           padding: EdgeInsets.all(4),
      //           decoration: BoxDecoration(
      //             color: Colors.red,
      //             shape: BoxShape.circle,
      //           ),
      //           child: Text(
      //             _pendingRequestsCount.toString(),
      //             style: TextStyle(
      //               color: Colors.white,
      //               fontSize: 12,
      //               fontWeight: FontWeight.bold,
      //             ),
      //           ),
      //         ),
      //       ),
      //   ],
      // ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      // case 1:
      //   return _buildSearchTab();
      case 1:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $_userName!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'What would you like to do today?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 40),
            // Image.asset(
            //   'assets/car_illustration.png', // Add an illustration image to your assets
            //   height: 180,
            //   fit: BoxFit.contain,
            // ),
            Icon(
              Icons.directions_car,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Offer a Ride',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateRideScreen()),
                );
              },
              icon: Icons.drive_eta,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Find a Ride',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchRideScreen()),
                );
              },
              icon: Icons.search,
              isOutlined: true,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard('Rides Offered', '0'),
                const SizedBox(width: 24),
                _buildStatCard('Rides Taken', '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for rides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search functionality will be implemented soon',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'User Profile',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: CustomButton(
              text: 'Sign Out',
              onPressed: _signOut,
              icon: Icons.logout,
              isOutlined: true,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: CustomButton(
              text: 'My Rides',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyRidesScreen()),
                );
              },
              icon: Icons.directions_car,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: CustomButton(
              text: 'My Requests',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyRequestsScreen()),
                );
              },
              icon: Icons.hourglass_bottom,
              isOutlined: true,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Al-Aqsa Carpooling'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Will implement refresh functionality later
            },
          ),
        ],
      ),
      body: _buildBody(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
      ),
      // // floatingActionButton: FloatingActionButton(
      // //   backgroundColor: Theme.of(context).primaryColor,
      // //   child: const Icon(Icons.add),
      // //   onPressed: () {
      // //     // Will implement ride creation later
      // //   },
      // ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'No rides available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a new ride or search for rides',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: CustomButton(
              text: 'Create a Ride',
              onPressed: () {
                // Will implement ride creation later
              },
              icon: Icons.add,
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
          SizedBox(height: 16),
          Text(
            'Search for rides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
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
          SizedBox(height: 16),
          Text(
            'User Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Profile functionality will be implemented soon',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: CustomButton(
              text: 'Go to Login',
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: Icons.login,
              isOutlined: true,
            ),
          ),
        ],
      ),
    );
  }
}

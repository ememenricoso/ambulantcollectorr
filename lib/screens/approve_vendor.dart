import 'package:ambulantcollector/screens/profile_screen.dart'; // Import ProfileScreen
import 'package:ambulantcollector/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:ambulantcollector/screens/vendor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApproveVendor extends StatefulWidget {
  const ApproveVendor({Key? key}) : super(key: key);

  @override
  _ApproveVendorState createState() => _ApproveVendorState();
}

class _ApproveVendorState extends State<ApproveVendor> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
  String _searchQuery = '';
  int _selectedIndex = 2; // Default to the current screen's index

  void _onItemTapped(int index) {
    if (index != _selectedIndex) { // Avoid unnecessary navigation
      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Vendor(),
            ),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ApproveVendor(),
            ),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Approved Vendors"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Search TextField
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by last name or number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildApprovedUserList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.green,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildBottomNavItem(Icons.person, 'Profile', 0),
            _buildBottomNavItem(Icons.app_registration, 'Registration', 1),
            _buildBottomNavItem(Icons.business, 'Vendors', 2),
            _buildBottomNavItem(Icons.settings, 'Settings', 3),
          ],
        ), // Background color of BottomAppBar
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.white : Colors.transparent, // Background color for selected item
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white, // Icon color for selected item
        ),
      ),
      onPressed: () => _onItemTapped(index),
    );
  }

  Widget _buildApprovedUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersRef.where('status', isEqualTo: 'Approved').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        // Get all approved users from the snapshot
        final approvedUsers = snapshot.data!.docs;

        // Filter the users based on search query
        final filteredUsers = approvedUsers.where((user) {
          final bool matchesQuery = user['last_name'].toString().toLowerCase().contains(_searchQuery) ||
              getNumberFromDocumentId(user.id).contains(_searchQuery);
          return matchesQuery;
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text('No matching results'));
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final number = getNumberFromDocumentId(user.id);
            final first = user['first_name'];
            final last = user['last_name'];
            final String vendorId = user.id; // Get the vendor document ID

            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    // Profile icon with larger size and color background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green, // Color background only for the profile icon
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$last, ${first[0]}.",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 21, 21, 21),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Status: Approved',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    // Number at the top right
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to extract number from document ID
  String getNumberFromDocumentId(String documentId) {
    final parts = documentId.split('_');
    return parts.isNotEmpty ? parts.last : '';
  }

  Widget _createDrawerItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 14, 14, 14)),
      title: Text(text),
      onTap: onTap,
    );
  }
}
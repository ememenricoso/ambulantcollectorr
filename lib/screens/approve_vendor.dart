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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Approved Vendors"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: Icon(Icons.person, size: 50, color: Colors.blueGrey[900]),
                  ),
                  SizedBox(width: 20),
                  Text(
                    'User Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Drawer Body
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _createDrawerItem(
                    icon: Icons.person,
                    text: 'My Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(), // Navigate to ProfileScreen
                        ),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.app_registration,
                    text: 'Registration',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Vendor(),
                        ),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.business,
                    text: 'Vendors',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApproveVendor(),
                        ),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.settings,
                    text: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(), // Navigate to SettingsScreen
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Search TextField
            TextField(
              decoration: InputDecoration(
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
            SizedBox(height: 20),
            Expanded(
              child: _buildApprovedUserList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersRef.where('status', isEqualTo: 'Approved').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: Text('No data available'));
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
          return Center(child: Text('No matching results'));
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
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    // Profile icon with larger size and color background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green, // Color background only for the profile icon
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 15),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$last, ${first[0]}.",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Status: Approved',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    // Number at the top right
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        number,
                        style: TextStyle(
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
      leading: Icon(icon, color: Colors.blueGrey[900]),
      title: Text(text),
      onTap: onTap,
    );
  }
}

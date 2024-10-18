import 'package:ambulantcollector/screens/Daily.dart';
import 'package:ambulantcollector/screens/Friday.dart';
import 'package:ambulantcollector/screens/Saturday.dart';
import 'package:ambulantcollector/screens/Sunday.dart';
import 'package:ambulantcollector/screens/Thursday.dart';
import 'package:ambulantcollector/screens/Tuesday.dart';
import 'package:ambulantcollector/screens/Wednesday.dart';
import 'package:ambulantcollector/screens/approve_vendor.dart'; // Import the ApproveVendor screen
import 'package:ambulantcollector/screens/assignpayment_all.dart';
import 'package:ambulantcollector/screens/monday.dart';
import 'package:ambulantcollector/screens/notifications.dart';
import 'package:ambulantcollector/screens/profile_screen.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:ambulantcollector/screens/vendor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 2; // Default to Dashboard

  final List<Widget> _screens = [
    const Vendor(),
    const AssignPaymentAllScreen(),
    const Dashboard(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

//vendor counts
Future<Map<String, int>> _getVendorCounts() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return {};
  }

  final collectorSnapshot = await FirebaseFirestore.instance
      .collection('ambulant_collector')
      .where('email', isEqualTo: currentUser.email)
      .limit(1)
      .get();

  if (collectorSnapshot.docs.isEmpty) {
    return {};
  }

  final collectorData = collectorSnapshot.docs.first.data();
  final String assignedCollection = collectorData['collector'] ?? '';

  if (assignedCollection.isEmpty) {
    return {};
  }

  // Initialize vendor counts
  final vendorCounts = <String, int>{
    'Daily': 0,
    'Monday': 0,
    'Tuesday': 0,
    'Wednesday': 0,
    'Thursday': 0,
    'Friday': 0,
    'Saturday': 0,
    'Sunday': 0,
    'ALL': 0,
  };

  // Get all approved vendors assigned to the collector
  final allVendorsSnapshot = await FirebaseFirestore.instance
      .collection('approved_vendors')
      .where('status', isEqualTo: 'Approved')
      .where('collector', isEqualTo: assignedCollection)
      .get();

  vendorCounts['ALL'] = allVendorsSnapshot.docs.length;

  // Count daily and each day
  for (var vendorDoc in allVendorsSnapshot.docs) {
    final vendorData = vendorDoc.data();

    // Check for daily assignments, looking for day_assign_1 to day_assign_8
    for (int i = 1; i <= 8; i++) {
      String dayAssign = vendorData['day_assign_$i'] ?? '';

      // Count the assignments for the respective days
      if (dayAssign.isNotEmpty && vendorCounts.containsKey(dayAssign)) {
        vendorCounts[dayAssign] = (vendorCounts[dayAssign] ?? 0) + 1;
      }

      // Specifically handle 'Daily' count
      if (dayAssign == 'Daily') {
        vendorCounts['Daily'] = (vendorCounts['Daily'] ?? 0) + 1;
      }
    }
  }

  return vendorCounts.map((key, value) => MapEntry(key, value));
}



  Widget bottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.green,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.white,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      iconSize: 20,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Vendors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment),
          label: 'Payment',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _selectedIndex == 2
        ? AppBar(
            title: const Text(""),
            flexibleSpace: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.green,
            elevation: 1.0,
          )
        : null,
    body: _selectedIndex == 2
        ? SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELCOME to,',
                            style: TextStyle(fontSize: 24),
                          ),
                          Text(
                            'CarbonRent',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      // Logout Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UnifiedLoginScreen(),
                            ),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.logout, color: Colors.green), // Logout Icon
                            SizedBox(width: 4),
                            Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30), // Added spacing after Logout
                  const Text(
                    'Schedule',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  // Horizontal Scroll for All Vendors and Days of the Week
                  SizedBox(
                    height: 130,
                    child: FutureBuilder<Map<String, int>>(
                      future: _getVendorCounts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final vendorCounts = snapshot.data ?? {};

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 9, // 8 days + 1 for Daily
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            String title;
                            Color textColor = Colors.white;
                            Color iconColor = Colors.white;

                            if (index == 0) {
                              title = 'ALL';
                            } else if (index == 1) {
                              title = 'Daily';
                            } else {
                              title = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][index - 2];
                            }

                            return DashboardCard(
                              icon: Icons.calendar_today,
                              title: title,
                              vendorText: '${vendorCounts[title] ?? 0} ${vendorCounts[title] == 1 ? 'vendor' : 'vendors'}', // Display vendor count
                              color: const Color.fromARGB(255, 38, 108, 41),
                              textColor: textColor,
                              iconColor: iconColor,
                              onTap: () {
                                if (index == 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ApproveVendor(),
                                    ),
                                  );
                                } else if (index == 1) { // Check if the tapped index is for "DAILY"
                                  // Navigate to the Daily screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DailyPage(), // Replace with your actual DailyPage
                                    ),
                                  ); 
                                } else if (index == 2) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MondayPage(),
                                    ),
                                  );
                                } else if (index == 3) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TuesdayPage(),
                                    ),
                                  );
                                } else if (index == 4) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Wednesday(),
                                    ),
                                  );
                                } else if (index == 5) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Thursday(),
                                    ),
                                  );
                                } else if (index == 6) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Friday(),
                                    ),
                                  );
                                } else if (index == 7) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Saturday(),
                                    ),
                                  );
                                } else if (index == 8) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Sunday(),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  // Two cards for Paid and Unpaid with text above
                  const Text(
                    'Payment Status',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 1.5,
                      children: <Widget>[
                        DashboardCard(
                          icon: Icons.check_circle,
                          title: 'PAID',
                          vendorText: '100 vendors',
                          color: const Color.fromARGB(255, 249, 251, 247),
                          textColor: Colors.green,
                          iconColor: Colors.green,
                          onTap: () {
                            /* Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaidVendorsPage(),
                              ),
                            ); */
                          },
                        ),
                        DashboardCard(
                          icon: Icons.cancel,
                          title: 'UNPAID',
                          vendorText: '50 vendors',
                          color: const Color.fromARGB(255, 249, 251, 247),
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () {
                            /* Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UnpaidVendorsPage(),
                              ),
                            ); */
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : _screens[_selectedIndex],
    bottomNavigationBar: bottomNavigationBar(),
  );
}
}

// Updated DashboardCard class
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String vendorText; // New vendorText property
  final Color color;
  final Color textColor;
  final Color iconColor; // Icon color
  final VoidCallback onTap;

  const DashboardCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.vendorText, // Add vendorText
    required this.color,
    required this.textColor,
    required this.iconColor, // Icon color
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 135,
        height: 80,
        decoration: BoxDecoration(
          color: color, // Use background color passed in
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: iconColor), // Use icon color
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Use text color
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  vendorText, // Show vendor count with text
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor, // Use text color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

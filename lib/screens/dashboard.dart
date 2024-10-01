import 'package:ambulantcollector/screens/assignpayment_all.dart';
import 'package:ambulantcollector/screens/notifications.dart';
import 'package:ambulantcollector/screens/profile_screen.dart';
import 'package:ambulantcollector/screens/vendor.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 2; // Default to Dashboard

  // List of screens for bottom navigation, excluding Dashboard
  final List<Widget> _screens = [
    const Vendor(), // Vendors screen
    const AssignPaymentAllScreen(), // Payment screen
    const Dashboard(), // Dashboard screen
    const NotificationsScreen(), // Notifications screen
    const ProfileScreen(), // Profile screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index
    });
  }

  // Bottom Navigation Bar
  Widget bottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color.fromARGB(255, 41, 239, 48),
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
      appBar: _selectedIndex == 2 // Show AppBar only on Dashboard screen
          ? AppBar(
              title: const Text(""), // Empty title to avoid spacing issues
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
              backgroundColor: const Color.fromARGB(255, 31, 232, 37),
              elevation: 1.0,
            )
          : null, // No AppBar for other screens
      body: _selectedIndex == 2 // Show Dashboard content
          ? Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
                children: [
                  // Welcome Text
                  const Text(
                    'WELCOME to,',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'CARBONRENT',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20), // Space after welcome text

                  // Horizontal Scroll for All Vendors and Days of the Week
                  SizedBox(
                    height: 80.0, // Adjust height as needed
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7, // For Monday to Sunday
                      separatorBuilder: (context, index) => const SizedBox(width: 10), // Distance between cards
                      itemBuilder: (context, index) {
                        final day = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'][index];
                        return DashboardCard(
                          icon: Icons.calendar_today,
                          title: day,
                          onTap: () {
                            // Handle day tap
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  // Two cards for Paid and Unpaid with text above
                  const SizedBox(height: 20), // Space above Paid and Unpaid cards
                  const Text(
                    'Payment Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10), // Space between text and cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 1.2, // Adjusted for smaller size
                      children: <Widget>[
                        DashboardCard(
                          icon: Icons.check_circle,
                          title: 'PAID',
                          onTap: () {
                            // Handle Paid tap
                          },
                        ),
                        DashboardCard(
                          icon: Icons.cancel,
                          title: 'UNPAID',
                          onTap: () {
                            // Handle Unpaid tap
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _screens[_selectedIndex], // Show other screens when selected
      bottomNavigationBar: bottomNavigationBar(), // Bottom navigation bar
    );
  }
}

// Assuming you have a DashboardCard widget, make sure it accommodates its contents correctly
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, // Set a fixed width
        height: 60, // Adjusted height for smaller size
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.black),
            const SizedBox(height: 5), // Space between icon and text
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:ambulantcollector/screens/paymentvendor.dart';
import 'package:flutter/material.dart';

class DashboardVendor extends StatefulWidget {
  const DashboardVendor({super.key});

  @override
  _DashboardVendorState createState() => _DashboardVendorState();
}

class _DashboardVendorState extends State<DashboardVendor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: <Widget>[
            DashboardCard(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
    // Navigate to PaymentInfoScreen when the Profile option is tapped
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentInfoScreen()),
    );
              }
            ),
        
            DashboardCard(
              icon: Icons.shopping_cart,
              title: 'Orders',
              onTap: () {
                // Navigate to Orders screen
              },
            ),
            DashboardCard(
              icon: Icons.message,
              title: 'Messages',
              onTap: () {
                // Navigate to Messages screen
              },
            ),
            DashboardCard(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                // Navigate to Settings screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardCard({super.key, 
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 20.0,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 10.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

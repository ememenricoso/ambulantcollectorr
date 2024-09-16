import 'package:ambulantcollector/screens/add_ambulant.dart';
import 'package:ambulantcollector/screens/vendor.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
/*         title: const Text("Dashboard"),
 */        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          children: <Widget>[
            DashboardCard(
              icon: Icons.person,
              title: 'VENDORS',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Vendor()), // Navigate to Vendor screen
                );
              },
            ),
            /* DashboardCard(
              icon: Icons.shopping_cart,
              title: 'VENDORS PAYMENT',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Vendorspayment()), // Navigate to Vendors Payment screen
                );
              }, */
           /*  ), */
            DashboardCard(
              icon: Icons.message,
              title: 'ADD AMBULANT',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAmbulant()), // Navigate to Add Ambulant screen
                );
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

  const DashboardCard({Key? key, 
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

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
              const SizedBox(height: 5.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.0,
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

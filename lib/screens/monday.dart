import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MondayPage extends StatelessWidget {
  final CollectionReference approvedVendorsRef =
      FirebaseFirestore.instance.collection('approved_vendors');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monday Assignments'),
        backgroundColor: Colors.green,
      ),
      body: _buildMondayVendorList(),
    );
  }

  Widget _buildMondayVendorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: approvedVendorsRef.snapshots(),
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

        final vendors = snapshot.data!.docs;
        final mondayVendors = vendors.where((vendor) {
          // Check for fields starting with 'assign_day_' and match 'Monday'
          for (int i = 1; i <= 10; i++) {
            if (vendor['day_assign_$i'] == 'Monday') {
              return true; // Found a match for Monday
            }
          }
          return false; // No match found
        }).toList();

        if (mondayVendors.isEmpty) {
          return const Center(child: Text('No vendors assigned on Monday'));
        }

        return ListView.builder(
          itemCount: mondayVendors.length,
          itemBuilder: (context, index) {
            final vendor = mondayVendors[index];
            final firstName = vendor['first_name'];
            final lastName = vendor['last_name'];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$lastName, $firstName",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Assigned on: Monday',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
}

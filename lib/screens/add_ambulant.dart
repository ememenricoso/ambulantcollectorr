import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddAmbulant extends StatefulWidget {
  const AddAmbulant({Key? key}) : super(key: key);

  @override
  _AddAmbulantState createState() => _AddAmbulantState();
}

class _AddAmbulantState extends State<AddAmbulant> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Table"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: usersRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('NUMBER')),
                  DataColumn(label: Text('EMAIL')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: users.map((user) {
                  final registrationDate = user['registration_date'].toDate().toString().substring(0, 10);
                  final email = user['email'];
                  final status = user['status'] ? 'Paid' : 'Unpaid';
                  final actionLabel = user['status'] ? 'VIEW RECEIPT' : 'Send Notice';
                  final actionColor = user['status'] ? Colors.green : Colors.red;

                  return DataRow(cells: [
                    DataCell(Text(registrationDate)),
                    DataCell(Text(users.indexOf(user).toString().padLeft(2, '0'))),
                    DataCell(Text(email)),
                    DataCell(Text(status)),
                    DataCell(
                      ElevatedButton(
                        onPressed: () {
                          // Handle button press
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                        ),
                        child: Text(actionLabel),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: AddAmbulant(),
  ));
}

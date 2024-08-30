import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'docs_rev.dart';
import 'status.dart';

class Vendor extends StatefulWidget {
  const Vendor({Key? key}) : super(key: key);

  @override
  _VendorState createState() => _VendorState();
}

class _VendorState extends State<Vendor> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vendor Table"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by last name or number',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: ['All', 'Added', 'Under Review', 'Declined', 'Pending'].map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: usersRef.orderBy('created_at').snapshots(), // Sort by 'created_at' in ascending order
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

                  // Get all users from the snapshot
                  final allUsers = snapshot.data!.docs;

                  // Filter the users
                  final filteredUsers = allUsers.where((user) {
                    final bool matchesStatus = _selectedStatus == 'All' || user['status'] == _selectedStatus;
                    final bool matchesQuery = user['last_name'].toString().toLowerCase().contains(_searchQuery) ||
                        getNumberFromDocumentId(user.id).contains(_searchQuery);
                    return matchesStatus && matchesQuery;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(child: Text('No matching results'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('REG. DATE')),
                        DataColumn(label: Text('NUMBER')),
                        DataColumn(label: Text('LASTNAME')),
                        DataColumn(label: Text('FIRSTNAME')),
                        DataColumn(label: Text('ACTION')),
                      ],
                      rows: List<DataRow>.generate(filteredUsers.length, (index) {
                        final user = filteredUsers[index];
                        final date = (user['created_at'] as Timestamp).toDate().toString().substring(0, 10);
                        final number = getNumberFromDocumentId(user.id);
                        final first = user['first_name'];
                        final last = user['last_name'];
                        final String vendorId = user.id; // Get the vendor document ID
                        final String status = user['status'] ?? 'Pending'; // Get the status field from Firestore
                        final bool isStatusPending = status == 'Pending';
                        final bool isStatusUnderReview = status == 'Under Review';
                        final bool isStatusDeclined = status == 'Declined';
                        final bool isStatusAdditionalInfoRequested = status == 'Additional Info Requested';
                        final String actionLabel = isStatusPending
                            ? 'PENDING'
                            : (isStatusUnderReview
                                ? 'UNDER REVIEW'
                                : (isStatusDeclined ? 'DECLINED' : (isStatusAdditionalInfoRequested ? 'ADDITIONAL INFO REQUESTED' : 'ADDED')));
                        final Color actionColor = isStatusPending
                            ? Colors.red
                            : (isStatusUnderReview
                                ? Colors.orange
                                : (isStatusDeclined ? Colors.red : (isStatusAdditionalInfoRequested ? Colors.blue : Colors.green)));

                        return DataRow(cells: [
                          DataCell(Text(date)),
                          DataCell(_highlightText(number)),
                          DataCell(_highlightText(last)),
                          DataCell(Text(first)),
                          DataCell(
                            ElevatedButton(
                              onPressed: isStatusPending
                                  ? () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StatusScreen(vendorId: vendorId),
                                        ),
                                      );
                                    }
                                  : (isStatusUnderReview
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReviewDocsScreen(vendorId: vendorId),
                                            ),
                                          );
                                        }
                                      : (isStatusAdditionalInfoRequested
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => StatusScreen(vendorId: vendorId),
                                                ),
                                              );
                                            }
                                          : null)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: actionColor,
                              ),
                              child: Text(actionLabel),
                            ),
                          ),
                        ]);
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to get document ID as a string
  String getNumberFromDocumentId(String documentId) {
    // Return the document ID directly
    return documentId;
  }

  // Method to highlight matching text
  Widget _highlightText(String text) {
    if (_searchQuery.isEmpty) {
      return Text(text);
    }

    final RegExp regExp = RegExp(RegExp.escape(_searchQuery), caseSensitive: false);
    final Iterable<RegExpMatch> matches = regExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(text);
    }

    final List<TextSpan> spans = <TextSpan>[];
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(backgroundColor: Colors.yellow),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

void main() {
  runApp(MaterialApp(
    home: Vendor(),
  ));
}

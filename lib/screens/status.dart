import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatusScreen extends StatefulWidget {
  final String vendorId;

  const StatusScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Application Detail"),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: usersRef.doc(widget.vendorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error fetching document: ${snapshot.error}');
            return Center(child: Text('Error fetching document'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            print('Document not found with ID: ${widget.vendorId}');
            return Center(child: Text("Application not found"));
          }

          final application = snapshot.data!;
          final applicationData = application.data() as Map<String, dynamic>;
          final contactNumber = applicationData['contact_number'] ?? 'N/A';
          final createdAt = applicationData['created_at']?.toDate().toString() ?? 'N/A';
          final email = applicationData['email'] ?? 'N/A';
          final firstName = applicationData['first_name'] ?? 'N/A';
          final lastName = applicationData['last_name'] ?? 'N/A';
          final status = applicationData['status'] ?? 'N/A';
          final username = applicationData['username'] ?? 'N/A';
          final documents = applicationData.containsKey('documents') ? applicationData['documents'] as List<dynamic> : [];
          final adminMessage = applicationData['admin_message'] ?? '';

          print('Document data: $applicationData');

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("First Name: $firstName", style: TextStyle(fontSize: 18)),
                Text("Last Name: $lastName", style: TextStyle(fontSize: 18)),
                Text("Username: $username", style: TextStyle(fontSize: 18)),
                Text("Email: $email", style: TextStyle(fontSize: 18)),
                Text("Contact Number: $contactNumber", style: TextStyle(fontSize: 18)),
                Text("Created At: $createdAt", style: TextStyle(fontSize: 18)),
                Text("Status: $status", style: TextStyle(fontSize: 18, color: _getStatusColor(status))),
                SizedBox(height: 20),
                if (documents.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Documents:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ...documents.map((doc) => Text(doc.toString(), style: TextStyle(fontSize: 16))),
                    ],
                  ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: status == 'Pending' || status == 'Additional Info Requested'
                          ? () => updateStatus('Approved')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: status == 'Pending' || status == 'Additional Info Requested'
                          ? showRequestAdditionalInfoDialog
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: Text('Request Additional Info'),
                    ),
                    ElevatedButton(
                      onPressed: status == 'Pending' || status == 'Additional Info Requested'
                          ? showDeclineDialog
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text('Decline'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Under Review':
        return Colors.blue;
      case 'Declined':
        return Colors.red;
      case 'Additional Info Requested':
        return Colors.yellow;
      default:
        return Colors.black;
    }
  }

  Future<void> updateStatus(String status, {String? message}) async {
    try {
      print('Updating status to $status with message: $message');
      final docRef = usersRef.doc(widget.vendorId);
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data() as Map<String, dynamic>;

      // Initialize or update the timeline array
      List<dynamic> timeline = data['timeline'] ?? [];

      // Check if the last request is submitted
      if (status == 'Additional Info Requested') {
        if (timeline.isNotEmpty) {
          final lastEntry = timeline.last as Map<String, dynamic>;
          final lastIssubmittedKey = lastEntry.keys.firstWhere(
            (key) => key.startsWith('issubmitted'),
            orElse: () => 'issubmitted0',
          );
          final lastIndex = int.tryParse(lastIssubmittedKey.replaceAll('issubmitted', '')) ?? 0;
          final lastIssubmittedValue = lastEntry[lastIssubmittedKey];
          
          if (lastIssubmittedValue == false) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Previous request has not been submitted yet.')));
            return;
          }
        }
      }

      // Determine the next available issubmitted field index
      int nextIssubmittedIndex = 1;
      if (timeline.isNotEmpty) {
        final lastEntry = timeline.last as Map<String, dynamic>;
        final lastIssubmittedKey = lastEntry.keys.firstWhere(
          (key) => key.startsWith('issubmitted'),
          orElse: () => 'issubmitted0',
        );
        final lastIndex = int.tryParse(lastIssubmittedKey.replaceAll('issubmitted', '')) ?? 0;
        nextIssubmittedIndex = lastIndex + 1;
      }

      // Create the new timeline entry
      final newTimelineEntry = {
        if (status == 'Additional Info Requested') 'issubmitted$nextIssubmittedIndex': false,
        'message': message ?? (status == 'Approved' ? 'CONGRATULATIONS YOUR APPLICATION IS APPROVED!!' : ''),
        'status': status,
        'timestamp': Timestamp.now(),
        'username': data['username'],
      };

      // Add the new entry to the timeline
      timeline.add(newTimelineEntry);

      // Prepare the update data
      final Map<String, dynamic> updateData = {
        'status': status,
        'timeline': timeline,
      };

      await docRef.update(updateData);
      print('Document successfully updated.');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      Navigator.pop(context, 'Status updated to $status');
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status')));
    }
  }

  void showRequestAdditionalInfoDialog() {
    final TextEditingController infoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Request Additional Information'),
          content: TextField(
            controller: infoController,
            decoration: InputDecoration(hintText: 'Enter additional information needed'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final additionalInfo = infoController.text.trim();
                if (additionalInfo.isNotEmpty) {
                  await updateStatus('Additional Info Requested', message: additionalInfo);
                  Navigator.of(context).pop(); // Close the dialog after submission
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Information cannot be empty')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void showDeclineDialog() {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Decline Message'),
          content: TextField(
            controller: messageController,
            decoration: InputDecoration(hintText: 'Enter your message here'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final message = messageController.text.trim();
                if (message.isNotEmpty) {
                  await updateStatus('Declined', message: message);
                  Navigator.of(context).pop(); // Close the dialog after
                  Navigator.of(context).pop(); // Close the dialog after submission
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Message cannot be empty')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Notification',
              style: TextStyle(fontSize: 17, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

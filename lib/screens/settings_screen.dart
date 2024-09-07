import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text("Notifications"),
              subtitle: Text("Manage notification settings"),
              onTap: () {
                // Navigate to notifications settings
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.security),
              title: Text("Security"),
              subtitle: Text("Change password and security settings"),
              onTap: () {
                // Navigate to security settings
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.language),
              title: Text("Language"),
              subtitle: Text("Change language settings"),
              onTap: () {
                // Navigate to language settings
              },
            ),
          ],
        ),
      ),
    );
  }
}

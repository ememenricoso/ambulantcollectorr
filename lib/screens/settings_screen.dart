import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              subtitle: const Text("Manage notification settings"),
              onTap: () {
                // Navigate to notifications settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text("Security"),
              subtitle: const Text("Change password and security settings"),
              onTap: () {
                // Navigate to security settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Language"),
              subtitle: const Text("Change language settings"),
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

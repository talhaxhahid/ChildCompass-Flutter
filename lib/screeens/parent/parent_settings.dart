import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  bool _geofenceNotifications = true;
  bool _chatNotifications = true;
  bool _speedLimitNotifications = true;
  bool _lowBatteryAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF373E4E),
        title: const Text('Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontFamily: "Quantico",
              fontSize: 18,
            )),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildAccountSection(),
            const SizedBox(height: 24),
            _buildNotificationSection(),
            const SizedBox(height: 24),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      color: Colors.indigo.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Handle change password
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Change Email'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Handle change email
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      color: Colors.indigo.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              activeTrackColor: Color(0xFF373E4E),
              title: const Text('Geofence Notifications'),
              subtitle: const Text('Alerts when entering/exiting geofenced areas'),
              value: _geofenceNotifications,
              secondary: const Icon(Icons.fence),
              onChanged: (bool value) {
                setState(() {
                  _geofenceNotifications = value;
                });
                // Add your geofence notification toggle logic here
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              activeTrackColor: Color(0xFF373E4E),
              title: const Text('Chat Notifications'),
              subtitle: const Text('Notifications for new messages'),
              value: _chatNotifications,
              secondary: const Icon(Icons.chat),
              onChanged: (bool value) {
                setState(() {
                  _chatNotifications = value;
                });
                // Add your chat notification toggle logic here
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              activeTrackColor: Color(0xFF373E4E),
              title: const Text('Speed Limit Notifications'),
              subtitle: const Text('Alerts when exceeding speed limits'),
              value: _speedLimitNotifications,
              secondary: const Icon(Icons.speed),
              onChanged: (bool value) {
                setState(() {
                  _speedLimitNotifications = value;
                });
                // Add your speed limit notification toggle logic here
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              activeTrackColor: Color(0xFF373E4E),
              title: const Text('Low Battery Alerts'),
              subtitle: const Text('Notifications when battery is low'),
              value: _lowBatteryAlerts,
              secondary: const Icon(Icons.battery_alert),
              onChanged: (bool value) {
                setState(() {
                  _lowBatteryAlerts = value;
                });
                // Add your low battery alert toggle logic here
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      color: Colors.indigo.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Perform logout logic here
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/parentLogin',
                        (route) => false
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
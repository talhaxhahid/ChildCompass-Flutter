import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildSettingsPermission extends StatefulWidget {
  const ChildSettingsPermission({super.key});

  @override
  State<ChildSettingsPermission> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<ChildSettingsPermission> {
  bool locationPermissionGranted = false;
  bool usagePermissionGranted = false;
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final locationAlwaysStatus = await Permission.locationAlways.status;
    final usagePermission = await UsageStats.checkUsagePermission() ?? false;

    setState(() {
      locationPermissionGranted = locationStatus.isGranted && locationAlwaysStatus.isGranted;
      usagePermissionGranted = usagePermission;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final bgStatus = await Permission.locationAlways.request();
      if (bgStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions granted')),
        );
      }
    } else {
      if (await Permission.location.isPermanentlyDenied) {
        _showPermissionDeniedDialog('Location');
      }
    }
    await _checkPermissions();
  }

  Future<void> _requestUsagePermission() async {
    final hasPermission = await UsageStats.checkUsagePermission() ?? false;
    if (!hasPermission) {
      await UsageStats.grantUsagePermission();
      // Wait a moment for the system to update
      await Future.delayed(const Duration(seconds: 1));
    }
    final newPermissionStatus = await UsageStats.checkUsagePermission() ?? false;
    if (!newPermissionStatus) {
      _showPermissionDeniedDialog('Usage Stats');
    }
    await _checkPermissions();
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Denied'),
        content: Text(
            'The $permissionName permission was permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This will erase all your data and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // Stop background service
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
           service.invoke('stopService');
        }

        // Clear Hive data
        await Hive.deleteFromDisk();

        // Clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Navigate to onboarding screen
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context,
              '/onBoardingScreen',
                  (route) => false
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Permissions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPermissionTile(
              icon: Icons.location_on,
              title: 'Location Permission',
              isGranted: locationPermissionGranted,
              onRequest: _requestLocationPermission,
            ),
            const SizedBox(height: 16),
            _buildPermissionTile(
              icon: Icons.analytics,
              title: 'Usage Permission',
              isGranted: usagePermissionGranted,
              onRequest: _requestUsagePermission,
            ),
            const SizedBox(height: 16),
            _buildServiceStatusTile(),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Delete Account'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Card(

      child: ListTile(


          onTap:  (!isGranted)?onRequest:()=>{},
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        subtitle: Text(
          isGranted ? 'Granted' : 'Not granted',
          style: TextStyle(color: isGranted ? Colors.green : Colors.red),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isGranted ? Icons.check_circle : Icons.error,
              color: isGranted ? Colors.green : Colors.red,
            )
            // ,
            // if (!isGranted)
            //   TextButton(
            //     onPressed: onRequest,
            //     child: const Text('Grant Permission'),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusTile() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.settings_backup_restore, size: 32),
        title: const Text('Background Service', style: TextStyle(fontSize: 18)),
        subtitle: Text(
          _isServiceRunning ? 'Running' : 'Stopped',
          style: TextStyle(color: _isServiceRunning ? Colors.green : Colors.red),
        ),
        trailing: Icon(
          _isServiceRunning ? Icons.check_circle: Icons.error,
          color: _isServiceRunning ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';

class AppUsageApp extends StatefulWidget {
  @override
  AppUsageAppState createState() => AppUsageAppState();
}

class AppUsageAppState extends State<AppUsageApp> {
  List<AppUsageInfo> appUsageList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAppUsageData();
  }

  Future<void> _fetchAppUsageData() async {
    try {
      // Request permission if not already granted
      bool hasPermission = await UsageStats.checkUsagePermission() ?? false;
      if (!hasPermission) {
        await UsageStats.grantUsagePermission();
      }

      // Set time range (last 24 hours)
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(hours: 24));

      // Query usage stats
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);

      // Create a map to aggregate usage time by package name
      Map<String, AppUsageInfo> appUsageMap = {};

      for (var info in usageStats) {
        if (info.packageName == null || info.totalTimeInForeground == null) continue;

        int timeInForeground = int.tryParse(info.totalTimeInForeground!) ?? 0;
        if (timeInForeground <= 0) continue;

        int lastTimeUsed = int.tryParse(info.lastTimeUsed ?? '0') ?? 0;

        // If we already have this app in our map, add to its time
        if (appUsageMap.containsKey(info.packageName)) {
          appUsageMap[info.packageName!] = AppUsageInfo(
            packageName: info.packageName!,
            appName: appUsageMap[info.packageName]!.appName,
            totalTimeInForeground: appUsageMap[info.packageName]!.totalTimeInForeground + timeInForeground,
            lastTimeUsed: lastTimeUsed > appUsageMap[info.packageName]!.lastTimeUsed
                ? lastTimeUsed
                : appUsageMap[info.packageName]!.lastTimeUsed,
          );
        } else {
          // First time seeing this app
          appUsageMap[info.packageName!] = AppUsageInfo(
            packageName: info.packageName!,
            appName: _getAppName(info.packageName),
            totalTimeInForeground: timeInForeground,
            lastTimeUsed: lastTimeUsed,
          );
        }
      }

      // Convert map values to list and sort by usage time
      List<AppUsageInfo> aggregatedList = appUsageMap.values.toList();
      aggregatedList.sort((a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));

      setState(() {
        appUsageList = aggregatedList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching usage data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Helper method to get app name from package name
  String _getAppName(String? packageName) {
    if (packageName == null) return 'Unknown';

    // Remove common package prefixes
    String name = packageName
        .replaceAll('com.android.', '')
        .replaceAll('com.google.', '')
        .replaceAll('com.', '')
        .replaceAll('org.', '')
        .replaceAll('io.', '');

    // Capitalize first letters of each word
    return name.split('.').map((s) => s.isNotEmpty
        ? s[0].toUpperCase() + s.substring(1)
        : '').join(' ');
  }

  // Format milliseconds to readable time
  String _formatDuration(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";
    } else {
      return "${duration.inSeconds}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Usage Statistics"),
        actions: [
          IconButton(
            onPressed: _fetchAppUsageData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: UsageStats.grantUsagePermission,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : RefreshIndicator(
        onRefresh: _fetchAppUsageData,
        child: ListView.builder(
          itemCount: appUsageList.length,
          itemBuilder: (context, index) {
            final app = appUsageList[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(app.appName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Package: ${app.packageName}'),
                    const SizedBox(height: 4),
                    Text('Usage Time: ${_formatDuration(app.totalTimeInForeground)}'),
                    Text('Last Used: ${DateTime.fromMillisecondsSinceEpoch(app.lastTimeUsed).toString().substring(0, 16)}'),
                  ],
                ),
                leading: const Icon(Icons.apps),
                trailing: Text(
                  '${(app.totalTimeInForeground / 3600000).toStringAsFixed(1)}h',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppUsageInfo {
  final String packageName;
  final String appName;
  final int totalTimeInForeground; // in milliseconds
  final int lastTimeUsed; // timestamp in milliseconds

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
  });
}
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:childcompass/core/api_constants.dart';
import 'package:childcompass/services/child/child_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:battery_plus/battery_plus.dart';

class ChildAppUsage {
  List<Map<String, dynamic>> appUsageList = [];
  String errorMessage = '';
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  String? childId;
  String? childName;
  bool permissionNotification=false;

  Future<void> LogAppUseage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('connectionString');
    childName = prefs.getString('childName');

    _batteryLevel = await _battery.batteryLevel;
    await _fetchAppUsageData();
    childApiService.logAppUsage(
      connectionString: childId ?? "null",
      appUsage: appUsageList.sublist(0, appUsageList.length > 10 ? 10 : appUsageList.length),
      battery: _batteryLevel,
    );

    Timer.periodic(const Duration(minutes: 10), (Timer timer) async {
      _batteryLevel = await _battery.batteryLevel;
      await _fetchAppUsageData();
      childApiService.logAppUsage(
        connectionString: childId ?? "null",
        appUsage: appUsageList.sublist(0, appUsageList.length > 5 ? 5 : appUsageList.length),
        battery: _batteryLevel,
      );
    });
  }

  Future<void> _fetchAppUsageData() async {
    try {
      // Request permission if not already granted
      bool hasPermission = await UsageStats.checkUsagePermission() ?? false;
      if (!hasPermission) {
        if(permissionNotification==false){
        http.get(Uri.parse('${ApiConstants.permissionIssue}/${childId}/Your%20Child ${childName}%20revoked%20App%20Useage%20Permsissions.'));
        permissionNotification=true;
        }
        await UsageStats.grantUsagePermission();
        return;
      }
      if(permissionNotification==true){
        http.get(Uri.parse('${ApiConstants.permissionIssue}/${childId}/Your%20Child%20${childName}%20granted%20App%20Useage%20Permsissions.'));
      permissionNotification=false;}

      // Set time range (last 24 hours)
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(hours: 24));

      // Query usage stats
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);

      // Create a map to aggregate usage time by package name
      Map<String, Map<String, dynamic>> appUsageMap = {};

      for (var info in usageStats) {
        if (info.packageName == null || info.totalTimeInForeground == null) continue;

        int timeInForeground = int.tryParse(info.totalTimeInForeground!) ?? 0;
        if (timeInForeground <= 0) continue;

        int lastTimeUsed = int.tryParse(info.lastTimeUsed ?? '0') ?? 0;

        // If we already have this app in our map, add to its time
        if (appUsageMap.containsKey(info.packageName)) {
          appUsageMap[info.packageName!] = {
            'packageName': info.packageName!,
            'totalTimeInForeground': appUsageMap[info.packageName!]!['totalTimeInForeground'] + timeInForeground,
            'lastTimeUsed': lastTimeUsed > appUsageMap[info.packageName!]!['lastTimeUsed']
                ? lastTimeUsed
                : appUsageMap[info.packageName!]!['lastTimeUsed'],
          };
        } else {
          // First time seeing this app
          appUsageMap[info.packageName!] = {
            'packageName': info.packageName!,
            'totalTimeInForeground': timeInForeground,
            'lastTimeUsed': lastTimeUsed,
          };
        }
      }

      // Convert map values to list and sort by usage time
      List<Map<String, dynamic>> aggregatedList = appUsageMap.values.toList();
      aggregatedList.sort((a, b) => (b['totalTimeInForeground'] as int).compareTo(a['totalTimeInForeground'] as int));
      appUsageList = aggregatedList;

    } catch (e) {
      errorMessage = 'Error fetching usage data: ${e.toString()}';
    }
  }
}
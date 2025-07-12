import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';
import '../../core/api_constants.dart';
import '../../core/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/child/child_background_service.dart';
import '../../services/child/child_location_service.dart';
import 'package:childcompass/screeens/child/child_taskscreen.dart';
import '../../services/child/child_api_service.dart';
import '../../services/parent/parent_api_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../mutual/messageScreen.dart';

class childDashboard extends StatefulWidget {
  @override
  _childDashboardState createState() => _childDashboardState();
}

class _childDashboardState extends State<childDashboard> {
  var childName;
  var childCode;
  var parent;

  @override
  void initState() {
    super.initState();
    //ChildBackgroundService();
    _requestPermissions();
    getChildData();
  }

  void getChildData() async {
    print("IN CHILDS DASHBOARD");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childName = prefs.get('childName');
    childCode = prefs.get('connectionString');
    parent = await parentApiService().getParentsByConnection(childCode);
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    try {
      // Request permissions
      final granted = await permissions.grantRequiredPermissions();

      if (!granted) {
        print('Required permissions not granted');
        Timer.periodic(Duration(seconds: 3), (Timer timer) async {
          final locationStatus = await Permission.location.status;
          final locationAlwaysStatus = await Permission.locationAlways.status;
          final usagePermission = await UsageStats.checkUsagePermission() ?? false;
          if(locationStatus.isGranted && locationAlwaysStatus.isGranted && usagePermission){
            final service = FlutterBackgroundService();
            final isRunning = await service.isRunning();

            if (!isRunning) {
              print('Starting background service...');
              ChildBackgroundService();
              print('Background service started successfully');
            } else {
              print('Background service is already running');
            }
            timer.cancel();
          }
        });
      }else{

        // Check service status
        final service = FlutterBackgroundService();
        final isRunning = await service.isRunning();

        if (!isRunning) {
          print('Starting background service...');
          ChildBackgroundService();
          print('Background service started successfully');
        } else {
          print('Background service is already running');
        }}
    } catch (e) {
      print('Error in _requestPermissions: $e');
      // You might want to show an error message to the user here
    }
  }

  @override
  Widget build(BuildContext context) {
    print("In Child Build");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF373E4E),
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hi, $childName',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: "Quantico",
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {

                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.refresh, color: Colors.white),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/childCode',
                      arguments: {'connectionString': childCode},
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.person_add_alt_1_outlined,
                        color: Colors.white),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/childSettingsPermission',

                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.settings_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChildTaskscreen(),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                // SOS Button - 70%
                Expanded(
                  flex: 7,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      WebSocketChannel? channel = IOWebSocketChannel.connect(ApiConstants.sosAlertSocket);
                      channel!.sink.add(jsonEncode({
                        'type': 'sos',
                        'childId':childCode
                      }));
                      childApiService.sosAlert(connectionString: childCode);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2400), // Scarlet Red
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.error_outline, color: Colors.white),
                    label: const Text(
                      "SOS",
                      style: TextStyle(color: Colors.white,fontFamily: "Quantico"),
                    ),
                  ),
                ),
                const SizedBox(width: 10), // spacing between buttons

                // Chat Button - 30%
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {

                      if(parent.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("No Parent Connected...")),
                        );
                      }else{
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              currentUserName: childName,
                              currentUserId: childCode,
                              otherUserId: parent[0]['email'],
                              otherUserName: parent[0]['name'],
                            ),
                          ),
                        );}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text(
                      "Chat",
                      style: TextStyle(color: Colors.white,fontFamily: "Quantico"),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),

    );
  }
}

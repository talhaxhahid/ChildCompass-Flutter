import 'package:flutter/material.dart';
import '../../core/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/child/child_background_service.dart';
import '../../services/child/child_location_service.dart';
import 'package:childcompass/screeens/child/child_taskscreen.dart';

import '../../services/parent/parent_api_service.dart';
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
    ChildBackgroundService();
    _requestPermissions();
    getChildData();
  }

  void getChildData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childName = prefs.get('childName');
    childCode = prefs.get('connectionString');
    parent = await parentApiService().getParentsByConnection(childCode);
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    await permissions.requestLocationPermissions();
  }

  @override
  Widget build(BuildContext context) {
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
                    // Navigator.pushNamed(context, '/childSettings');
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
                      print("SOS Pressed");
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

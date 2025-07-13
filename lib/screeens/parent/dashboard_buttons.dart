import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_constants.dart';
import '../../provider/parent_provider.dart';
import '../mutual/messageScreen.dart';
import 'package:http/http.dart' as http;
class ParentDashboardButton extends ConsumerStatefulWidget {
  const ParentDashboardButton({super.key});

  @override
  ConsumerState<ParentDashboardButton> createState() => _ParentDashboardButtonState();
}

class _ParentDashboardButtonState extends ConsumerState<ParentDashboardButton> {

  int UnreadCount=0;

  Future<void> GetUnreadCount() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.messaging}unread-count/${ref.read(parentEmailProvider)}/${ref.read(currentChildProvider)}_${ref.read(parentEmailProvider)}'),
    );
    print(response.body);
    final data = json.decode(response.body);
    UnreadCount=data['count'];

    setState(() {

    });

  }
  @override
  void initState() {
    super.initState();

    _setupFCM();
  }
  Future<void> _setupFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['chatId'] == '${ref.read(currentChildProvider)}_${ref.read(parentEmailProvider)}') {
        UnreadCount++;
        setState(() {

        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentChildProvider, (previous, next) {
      setState(() {
        UnreadCount=0;
        GetUnreadCount();
      });


    });
    return Center(
      child: Wrap(
         spacing: MediaQuery.of(context).size.width * 0.03,
         runSpacing: 12,

        alignment: WrapAlignment.spaceBetween,
        children: [
          // Speed Widget
          InkWell(
            onTap: (){

              Navigator.pushNamed(context, '/SetSpeedLimit');
            },
            child: FractionallySizedBox(
              widthFactor: 0.65,
              child: Container(
                // width: 240,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children:  [
                        Icon(Icons.speed, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(ref.watch(speedProvider).toString()+" km/hr", style: TextStyle(color: Colors.white, fontSize: 16,fontFamily: "Quantico",)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.white),
                    Text("Max\n"+ref.watch(maxSpeedProvider).toString()+" km/hr", style: TextStyle(color: Colors.white, fontSize: 14,fontFamily: "Quantico",)),
                  ],
                ),
              ),
            ),
          ),

          // Chat Button
          FractionallySizedBox(
          widthFactor: 0.25,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserName: ref.read(parentNameProvider)!,
                          currentUserId: ref.read(parentEmailProvider)!,
                          otherUserId: ref.read(currentChildProvider)!,
                          otherUserName: ref.read(connectedChildsNameProvider)![ref.read(currentChildProvider)],
                        ),
                      ),
                    );
                    UnreadCount=0;
                    setState(() {

                    });
                  },
                  child: Container(
                    // width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                // Unread count badge
                 UnreadCount>0?Positioned(
                  right: 3,
                  top: 3,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red, // Badge color
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      UnreadCount.toString(), // Replace with your actual unread count
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ):Container(width: 1,height: 1,),
              ],
            ),
          ),

          // Battery Button
          FractionallySizedBox(
            widthFactor: 0.30,
            child: Container(
              // width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children:  [
                  _getBatteryIcon(ref.watch(batteryProvider)!),
                  SizedBox(width: 10),
                  Text(ref.watch(batteryProvider).toString()+"%", style: TextStyle(color: Colors.white, fontSize: 16,fontFamily: "Quantico",)),
                ],
              ),
            ),
          ),

          // Geo-fence Button
          FractionallySizedBox(
            widthFactor: 0.60,
            child: GestureDetector(
              onTap: (){
                Navigator.pushNamed(context, '/GeofenceListScreen');
              },
              child: Container(
                // width: 220,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6F78),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.location_on_outlined, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "Geo-fence Locations",
                      style: TextStyle(color: Colors.white, fontSize: 14,fontFamily: "Quantico",),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Child Tasks Button
          FractionallySizedBox(
            widthFactor: 0.65,
            child: GestureDetector(
              onTap: (){
                Navigator.pushNamed(context, '/parentTaskScreen');
              },
              child: Container(

                // width: 240,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.checklist_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text("Manage Child Tasks", style: TextStyle(color: Colors.white, fontSize: 15,fontFamily: "Quantico",)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          // Settings Button
          FractionallySizedBox(
            widthFactor: 0.25,
            child: GestureDetector(
              onTap: ()=>{Navigator.pushNamed(context, '/parentEndChildSettings')},
              child: Container(
                // width: 100,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Helper function to get the appropriate battery icon
Icon _getBatteryIcon(String battery) {
  var batteryPercent =int.parse(battery);
  if (batteryPercent >= 90) return const Icon(Icons.battery_full_rounded, color: Colors.white, size: 28);
  if (batteryPercent >= 70) return const Icon(Icons.battery_6_bar_rounded, color: Colors.white, size: 28);
  if (batteryPercent >= 50) return const Icon(Icons.battery_5_bar_rounded, color: Colors.white, size: 28);
  if (batteryPercent >= 30) return const Icon(Icons.battery_4_bar_rounded, color: Colors.white, size: 28);
  if (batteryPercent >= 15) return const Icon(Icons.battery_3_bar_rounded, color: Colors.white, size: 28);
  if (batteryPercent >= 5) return const Icon(Icons.battery_2_bar_rounded, color: Colors.white, size: 28);
  if (batteryPercent > 0) return const Icon(Icons.battery_1_bar_rounded, color: Colors.white, size: 28);
  return const Icon(Icons.battery_0_bar_rounded, color: Colors.red, size: 28);
}
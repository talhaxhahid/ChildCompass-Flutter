import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/parent_provider.dart';
import '../mutual/messageScreen.dart';
class ParentDashboardButton extends ConsumerStatefulWidget {
  const ParentDashboardButton({super.key});

  @override
  ConsumerState<ParentDashboardButton> createState() => _ParentDashboardButtonState();
}

class _ParentDashboardButtonState extends ConsumerState<ParentDashboardButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Speed Widget
          Container(
            width: 240,
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

          // Chat Button
          GestureDetector(
            onTap: (){
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
            },
            child: Container(
              width: 100,
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

          // Battery Button
          Container(
            width: 120,
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

          // Geo-fence Button
          GestureDetector(
            onTap: (){
              Navigator.pushNamed(context, '/GeofenceListScreen');
            },
            child: Container(
              width: 220,
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

          // Child Tasks Button
          GestureDetector(
            onTap: (){
              Navigator.pushNamed(context, '/parentTaskScreen');
            },
            child: Container(

              width: 240,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.checklist_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text("Child Tasks", style: TextStyle(color: Colors.white, fontSize: 15,fontFamily: "Quantico",)),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.white),
                  const Text("Complete\n3 / 5",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12,fontFamily: "Quantico",)),
                ],
              ),
            ),
          ),

          // Settings Button
          GestureDetector(
            onTap: ()=>{Navigator.pushNamed(context, '/parentEndChildSettings')},
            child: Container(
              width: 100,
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
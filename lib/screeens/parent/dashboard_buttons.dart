import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/parent_provider.dart';
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
              Navigator.pushNamed(context, '/appUseage');
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
              children: const [
                Icon(Icons.battery_5_bar_rounded, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text("37%", style: TextStyle(color: Colors.white, fontSize: 16,fontFamily: "Quantico",)),
              ],
            ),
          ),

          // Geo-fence Button
          Container(
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

          // Child Tasks Button
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

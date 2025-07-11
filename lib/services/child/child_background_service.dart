import 'dart:async';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'childActiveStatusService.dart';
import 'child_appUseage_service.dart';
import 'child_location_service.dart';


Future<void> ChildBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {

  print("IN CHILD BACKGROUND service");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var user = prefs.get('user');
  if(user=='child'){
  startSharingLocation();
  ChildActiveStatusService().start();
  ChildAppUsage().LogAppUseage();
  }
  else{
    Timer.periodic(Duration(seconds: 1), (timer) async {
      print('Hello from SOS service');

    });
    // FlutterRingtonePlayer().play(
    //     fromAsset: "assets/audio/sos.mp3",
    //     looping: true, // or false depending on your need
    //     volume: 1.0,
    //     asAlarm: true
    // );

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //
    //   if (message.data['type'] == 'sos_alert') {
    //     print("SOSSS ALERT HIT");
    //
    //
    //   }
    // });
  }



  service.on("stopService").listen((event) {
    service.stopSelf();
  });
  service.on("task").listen((event) {
    print("Background task running...");
  });
}
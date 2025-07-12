import 'dart:async';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../parent/sos_service.dart';
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
  else if(user=='parent'){
    SosService().start();
  }
  else{
    service.stopSelf();
  }



  service.on("stopService").listen((event) {
    service.stopSelf();
  });
  service.on("task").listen((event) {
    print("Background task running...");
  });
}
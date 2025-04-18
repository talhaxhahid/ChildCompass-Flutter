import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'childActiveStatusService.dart';
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
void onStart(ServiceInstance service) {

  startSharingLocation();
  ChildActiveStatusService().start();


  service.on("stopService").listen((event) {
    service.stopSelf();
  });
  service.on("task").listen((event) {
    print("Background task running...");
  });
}
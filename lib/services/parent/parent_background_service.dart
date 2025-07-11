// import 'dart:async';
// import 'package:flutter_background_service/flutter_background_service.dart';
//
// Future<void> initializeSosService() async {
//   final service = FlutterBackgroundService();
//
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'sos_service_channel', // Required for foreground
//       initialNotificationTitle: 'SOS Service',      // Required for foreground
//       initialNotificationContent: 'Running in background', // Required
//       foregroundServiceNotificationId: 1,           // Required (must be > 0)
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
//
//   if (await service.isRunning()) {
//     service.startService(); // Ensure service starts only if not already running
//   }
// }
//
// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   // Required for iOS background execution
//   return true;
// }
//
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) {
//   // Required for Android foreground service
//   if (service is AndroidServiceInstance) {
//     service.setAsForegroundService();
//   }
//
//
//
//   service.on("stopService").listen((event) {
//
//     service.stopSelf(); // Stop the service
//   });
//
//   service.on("task").listen((event) {
//     print("Background task running...");
//   });
// }
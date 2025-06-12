import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/services.dart';

/// Initialize and start the background service
Future<void> ParentBackgroundService() async {
  final service = FlutterBackgroundService();

  // Configure the service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'sos_background_service',
      initialNotificationTitle: 'SOS Alert Service',
      initialNotificationContent: 'Monitoring for emergency alerts',
      foregroundServiceNotificationId: 888, // Unique ID
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  // Check if service is already running
  if (await service.isRunning()) {
    service.invoke('update');
  } else {
    await service.startService();
  }
}

/// Background service entry point
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Ensure Flutter plugins are initialized
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // For Android, set up foreground notification
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "SOS Alert Service",
      content: "Ready to receive alerts",
    );
  }

  // Initialize components
  try {
    await setupFirebaseMessaging(service);

    // Periodic task example (optional)
    Timer.periodic(Duration(seconds: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "SOS Alert Service",
          content: "Last active: ${DateTime.now()}",
        );
      }

      service.invoke('update');
    });
  } catch (e) {
    print("Service initialization error: $e");
  }

  // Setup service listeners
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('playAlarm').listen((event) async {
    await playSosAlarm();
  });
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await setupFirebaseMessaging(service);
  return true;
}

/// Configure Firebase Messaging
Future<void> setupFirebaseMessaging(ServiceInstance service) async {
  try {
    // Request permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configure how notifications are displayed when app is in foreground
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Notification received: ${message.data}");

      if (message.data['type'] == 'sos_alert') {
        await playSosAlarm();

        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "EMERGENCY ALERT",
            content: "SOS signal received!",
          );
        }
      }
    });

    // Handle notification when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      FlutterRingtonePlayer().stop();
    });

  } catch (e) {
    print("Firebase Messaging error: $e");
    rethrow;
  }
}

/// Play SOS alarm with error handling
Future<void> playSosAlarm() async {
  try {
    await FlutterRingtonePlayer().stop(); // Stop any existing playback

    await FlutterRingtonePlayer().play(
      android: AndroidSounds.alarm,
      ios: IosSounds.alarm,
      fromAsset: "assets/audio/sos.mp3",
      looping: true,
      volume: 1.0,
      asAlarm: true,
    );

    print("SOS alarm played successfully");
  } catch (e) {
    print("Error playing SOS alarm: $e");

    // Fallback to default alarm if custom sound fails
    try {
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (e) {
      print("Fallback alarm also failed: $e");
    }
  }
}
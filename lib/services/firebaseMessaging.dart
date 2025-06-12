import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'messages_channel';
  static const String _channelName = 'Messages Notifications';
  static const String _channelDesc = 'Notifications for new messages';

  // Initialize the service
  Future<void> initialize() async {
    await _setupNotificationChannels();
    await _requestNotificationPermissions();
    await _initializeNotifications();
    _setupMessageHandlers();
    setupFirebaseMessaging();

    // Get and print token for testing
    final String? token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');
  }

  void setupFirebaseMessaging() {

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'sos_alert') {
        print("SOSSS ALERT HIT");

        FlutterRingtonePlayer().play(
            fromAsset: "assets/audio/sos.mp3",
          looping: true, // or false depending on your need
          volume: 1.0,
          asAlarm: true
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle when the user taps the notification
      FlutterRingtonePlayer().stop();

    });
  }

  // Set up notification channels (required for Android 8.0+)
  Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    try {
      final NotificationSettings settings =
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: null, // You can add iOS settings here if needed
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle when a notification is tapped
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }

  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _showNotification(message);
    });

    // Background/terminated messages when opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background message: ${message.messageId}');
      _handleMessageNavigation(message);
    });

    // Corrected: Access getInitialMessage through the instance
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state with message: ${message.messageId}');
        _handleMessageNavigation(message);
      }
    });
  }

  // Show notification
  void _showNotification(RemoteMessage message) {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            icon: android.smallIcon,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            color: Colors.blue,
            styleInformation: BigTextStyleInformation(notification.body ?? ''),
          ),
        ),
        payload: message.data['route'], // Can be used for navigation
      );
    }
  }

  // Handle message navigation
  void _handleMessageNavigation(RemoteMessage message) {
    // Implement your navigation logic here based on message data
    final String? route = message.data['route'];
    if (route != null) {
      debugPrint('Should navigate to: $route');
      // Example: Navigator.pushNamed(context, route);
    }
  }

  // Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
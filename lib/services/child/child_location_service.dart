import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';

Stream<Position> getLiveLocation() {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10, // meters
    ),
  );
}

IOWebSocketChannel? channel;
bool isReconnecting = false;

void connectWebSocket() async {
  try {
    channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var childId = prefs.getString('connectionString');

    channel!.sink.add(jsonEncode({
      'type': 'register_child',
      'childId': childId,
    }));

    channel!.stream.listen(
          (message) {
        print("Received: $message");
      },
      onError: (error) {
        print("WebSocket error: $error");
        reconnect();
      },
      onDone: () {
        print("WebSocket connection closed.");
        reconnect();
      },
      cancelOnError: true,
    );
  } catch (e) {
    print("WebSocket connection failed: $e");
    reconnect();
  } finally {
    isReconnecting = false; // Reset the flag after attempting to connect
  }
}

void reconnect() {
  if (!isReconnecting) {
    isReconnecting = true;
    Future.delayed(Duration(seconds: 5), () {
      print("Attempting to reconnect...");
      connectWebSocket();
    });
  }
}

void startSharingLocation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var childId = prefs.getString('connectionString');
  connectWebSocket();

  DateTime now = DateTime.now();
  String todayKey = "${now.year}-${now.month}-${now.day}";
  String? savedDate = prefs.getString('maxSpeedDate');
  double maxSpeed = prefs.getDouble('maxSpeed') ?? 0.0;

  // Reset max speed if date changed
  if (savedDate != todayKey) {
    await prefs.setString('maxSpeedDate', todayKey);
    await prefs.setDouble('maxSpeed', 0.0);
    maxSpeed = 0.0;
  }

  getLiveLocation().listen((Position position) async {
    double speedKmph = position.speed * 3.6;

    // Update max speed if current speed is higher
    if (speedKmph > maxSpeed) {
      maxSpeed = speedKmph;
      await prefs.setDouble('maxSpeed', maxSpeed);
    }

    if (channel != null) {
      print("Longitude: ${position.longitude}, Latitude: ${position.latitude}, Speed: $speedKmph, MaxSpeedToday: $maxSpeed");

      channel!.sink.add(jsonEncode({
        'type': 'location_update',
        'childId': childId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': speedKmph,
        'maxSpeed': maxSpeed,
      }));
    }
  });
}

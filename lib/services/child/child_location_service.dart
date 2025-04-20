import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';
import 'dart:math';

double _degToRad(double deg) {
  return deg * (pi / 180);
}

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const radius = 6371; // Earth's radius in kilometers

  // Convert degrees to radians
  double lat1Rad = _degToRad(lat1);
  double lon1Rad = _degToRad(lon1);
  double lat2Rad = _degToRad(lat2);
  double lon2Rad = _degToRad(lon2);

  // Differences between the coordinates
  double deltaLat = lat2Rad - lat1Rad;
  double deltaLon = lon2Rad - lon1Rad;

  // Haversine formula
  double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) *
          sin(deltaLon / 2) * sin(deltaLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  // Distance in meters
  double distance = radius * c * 1000;

  return distance;
}

Stream<Position> getLiveLocation() {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
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

  // Initialize last history location and time
  Position? lastHistoryLocation;
  DateTime? lastHistoryTime;

  getLiveLocation().listen((Position position) async {
    double speedKmph = position.speed * 3.6;

    // Update max speed if current speed is higher
    if (speedKmph > maxSpeed) {
      maxSpeed = speedKmph;
      await prefs.setDouble('maxSpeed', maxSpeed);
    }

    // Check if we need to log history
    bool shouldLogHistory = false;

    if (lastHistoryLocation == null) {
      // First location update, always log as history
      shouldLogHistory = true;
    } else {
      // Calculate distance from last history location
      double distance = haversineDistance(
        lastHistoryLocation!.latitude,
        lastHistoryLocation!.longitude,
        position.latitude,
        position.longitude,
      );

      // Calculate time difference
      DateTime currentTime = DateTime.now();
      int timeDifference = currentTime.difference(lastHistoryTime!).inMinutes;

      // Check if either threshold is met
      if (distance >= 50 || timeDifference >= 10) {
        shouldLogHistory = true;
      }
    }

    // Update history location and time if needed
    if (shouldLogHistory) {
      lastHistoryLocation = position;
      lastHistoryTime = DateTime.now();
    }

    if (channel != null) {
      print("Longitude: ${position.longitude}, Latitude: ${position.latitude}, "
          "Speed: $speedKmph, MaxSpeedToday: $maxSpeed, History: $shouldLogHistory");

      channel!.sink.add(jsonEncode({
        'type': 'location_update',
        'childId': childId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': speedKmph,
        'maxSpeed': maxSpeed,
        'history': shouldLogHistory,
      }));
    }
  });
}
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';

Stream<Position> getLiveLocation() {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // meters
    ),
  );
}

IOWebSocketChannel? channel;
bool isConnected = false;

void connectWebSocket() {
  channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);

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
}

void reconnect() {
  if (!isConnected) {
    isConnected = true; // Prevent multiple reconnection attempts
    Future.delayed(Duration(seconds: 5), () {
      print("Attempting to reconnect...");
      connectWebSocket();
      isConnected = false;
    });
  }
}

void startSharingLocation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var childId = prefs.getString('connectionString');

  if (channel == null) {
    connectWebSocket();
  }

  channel!.sink.add(jsonEncode({
    'type': 'register_child',
    'childId': childId,
  }));

  getLiveLocation().listen((Position position) {
    if (channel != null) {
      print("Longitude: ${position.longitude}, Latitude: ${position.latitude}, Speed: ${position.speed}");
      channel!.sink.add(jsonEncode({
        'type': 'location_update',
        'childId': childId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
      }));
    }
  });
}

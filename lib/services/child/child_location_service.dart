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

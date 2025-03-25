import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

Stream<Position> getLiveLocation() {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // meters
    ),
  );
}



final channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);

void startSharingLocation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var childId= prefs.get('connectionString');

  channel.sink.add(jsonEncode({
    'type': 'register_child',
    'childId': childId,
  }));

  getLiveLocation().listen((Position position) {
    print("longitude : "+ position.longitude.toString() +"\n latitude : "+position.latitude.toString()+"\n Speed: "+position.speed.toString());
    channel.sink.add(jsonEncode({
      'type': 'location_update',
      'childId': childId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed' : position.speed,
    }));
  });
}

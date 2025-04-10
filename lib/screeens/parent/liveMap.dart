import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import '../../core/api_constants.dart';

class LiveMap extends StatefulWidget {
  final String childId;
  final String parentEmail;

  const LiveMap({
    Key? key,
    required this.childId,
    required this.parentEmail,
  }) : super(key: key);

  @override
  _LiveMapState createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  LatLng _currentLocation = LatLng(31.5204, 74.3587); // Default to Lahore
  late MapController _mapController;
  IOWebSocketChannel? channel;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    connectToWebSocket();
  }

  void reconnect() {
    if (!isConnected) {
      isConnected = true; // Prevent multiple reconnection attempts
      Future.delayed(Duration(seconds: 5), () {
        print("Attempting to reconnect...");
        connectToWebSocket();
        isConnected = false;
      });
    }
  }

  void connectToWebSocket() {
    channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
    channel!.sink.add(jsonEncode({
      'type': 'register_parent',
      'targetchildId': widget.childId,
      'parentId': widget.parentEmail,
    }));
    channel!.stream.listen(
          (data) {
        final decoded = jsonDecode(data);
        final lat = decoded['latitude'];
        final lng = decoded['longitude'];

        setState(() {
          _currentLocation = LatLng(lat, lng);
          _mapController.move(_currentLocation, 15.0);
        });
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 60.0,
                height: 60.0,
                point: _currentLocation,
                child: Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

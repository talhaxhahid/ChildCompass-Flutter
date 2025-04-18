import 'package:childcompass/provider/parent_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../../core/api_constants.dart';
import '../../provider/parent_provider.dart';

class LiveMap extends ConsumerStatefulWidget {

  @override
  _LiveMapState createState() => _LiveMapState();
}

class _LiveMapState extends ConsumerState<LiveMap> {
  CircleAnnotationManager? circleAnnotationManager;
  Point _currentLocation = Point(
    coordinates: Position(74.3587, 31.5204),
  ); // Default to Lahore
  MapboxMap? mapboxMap;
  WebSocketChannel? channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
  bool isConnected = false;
  late AnnotationManager annotationManager;
  CircleAnnotation? locationMarker;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => connectToWebSocket());
  }

  void reconnect() {
    if (!isConnected) {
      isConnected = true; // Prevent multiple reconnection attempts
      Future.delayed(const Duration(seconds: 5), () {
        print("Attempting to reconnect...");
        connectToWebSocket();
        isConnected = false;
      });
    }
  }

  void connectToWebSocket() {



    channel!.sink.add(jsonEncode({
      'type': 'register_parent',
      'targetchildId': ref.watch(connectedChildsProvider),
      'parentId': ref.read(parentEmailProvider),
    }));

    channel!.stream.listen(
          (data) {
        final decoded = jsonDecode(data);
        final lat = decoded['latitude'];
        final lng = decoded['longitude'];
        final child = decoded['childId'];


        print("latitude: "+lat.toString()+" longitude: "+lng.toString()+" Child : "+child.toString());
        if(ref.watch(currentChildProvider)==child){
          ref.read(speedProvider.notifier).state=decoded['speed'].toInt().toString();
        setState(() {
          _currentLocation = Point(
            coordinates: Position(lng, lat),
          );
          updateMarker();
          mapboxMap?.flyTo(
            CameraOptions(
              center: _currentLocation,
              zoom: 15.0,
            ),
            MapAnimationOptions(duration: 1000, startDelay: 0),
          );
        });
        }

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

  void updateMarker() async {
    if (mapboxMap == null) return;

    try {
      await circleAnnotationManager!.deleteAll();
      await circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: _currentLocation,
          circleColor: Colors.blue.value,
          circleRadius: 10.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        ),
      );
    } catch (e) {
      debugPrint('Error updating markers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentChildProvider, (previous, next) {
      print("CURRENNT CHILD CHANGE");
      if (next != null) {
        channel?.sink.add(jsonEncode({
          'type': 'query_child',
          'targetchildId': next,
          'parentId': ref.read(parentEmailProvider),
        }));
      }
    });
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),border: Border.all(width: 1 ,color: Color(0xFF373E4E))),
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: MapWidget(
          key: const ValueKey("mapWidget"),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          cameraOptions: CameraOptions(
            center: _currentLocation,
            zoom: 15.0,
          ),
          onMapCreated: (MapboxMap map) async {
            mapboxMap = map;
            // Hide Mapbox logo
            await mapboxMap!.logo.updateSettings(
              LogoSettings(enabled: false),
            );
            // Hide attribution icon
            await mapboxMap!.attribution.updateSettings(
              AttributionSettings(enabled: false),
            );
        
            mapboxMap!.annotations.createCircleAnnotationManager().then((manager) {
              if ( mounted) {
                setState(() {
                  circleAnnotationManager = manager;
                  updateMarker();
                });
        
              }
            }).catchError((e) {
              debugPrint('Error creating annotation manager: $e');
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

}



// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:web_socket_channel/io.dart';
// import 'dart:convert';
// import '../../core/api_constants.dart';
//
// class LiveMap extends StatefulWidget {
//   final String childId;
//   final String parentEmail;
//
//   const LiveMap({
//     Key? key,
//     required this.childId,
//     required this.parentEmail,
//   }) : super(key: key);
//
//   @override
//   _LiveMapState createState() => _LiveMapState();
// }
//
// class _LiveMapState extends State<LiveMap> {
//   LatLng _currentLocation = LatLng(31.5204, 74.3587); // Default to Lahore
//   late MapController _mapController;
//   IOWebSocketChannel? channel;
//   bool isConnected = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _mapController = MapController();
//     connectToWebSocket();
//   }
//
//   void reconnect() {
//     if (!isConnected) {
//       isConnected = true; // Prevent multiple reconnection attempts
//       Future.delayed(Duration(seconds: 5), () {
//         print("Attempting to reconnect...");
//         connectToWebSocket();
//         isConnected = false;
//       });
//     }
//   }
//
//   void connectToWebSocket() {
//     channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
//     channel!.sink.add(jsonEncode({
//       'type': 'register_parent',
//       'targetchildId': widget.childId,
//       'parentId': widget.parentEmail,
//     }));
//     channel!.stream.listen(
//           (data) {
//         final decoded = jsonDecode(data);
//         final lat = decoded['latitude'];
//         final lng = decoded['longitude'];
//
//         setState(() {
//           _currentLocation = LatLng(lat, lng);
//           _mapController.move(_currentLocation, 15.0);
//         });
//       },
//       onError: (error) {
//         print("WebSocket error: $error");
//         reconnect();
//       },
//       onDone: () {
//         print("WebSocket connection closed.");
//         reconnect();
//       },
//       cancelOnError: true,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 300,
//       child: FlutterMap(
//         mapController: _mapController,
//         options: MapOptions(
//           initialCenter: _currentLocation,
//           initialZoom: 15.0,
//         ),
//         children: [
//           TileLayer(
//             urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//           ),
//           MarkerLayer(
//             markers: [
//               Marker(
//                 width: 60.0,
//                 height: 60.0,
//                 point: _currentLocation,
//                 child: Icon(Icons.location_pin, color: Colors.red, size: 40),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
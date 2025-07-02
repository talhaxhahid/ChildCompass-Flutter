import 'package:childcompass/provider/parent_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'dart:convert';
import '../../core/api_constants.dart';
import '../../services/child/child_api_service.dart';
import '../mutual/placeholder.dart';
import 'avatarPin.dart';

class LiveMap extends ConsumerStatefulWidget {

  @override
  _LiveMapState createState() => _LiveMapState();
}

class _LiveMapState extends ConsumerState<LiveMap> {
  LatLng _currentLocation = const LatLng(31.5204, 74.3587); // Default to Lahore
  GoogleMapController? _mapController;
  WebSocketChannel? channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
  bool isReconnecting = false;
  bool isLoading = true;
  String time='never';
  Set<Marker> _markers = {};
  Set<Circle> _circles={};
  List<dynamic> _geofences = [];
  Marker? _locationMarker;
  double _currentZoom = 16.8; // Track current zoom level
  final String mapStyle = ''' 
[
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.neighborhood",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.business",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
''';

  @override
  void initState() {
    super.initState();
    Future.microtask((){ connectToWebSocket();
      getGeofenceLocations();

    });

  }

  Future<void> getGeofenceLocations() async {
    final geofences = await childApiService
        .getGeofenceLocations(ref.read(currentChildProvider)!);

    if (geofences == null) {
      return;
    }

      _geofences = geofences;
      _updateCircles();


  }

  Future<void> _updateCircles() async {
    _circles.clear();
    _markers.removeWhere((marker) => marker.markerId.value.contains('geofence'));
    print(_geofences);
    var selectedPoint;
    double circleRadius;
    for(var i=0 ;i<_geofences.length;i++) {

      selectedPoint= LatLng(_geofences[i]['latitude'],_geofences[i]['longitude'] );
      circleRadius=_geofences[i]['radius'].toDouble();

      if (selectedPoint != null) {
        _circles.add(
          Circle(
            zIndex: 10,
            circleId: CircleId('geofence$i'),
            center: selectedPoint!,
            radius: circleRadius,
            fillColor: Color(0xFF373E4E).withOpacity(0.5),
            strokeColor: Color(0xFF373E4E),
            strokeWidth: 2,
          ),
        );

        _markers.add(
          Marker(
              markerId:  MarkerId('geofence$i'),
              position: selectedPoint,
              icon: await Container(decoration: BoxDecoration(color: Color(0xFF373E4E),borderRadius: BorderRadius.circular(10)), child:Text(_geofences[i]['name'],style: TextStyle(color: Colors.white ,fontSize: 28 ,fontWeight: FontWeight.bold),), padding: EdgeInsets.symmetric(horizontal: 30,vertical: 10), ).toBitmapDescriptor(
              logicalSize: const Size(160, 160), imageSize: const Size(160, 160)
          ),

        ),
    );

      }
    }
    setState(() {

    });

  }

  void reconnect() {
    if (!isReconnecting) {
      isReconnecting = true;
      Future.delayed(Duration(seconds: 5), () {
        print("Attempting to reconnect...");
        connectToWebSocket();
      });
    }
  }

  void connectToWebSocket() {
    try {
    channel!.sink.add(jsonEncode({
      'type': 'register_parent',
      'targetchildId': ref.watch(connectedChildsProvider),
      'parentId': ref.read(parentEmailProvider),
    }));
    channel?.sink.add(jsonEncode({
      'type': 'query_child',
      'targetchildId': ref.read(currentChildProvider),
      'parentId': ref.read(parentEmailProvider),
    }));

    channel!.stream.listen(
          (data) {
        final decoded = jsonDecode(data);
        final lat = decoded['latitude'];
        final lng = decoded['longitude'];
        final child = decoded['childId'];
        time =decoded['time'];

        print("latitude: "+lat.toString()+" longitude: "+lng.toString()+" Child : "+child.toString());
        if(ref.watch(currentChildProvider)==child){
          ref.read(speedProvider.notifier).state=decoded['speed'].toInt().toString();
          ref.read(maxSpeedProvider.notifier).state=decoded['maxSpeed'].toInt().toString();
          setState(() {
            _currentLocation = LatLng(lat, lng);
            _updateMarker();

            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_currentLocation, _currentZoom),
            );
            isLoading=false;
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
    } catch (e) {
      print("WebSocket connection failed: $e");
      reconnect();
    } finally {
      isReconnecting = false; // Reset the flag after attempting to connect
    }
  }

  void _updateMarker() async {
    String ImageUrl = ref.read(connectedChildsImageProvider)?[ref.read(currentChildProvider)]??" ";

    // _markers.clear();
    _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentLocation,
        icon: await PinWithAvatar(imageUrl:ImageUrl).toBitmapDescriptor(
            logicalSize: const Size(160, 160), imageSize: const Size(160, 160)
        ),
          infoWindow: InfoWindow(
          title: 'Last Update',
          snippet: time,
          onTap: () {},
      // Use a custom widget for the info window
    ),

        // BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    print("Length of Markers array = ${_markers.length}");
    setState(()  {
    });
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
        getGeofenceLocations();
      }
    });

    return isLoading?buildShimmerMapPlaceholder(): Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1, color: const Color(0xFF373E4E)),
      ),
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GoogleMap(
          mapType: MapType.normal,
          style: mapStyle,
          initialCameraPosition: CameraPosition(
            tilt: 55,
            target: _currentLocation,
            zoom: _currentZoom,
          ),
          markers: _markers,
          circles: _circles,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
            ),
          }.toSet(),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Track zoom level changes
            controller.getZoomLevel().then((zoom) {
              _currentZoom = zoom;
            });
          },
          onCameraMove: (CameraPosition position) {
            // Update current zoom level whenever the camera moves
            _currentZoom = position.zoom;
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    _mapController?.dispose();
    super.dispose();
  }
}

// import 'package:childcompass/provider/parent_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'dart:convert';
// import '../../core/api_constants.dart';
// import '../../provider/parent_provider.dart';
//
// class LiveMap extends ConsumerStatefulWidget {
//
//   @override
//   _LiveMapState createState() => _LiveMapState();
// }
//
// class _LiveMapState extends ConsumerState<LiveMap> {
//   CircleAnnotationManager? circleAnnotationManager;
//   Point _currentLocation = Point(
//     coordinates: Position(74.3587, 31.5204),
//   ); // Default to Lahore
//   MapboxMap? mapboxMap;
//   WebSocketChannel? channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
//   bool isConnected = false;
//   late AnnotationManager annotationManager;
//   CircleAnnotation? locationMarker;
//
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() => connectToWebSocket());
//   }
//
//   void reconnect() {
//     if (!isConnected) {
//       isConnected = true; // Prevent multiple reconnection attempts
//       Future.delayed(const Duration(seconds: 5), () {
//         print("Attempting to reconnect...");
//         connectToWebSocket();
//         isConnected = false;
//       });
//     }
//   }
//
//   void connectToWebSocket() {
//
//
//
//     channel!.sink.add(jsonEncode({
//       'type': 'register_parent',
//       'targetchildId': ref.watch(connectedChildsProvider),
//       'parentId': ref.read(parentEmailProvider),
//     }));
//
//     channel!.stream.listen(
//           (data) {
//         final decoded = jsonDecode(data);
//         final lat = decoded['latitude'];
//         final lng = decoded['longitude'];
//         final child = decoded['childId'];
//
//
//         print("latitude: "+lat.toString()+" longitude: "+lng.toString()+" Child : "+child.toString());
//         if(ref.watch(currentChildProvider)==child){
//           ref.read(speedProvider.notifier).state=decoded['speed'].toInt().toString();
//           ref.read(maxSpeedProvider.notifier).state=decoded['maxSpeed'].toInt().toString();
//         setState(() {
//           _currentLocation = Point(
//             coordinates: Position(lng, lat),
//           );
//           updateMarker();
//           mapboxMap?.flyTo(
//             CameraOptions(
//               center: _currentLocation,
//               zoom: 15.0,
//             ),
//             MapAnimationOptions(duration: 1000, startDelay: 0),
//           );
//         });
//         }
//
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
//   void updateMarker() async {
//     if (mapboxMap == null) return;
//
//     try {
//       await circleAnnotationManager!.deleteAll();
//       await circleAnnotationManager!.create(
//         CircleAnnotationOptions(
//           geometry: _currentLocation,
//           circleColor: Colors.blue.value,
//           circleRadius: 10.0,
//           circleStrokeColor: Colors.white.value,
//           circleStrokeWidth: 2.0,
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error updating markers: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ref.listen<String?>(currentChildProvider, (previous, next) {
//       print("CURRENNT CHILD CHANGE");
//       if (next != null) {
//         channel?.sink.add(jsonEncode({
//           'type': 'query_child',
//           'targetchildId': next,
//           'parentId': ref.read(parentEmailProvider),
//         }));
//       }
//     });
//     return Container(
//       decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),border: Border.all(width: 1 ,color: Color(0xFF373E4E))),
//       height: 300,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(10),
//         child: MapWidget(
//           key: const ValueKey("mapWidget"),
//           styleUri: MapboxStyles.MAPBOX_STREETS,
//           cameraOptions: CameraOptions(
//             center: _currentLocation,
//             zoom: 15.0,
//           ),
//           onMapCreated: (MapboxMap map) async {
//             mapboxMap = map;
//             // Hide Mapbox logo
//             await mapboxMap!.logo.updateSettings(
//               LogoSettings(enabled: false),
//             );
//             // Hide attribution icon
//             await mapboxMap!.attribution.updateSettings(
//               AttributionSettings(enabled: false),
//             );
//
//             mapboxMap!.annotations.createCircleAnnotationManager().then((manager) {
//               if ( mounted) {
//                 setState(() {
//                   circleAnnotationManager = manager;
//                   updateMarker();
//                 });
//
//               }
//             }).catchError((e) {
//               debugPrint('Error creating annotation manager: $e');
//             });
//           },
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     channel?.sink.close();
//     super.dispose();
//   }
//
// }

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

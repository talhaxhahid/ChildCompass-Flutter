import 'dart:async';
import 'package:childcompass/services/child/child_api_service.dart';
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
import '../mutual/placeholder.dart';
import 'avatarPin.dart';

class HistoryMap extends ConsumerStatefulWidget {
  @override
  _HistoryMapState createState() => _HistoryMapState();
}

class _HistoryMapState extends ConsumerState<HistoryMap> {
  late StreamSubscription subscription;
   List<LatLng> historyCoordinates=[];
   List<String> historyTimeStamp=[];
  GoogleMapController? _mapController;
  WebSocketChannel? channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
  bool isReconnecting = false;
  bool isLoading = true;
  String time='never';
  dynamic distanceCovered =0;
  Set<Marker> _markers = {};
  double _currentZoom = 17.0; // Track current zoom level

  @override
  void initState() {
    super.initState();
    Future.microtask((){ getLocationHistory();

    });

  }



  void getLocationHistory() async {
    if(!isLoading){
    setState(() {
      isLoading=true;
    });}

    try {
      final data = await childApiService
          .getLocationHistory(ref.read(currentChildProvider)!);

            if(data != null) {
              print("history data received");

          final history = data['locationHistory'];

          distanceCovered= data['distance'];

            historyCoordinates=[];
            for(int i=0;i<history.length;i++)
              {
                historyCoordinates.add( LatLng(history[i]['latitude'],history[i]['longitude']));
                historyTimeStamp.add(history[i]['time']);
              }

            setState(() {
              _updateMarker();
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(historyCoordinates.last, _currentZoom),
              );
              isLoading=false;


            });

        }


    } catch (e) {
      print("WebSocket connection failed: $e");

    }
  }

  Set<Polyline> _getPolyline() {
    return {
      Polyline(
        polylineId: PolylineId("movement_history"),
        visible: true,
        points: historyCoordinates,
        color: Colors.blue,
        width: 4,
      )
    };
  }
  void _updateMarker() async {
    String ImageUrl = ref.read(connectedChildsImageProvider)?[ref.read(currentChildProvider)] ?? " ";

    _markers.clear();

    // Ensure we have at least 2 points (first and last)
    if (historyCoordinates.isEmpty) return;

    final int totalPoints = historyCoordinates.length;
    final int maxMarkers = 50;
    final int pointsToSelect = totalPoints > maxMarkers ? maxMarkers : totalPoints;

    // Calculate step size if we need to skip points
    double step = 1.0;
    if (totalPoints > maxMarkers) {
      step = (totalPoints - 1) / (pointsToSelect - 1);
    }

    // Always include first point
    _markers.add(
      Marker(
        markerId: const MarkerId("FirstHistoryLocation"),
        position: historyCoordinates.first,
        icon: await CircleAvatar(backgroundColor: Colors.redAccent, radius: 22).toBitmapDescriptor(
            logicalSize: const Size(160, 160),
            imageSize: const Size(160, 160)
        ),
        infoWindow: InfoWindow(
          title: 'Location Time',
          snippet: historyTimeStamp.first,
          onTap: () {},
        ),
      ),
    );

    // Add intermediate points if needed
    if (pointsToSelect > 2) {
      for (int i = 1; i < pointsToSelect - 1; i++) {
        int index = (i * step).round();
        // Ensure we don't go out of bounds and don't duplicate first/last points
        index = index.clamp(1, totalPoints - 2);

        _markers.add(
          Marker(
            markerId: MarkerId("LocationHistory_$i"),
            position: historyCoordinates[index],
            icon: await CircleAvatar(backgroundColor: Colors.indigo.shade300, radius: 12).toBitmapDescriptor(
                logicalSize: const Size(160, 160),
                imageSize: const Size(160, 160)
            ),
            infoWindow: InfoWindow(
              title: 'Location Time',
              snippet: historyTimeStamp[index],
              onTap: () {},
            ),
          ),
        );
      }
    }

    // Always include last point
    _markers.add(
      Marker(
        markerId: const MarkerId('LastHistoryLocation'),
        position: historyCoordinates.last,
        icon: await PinWithAvatar(imageUrl: ImageUrl).toBitmapDescriptor(
            logicalSize: const Size(160, 160),
            imageSize: const Size(160, 160)
        ),
        infoWindow: InfoWindow(
          title: 'Location Time',
          snippet: historyTimeStamp.last,
        ),
      ),
    );

    setState(() {});
  }

  // void _updateMarker() async {
  //   String ImageUrl = ref.read(connectedChildsImageProvider)?[ref.read(currentChildProvider)]??" ";
  //
  //   _markers.clear();
  //   for(int i=0 ; i<historyCoordinates.length-1;i++)
  //     {
  //       _markers.add(
  //         Marker(
  //           markerId: MarkerId("Locationhistory$i"),
  //           position: historyCoordinates[i],
  //           icon: i==0?await CircleAvatar(backgroundColor: Colors.redAccent,radius: 22,).toBitmapDescriptor(
  //               logicalSize: const Size(160, 160), imageSize: const Size(160, 160)
  //           ):await CircleAvatar(backgroundColor: Colors.indigo.shade300,radius: 12,).toBitmapDescriptor(
  //               logicalSize: const Size(160, 160), imageSize: const Size(160, 160)
  //           ),
  //           infoWindow: InfoWindow(
  //             title: 'Location Time',
  //             snippet: historyTimeStamp[i],
  //             onTap: () {},
  //
  //           ),
  //
  //
  //         ),
  //       );
  //     }
  //   _markers.add(
  //     Marker(
  //       markerId: const MarkerId('LastHistoryLocation'),
  //       position: historyCoordinates.last,
  //       icon: await PinWithAvatar(imageUrl:ImageUrl).toBitmapDescriptor(
  //           logicalSize: const Size(160, 160), imageSize: const Size(160, 160)
  //       ),
  //       infoWindow: InfoWindow(
  //
  //         title: 'Location Time',
  //         snippet: historyTimeStamp.last,
  //         // Use a custom widget for the info window
  //       ),
  //
  //       // BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  //     ),
  //   );
  //   setState(()  {
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentChildProvider, (previous, next) {
      print("CURRENNT CHILD CHANGE");
      if (next != null) {
        getLocationHistory();
      }
    });

    return isLoading?buildShimmerHistoryMapPlaceholder():Column(
      spacing: 10,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFEAF2FF),
            border: Border.all(width: 1, color: const Color(0xFF373E4E)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Distance Covered :" ,style: TextStyle(fontWeight: FontWeight.bold ,fontFamily: 'Quantico'),),
                Text(distanceCovered.toStringAsFixed(2)+" Km",style: TextStyle(fontWeight: FontWeight.bold ,fontFamily: 'Quantico'),),

              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 1, color: const Color(0xFF373E4E)),
          ),
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: historyCoordinates.last,
                zoom: _currentZoom,
              ),
              markers: _markers,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                ),
              }.toSet(),
              polylines: _getPolyline(),
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    _mapController?.dispose();
    super.dispose();
  }

}
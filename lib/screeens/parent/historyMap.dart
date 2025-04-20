import 'dart:async';

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
import 'avatarPin.dart';

class HistoryMap extends ConsumerStatefulWidget {
  @override
  _HistoryMapState createState() => _HistoryMapState();
}

class _HistoryMapState extends ConsumerState<HistoryMap> {
  late StreamSubscription subscription;
   List<LatLng> historyCoordinates=[];
  GoogleMapController? _mapController;
  WebSocketChannel? channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
  bool isReconnecting = false;
  bool isLoading = true;
  String time='never';
  Set<Marker> _markers = {};
  Marker? _locationMarker;
  double _currentZoom = 17.0; // Track current zoom level

  @override
  void initState() {
    super.initState();
    Future.microtask((){ connectToWebSocket();

    });

  }



  void connectToWebSocket() {
    if(!isLoading){
    setState(() {
      isLoading=true;
    });}

    try {
      channel!.sink.add(jsonEncode({
        'type': 'query_history',
        'targetchildId': ref.watch(currentChildProvider),

      }));
      subscription= channel!.stream.listen(
            (data) {
              print("history data received");
          final decoded = jsonDecode(data);
          final history = decoded['history'];
          final child = decoded['childId'];
          if(ref.watch(currentChildProvider)==child){
            historyCoordinates=[];
            for(int i=0;i<history.length;i++)
              {
                historyCoordinates.add( LatLng(history[i]['latitude'],history[i]['longitude']));
              }

            setState(() {
              _updateMarker();
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(historyCoordinates[0], _currentZoom),
              );
              isLoading=false;


            });
          }
        },
        onError: (error) {
          print("WebSocket error: $error");

        },
        onDone: () {
          print("WebSocket connection closed.");

        },
        cancelOnError: true,

      );
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
    String ImageUrl = ref.read(connectedChildsImageProvider)?[ref.read(currentChildProvider)]??" ";

    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('LastHistoryLocation'),
        position: historyCoordinates[0],
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
    setState(()  {
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentChildProvider, (previous, next) {
      print("CURRENNT CHILD CHANGE");
      if (next != null) {
        channel!.sink.add(jsonEncode({
          'type': 'query_history',
          'targetchildId': ref.watch(currentChildProvider),

        }));
      }
    });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1, color: const Color(0xFF373E4E)),
      ),
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child:isLoading?Center(child: CircularProgressIndicator()): GoogleMap(
          initialCameraPosition: CameraPosition(
            target: historyCoordinates[0],
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
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    _mapController?.dispose();
    super.dispose();
  }

}
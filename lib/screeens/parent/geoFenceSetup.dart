import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

class GeofenceSetupScreen extends StatefulWidget {
  @override
  _GeofenceSetupScreenState createState() => _GeofenceSetupScreenState();
}

class _GeofenceSetupScreenState extends State<GeofenceSetupScreen> {
  late GoogleMapController mapController;
  LatLng? selectedPoint;
  double circleRadius = 80; // Default radius in meters
  final TextEditingController locationNameController = TextEditingController();
  final double minRadius = 80; // Minimum radius in meters
  final double maxRadius = 1000; // Maximum radius in meters

  // Initial map position (you can set your own default)
  final LatLng _initialPosition = const LatLng(31.5204, 74.3587);

  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateCircles();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _updateMarker() async {


    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: selectedPoint!,
        icon: await CircleAvatar(backgroundColor:Color(0xFF373E4E) ,radius: 50,).toBitmapDescriptor(
        logicalSize: const Size(50, 50), imageSize: const Size(50, 50),),


      ),
    );

  }

  Future<void> _onMapTap(LatLng position) async {
    selectedPoint = position;
    await _updateMarker();
    _updateCircles();
    setState(()  {

    });
  }

  void _updateCircles() {
    _circles.clear();
    if (selectedPoint != null) {
      _circles.add(
        Circle(
          circleId: CircleId('geofence'),
          center: selectedPoint!,
          radius: circleRadius,
          fillColor: Color(0xFF373E4E).withOpacity(0.5),
          strokeColor: Color(0xFF373E4E),
          strokeWidth: 2,
        ),
      );
    }
  }

  void _onRadiusChanged(double value) {
    setState(() {
      circleRadius = value;
      _updateCircles();
    });
  }

  void _saveGeofence() {
    if (selectedPoint == null || locationNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location and enter a name')),
      );
      return;
    }

    // Here you would typically save the geofence to your database or state management
    final geofenceData = {
      'name': locationNameController.text,
      'latitude': selectedPoint!.latitude,
      'longitude': selectedPoint!.longitude,
      'radius': circleRadius,
    };

    print('Geofence saved: $geofenceData');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Geofence saved successfully')),
    );

    // Optionally navigate back
    // Navigator.pop(context, geofenceData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF373E4E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Setup GeoFence',
          style: TextStyle(color: Colors.white, fontFamily: "Quantico"),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 500, // Fixed map height as requested
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 11,
                ),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                  ),
                }.toSet(),
                markers: _markers,
                onTap: _onMapTap,
                circles: _circles,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedPoint != null) ...[

                    SizedBox(height: 16),
                    Text(
                      'Geofence Radius: ${circleRadius.round()} meters',
                      style: TextStyle(fontWeight: FontWeight.bold,fontFamily: "Quantico"),
                    ),
                    Slider(
                      activeColor: Color(0xFF373E4E),
                      value: circleRadius,
                      min: minRadius,
                      max: maxRadius,
                      divisions: (maxRadius - minRadius) ~/ 10,
                      label: '${circleRadius.round()} meters',
                      onChanged: _onRadiusChanged,
                    ),
                  ] else ...[
                    Text(
                      'Tap on the map to select a location',
                      style: TextStyle(fontStyle: FontStyle.italic ,fontFamily: "Quantico"),
                    ),
                  ],
                  SizedBox(height: 16),
      TextField(
        style: TextStyle(fontFamily: "Quantico"),
        controller: locationNameController,
        decoration: InputDecoration(
          focusColor: Color(0xFF373E4E),
          labelStyle: TextStyle(fontFamily: "Quantico"),
          floatingLabelStyle: TextStyle(
            fontFamily: "Quantico",
            color: Color(0xFF373E4E),
          ),
          labelText: 'Location Name',
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF373E4E)), // Default border color
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF373E4E)), // Border color when enabled but not focused
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF373E4E)),
          ),// Border color when focused
            hintText: 'Enter a name for this location',
          ),
        ),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveGeofence,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF373E4E), // Background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0), // Less rounded borders
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                        child: Text(
                          'Save Geofence',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Quantico",
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    locationNameController.dispose();
    super.dispose();
  }
}
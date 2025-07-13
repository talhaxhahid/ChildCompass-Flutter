import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:childcompass/services/child/child_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';
import 'dart:math';

double _degToRad(double deg) {
return deg * (pi / 180);
}

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
const radius = 6371; // Earth's radius in kilometers

double lat1Rad = _degToRad(lat1);
double lon1Rad = _degToRad(lon1);
double lat2Rad = _degToRad(lat2);
double lon2Rad = _degToRad(lon2);

double deltaLat = lat2Rad - lat1Rad;
double deltaLon = lon2Rad - lon1Rad;

double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
double c = 2 * atan2(sqrt(a), sqrt(1 - a));

return radius * c * 1000; // Distance in meters
}

class LocationService {
static final LocationService _instance = LocationService._internal();
factory LocationService() => _instance;
LocationService._internal();

IOWebSocketChannel? _channel;
bool _isReconnecting = false;
bool _isLocationStreamActive = false;
StreamSubscription<Position>? _locationSubscription;
Position? _lastHistoryLocation;
DateTime? _lastHistoryTime;
String? _childId;
String? childName;
double _maxSpeed = 0.0;
final _maxRetryDelay = Duration(minutes: 1); // Maximum delay between retries
Duration _currentRetryDelay = Duration(seconds: 5); // Initial retry delay
bool permissionNotification=false;

Future<void> initialize() async {
final prefs = await SharedPreferences.getInstance();
_childId = prefs.getString('connectionString');
childName = prefs.getString('childName');

// Initialize date tracking for max speed
DateTime now = DateTime.now();
String todayKey = "${now.year}-${now.month}-${now.day}";
String? savedDate = prefs.getString('maxSpeedDate');

if (savedDate != todayKey) {
await prefs.setString('maxSpeedDate', todayKey);
await prefs.setDouble('maxSpeed', 0.0);
}
_maxSpeed = prefs.getDouble('maxSpeed') ?? 0.0;

_startService();
}

void _startService() {
_connectWebSocket();
_startLocationUpdates();
}

void _connectWebSocket() {
if (_channel != null) return;

try {
_channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
_channel!.sink.add(jsonEncode({
'type': 'register_child',
'childId': _childId,
}));

_channel!.stream.listen(
(message) => print("Received: $message"),
onError: (error) {
print("WebSocket error: $error");
_reconnectWebSocket();
},
onDone: () {
print("WebSocket connection closed.");
_reconnectWebSocket();
},
cancelOnError: true,
);
} catch (e) {
print("WebSocket connection failed: $e");
_reconnectWebSocket();
}
}

void _reconnectWebSocket() {
if (_isReconnecting) return;

_isReconnecting = true;
_channel = null;

print("Attempting to reconnect WebSocket in ${_currentRetryDelay.inSeconds} seconds...");

Future.delayed(_currentRetryDelay, () {
_isReconnecting = false;
// Exponential backoff with maximum limit
_currentRetryDelay = Duration(seconds: min(_currentRetryDelay.inSeconds * 2, _maxRetryDelay.inSeconds));
_connectWebSocket();
});
}

Future<void> _startLocationUpdates() async {
if (_isLocationStreamActive) return;

try {
// Check and request permissions if needed
bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
print("Location services are disabled.");
await _handleLocationServiceDisabled();
return;
}
else{
if(permissionNotification==true){
http.get(Uri.parse('${ApiConstants.permissionIssue}/${_childId}/Your%20Child%20${childName}%20turn%20back%20on%20GPS'));
permissionNotification=false;}
}

LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied) {
print("Location permissions are denied");
await _handlePermissionDenied();
return;
}
}

if (permission == LocationPermission.deniedForever) {
print("Location permissions are permanently denied");
await _handlePermissionDeniedForever();
return;
} else
{
if(permissionNotification==true){
http.get(Uri.parse('${ApiConstants.permissionIssue}/${_childId}/Your%20Child%20${childName}%20granted%20Location%20Permission'));
permissionNotification=false;}
}




// Reset retry delay on successful permission check
_currentRetryDelay = Duration(seconds: 5);

// Start listening to location updates
_isLocationStreamActive = true;
_locationSubscription = getLiveLocation().listen(
(position) => _handleNewPosition(position),
onError: (error) {
print("Location stream error: $error");
_restartLocationUpdates();
},
cancelOnError: true,
);

  Timer.periodic(const Duration(seconds: 5), (Timer timer) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      if(permissionNotification==false){
        http.get(Uri.parse('${ApiConstants.permissionIssue}/${_childId}/Your%20Child%20${childName}%20Turn%20Off%20GPS%20Service'));
        permissionNotification=true;}

    }else{
      if(permissionNotification==true){
        http.get(Uri.parse('${ApiConstants.permissionIssue}/${_childId}/Your%20Child%20${childName}%20turn%20back%20on%20GPS'));
        permissionNotification=false;}
    }
  });

} catch (e) {
print("Error starting location updates: $e");
_restartLocationUpdates();
}
}

Future<void> _handleNewPosition(Position position) async {
try {
final prefs = await SharedPreferences.getInstance();
double speedKmph = position.speed * 3.6;

// Update max speed if current speed is higher
if (speedKmph > _maxSpeed) {
_maxSpeed = speedKmph;
await prefs.setDouble('maxSpeed', _maxSpeed);
}

// Check if we need to log history
bool shouldLogHistory = false;
double distance = 0;

if (_lastHistoryLocation == null) {
shouldLogHistory = true;
} else {
distance = haversineDistance(
_lastHistoryLocation!.latitude,
_lastHistoryLocation!.longitude,
position.latitude,
position.longitude,
);

DateTime currentTime = DateTime.now();
int timeDifference = currentTime.difference(_lastHistoryTime!).inMinutes;

if (distance >= 50 || timeDifference >= 10) {
shouldLogHistory = true;
}
}

// Update history location and time if needed
if (shouldLogHistory) {
_lastHistoryLocation = position;
_lastHistoryTime = DateTime.now();
print('logging Location History');

final location = {
'longitude': position.longitude,
'latitude': position.latitude,
};

try {
await childApiService.logLocationHistory(
connectionString: _childId!,
location: location,
distance: distance / 1000,
);
} catch (e) {
print("Error logging location history: $e");
// We'll try again next time
}
}

if (_channel != null) {
print("Longitude: ${position.longitude}, Latitude: ${position.latitude}, "
"Speed: $speedKmph, MaxSpeedToday: $_maxSpeed, History: $shouldLogHistory, Distance: $distance");

_channel!.sink.add(jsonEncode({
'type': 'location_update',
'childId': _childId,
'latitude': position.latitude,
'longitude': position.longitude,
'speed': speedKmph,
'maxSpeed': _maxSpeed,
}));
}
} catch (e) {
print("Error processing position: $e");
}
}

Future<void> _handleLocationServiceDisabled() async {
print("Attempting to enable location services...");
try {
if(permissionNotification==false){
http.get(Uri.parse('${ApiConstants.permissionIssue}/${_childId}/Your%20Child%20${childName}%20turn%20off%20GPS'));
permissionNotification=true;
}
// Try to open location settings and wait a bit before retrying
//await Geolocator.openLocationSettings();
await Future.delayed(Duration(seconds: 10));
} catch (e) {
print("Error opening location settings: $e");
}
_restartLocationUpdates();
}

Future<void> _handlePermissionDenied() async {
if(permissionNotification==false){
http.get(Uri.parse('${ApiConstants.permissionIssue}/${_childId}/Your%20Child%20${childName}%20revoked%20Location%20Permissions'));
permissionNotification=true;
}
print("Location permission denied. Will retry...");
// Wait a bit longer for permissions
await Future.delayed(Duration(seconds: 30));
_restartLocationUpdates();
}

Future<void> _handlePermissionDeniedForever() async {
if(permissionNotification==false){
http.get(Uri.parse('${ApiConstants.permissionIssue}/${_childId}/Your%20Child%20${childName}%20revoked%20Location%20Permissions'));
permissionNotification=true;
}
print("Location permission permanently denied. Attempting to open app settings...");
try {
// Open app settings so user can manually enable permissions
//await Geolocator.openAppSettings();
await Future.delayed(Duration(seconds: 30));
} catch (e) {
print("Error opening app settings: $e");
}
_restartLocationUpdates();
}

void _restartLocationUpdates() {
_isLocationStreamActive = false;
_locationSubscription?.cancel();
_locationSubscription = null;

print("Restarting location updates in ${_currentRetryDelay.inSeconds} seconds...");

Future.delayed(_currentRetryDelay, () {
// Exponential backoff with maximum limit
_currentRetryDelay = Duration(seconds: min(_currentRetryDelay.inSeconds * 2, _maxRetryDelay.inSeconds));
_startLocationUpdates();
});
}

Future<void> stopService() async {
_locationSubscription?.cancel();
_locationSubscription = null;
_isLocationStreamActive = false;
await _channel?.sink.close();
_channel = null;
_isReconnecting = false;
}
}

// Initialize the service when your app starts
final locationService = LocationService();

// Start the service
void startSharingLocation() {
locationService.initialize();
}

// Stop the service when no longer needed
void stopSharingLocation() {
locationService.stopService();
}

Stream<Position> getLiveLocation() {
return Geolocator.getPositionStream(
locationSettings: const LocationSettings(
accuracy: LocationAccuracy.bestForNavigation,
distanceFilter: 10, // meters
),
);
}



























// import 'dart:async';
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:childcompass/services/child/child_api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../core/api_constants.dart';
// import 'dart:math';
//
// double _degToRad(double deg) {
//   return deg * (pi / 180);
// }
//
// double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
//   const radius = 6371; // Earth's radius in kilometers
//
//   double lat1Rad = _degToRad(lat1);
//   double lon1Rad = _degToRad(lon1);
//   double lat2Rad = _degToRad(lat2);
//   double lon2Rad = _degToRad(lon2);
//
//   double deltaLat = lat2Rad - lat1Rad;
//   double deltaLon = lon2Rad - lon1Rad;
//
//   double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
//       cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
//   double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//
//   return radius * c * 1000; // Distance in meters
// }
//
// class LocationService {
//   static final LocationService _instance = LocationService._internal();
//   factory LocationService() => _instance;
//   LocationService._internal();
//
//   IOWebSocketChannel? _channel;
//   bool _isReconnecting = false;
//   bool _isLocationStreamActive = false;
//   StreamSubscription<Position>? _locationSubscription;
//   Position? _lastHistoryLocation;
//   DateTime? _lastHistoryTime;
//   String? _childId;
//   double _maxSpeed = 0.0;
//   final _maxRetryDelay = Duration(minutes: 1); // Maximum delay between retries
//   Duration _currentRetryDelay = Duration(seconds: 5); // Initial retry delay
//
//   Future<void> initialize() async {
//     final prefs = await SharedPreferences.getInstance();
//     _childId = prefs.getString('connectionString');
//
//     // Initialize date tracking for max speed
//     DateTime now = DateTime.now();
//     String todayKey = "${now.year}-${now.month}-${now.day}";
//     String? savedDate = prefs.getString('maxSpeedDate');
//
//     if (savedDate != todayKey) {
//       await prefs.setString('maxSpeedDate', todayKey);
//       await prefs.setDouble('maxSpeed', 0.0);
//     }
//     _maxSpeed = prefs.getDouble('maxSpeed') ?? 0.0;
//
//     _startService();
//   }
//
//   void _startService() {
//     _connectWebSocket();
//     _startLocationUpdates();
//   }
//
//   void _connectWebSocket() {
//     if (_channel != null) return;
//
//     try {
//       _channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
//       _channel!.sink.add(jsonEncode({
//         'type': 'register_child',
//         'childId': _childId,
//       }));
//
//       _channel!.stream.listen(
//             (message) => print("Received: $message"),
//         onError: (error) {
//           print("WebSocket error: $error");
//           _reconnectWebSocket();
//         },
//         onDone: () {
//           print("WebSocket connection closed.");
//           _reconnectWebSocket();
//         },
//         cancelOnError: true,
//       );
//     } catch (e) {
//       print("WebSocket connection failed: $e");
//       _reconnectWebSocket();
//     }
//   }
//
//   void _reconnectWebSocket() {
//     if (_isReconnecting) return;
//
//     _isReconnecting = true;
//     _channel = null;
//
//     print("Attempting to reconnect WebSocket in ${_currentRetryDelay.inSeconds} seconds...");
//
//     Future.delayed(_currentRetryDelay, () {
//       _isReconnecting = false;
//       // Exponential backoff with maximum limit
//       _currentRetryDelay = Duration(seconds: min(_currentRetryDelay.inSeconds * 2, _maxRetryDelay.inSeconds));
//       _connectWebSocket();
//     });
//   }
//
//   Future<void> _startLocationUpdates() async {
//     if (_isLocationStreamActive) return;
//
//     try {
//       // Check and request permissions if needed
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         print("Location services are disabled.");
//         await _handleLocationServiceDisabled();
//         return;
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           print("Location permissions are denied");
//           await _handlePermissionDenied();
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         print("Location permissions are permanently denied");
//         await _handlePermissionDeniedForever();
//         return;
//       }
//
//       // Reset retry delay on successful permission check
//       _currentRetryDelay = Duration(seconds: 5);
//
//       // Start listening to location updates
//       _isLocationStreamActive = true;
//       _locationSubscription = getLiveLocation().listen(
//             (position) => _handleNewPosition(position),
//         onError: (error) {
//           print("Location stream error: $error");
//           _restartLocationUpdates();
//         },
//         cancelOnError: true,
//       );
//
//     } catch (e) {
//       print("Error starting location updates: $e");
//       _restartLocationUpdates();
//     }
//   }
//
//   Future<void> _handleNewPosition(Position position) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       double speedKmph = position.speed * 3.6;
//
//       // Update max speed if current speed is higher
//       if (speedKmph > _maxSpeed) {
//         _maxSpeed = speedKmph;
//         await prefs.setDouble('maxSpeed', _maxSpeed);
//       }
//
//       // Check if we need to log history
//       bool shouldLogHistory = false;
//       double distance = 0;
//
//       if (_lastHistoryLocation == null) {
//         shouldLogHistory = true;
//       } else {
//         distance = haversineDistance(
//           _lastHistoryLocation!.latitude,
//           _lastHistoryLocation!.longitude,
//           position.latitude,
//           position.longitude,
//         );
//
//         DateTime currentTime = DateTime.now();
//         int timeDifference = currentTime.difference(_lastHistoryTime!).inMinutes;
//
//         if (distance >= 50 || timeDifference >= 10) {
//           shouldLogHistory = true;
//         }
//       }
//
//       // Update history location and time if needed
//       if (shouldLogHistory) {
//         _lastHistoryLocation = position;
//         _lastHistoryTime = DateTime.now();
//         print('logging Location History');
//
//         final location = {
//           'longitude': position.longitude,
//           'latitude': position.latitude,
//         };
//
//         try {
//           await childApiService.logLocationHistory(
//             connectionString: _childId!,
//             location: location,
//             distance: distance / 1000,
//           );
//         } catch (e) {
//           print("Error logging location history: $e");
//           // We'll try again next time
//         }
//       }
//
//       if (_channel != null) {
//         print("Longitude: ${position.longitude}, Latitude: ${position.latitude}, "
//             "Speed: $speedKmph, MaxSpeedToday: $_maxSpeed, History: $shouldLogHistory, Distance: $distance");
//
//         _channel!.sink.add(jsonEncode({
//           'type': 'location_update',
//           'childId': _childId,
//           'latitude': position.latitude,
//           'longitude': position.longitude,
//           'speed': speedKmph,
//           'maxSpeed': _maxSpeed,
//         }));
//       }
//     } catch (e) {
//       print("Error processing position: $e");
//     }
//   }
//
//   Future<void> _handleLocationServiceDisabled() async {
//     print("Attempting to enable location services...");
//     try {
//       // Try to open location settings and wait a bit before retrying
//       //await Geolocator.openLocationSettings();
//       await Future.delayed(Duration(seconds: 10));
//     } catch (e) {
//       print("Error opening location settings: $e");
//     }
//     _restartLocationUpdates();
//   }
//
//   Future<void> _handlePermissionDenied() async {
//     print("Location permission denied. Will retry...");
//     // Wait a bit longer for permissions
//     await Future.delayed(Duration(seconds: 30));
//     _restartLocationUpdates();
//   }
//
//   Future<void> _handlePermissionDeniedForever() async {
//     print("Location permission permanently denied. Attempting to open app settings...");
//     try {
//       // Open app settings so user can manually enable permissions
//       //await Geolocator.openAppSettings();
//       await Future.delayed(Duration(seconds: 30));
//     } catch (e) {
//       print("Error opening app settings: $e");
//     }
//     _restartLocationUpdates();
//   }
//
//   void _restartLocationUpdates() {
//     _isLocationStreamActive = false;
//     _locationSubscription?.cancel();
//     _locationSubscription = null;
//
//     print("Restarting location updates in ${_currentRetryDelay.inSeconds} seconds...");
//
//     Future.delayed(_currentRetryDelay, () {
//       // Exponential backoff with maximum limit
//       _currentRetryDelay = Duration(seconds: min(_currentRetryDelay.inSeconds * 2, _maxRetryDelay.inSeconds));
//       _startLocationUpdates();
//     });
//   }
//
//   Future<void> stopService() async {
//     _locationSubscription?.cancel();
//     _locationSubscription = null;
//     _isLocationStreamActive = false;
//     await _channel?.sink.close();
//     _channel = null;
//     _isReconnecting = false;
//   }
// }
//
// // Initialize the service when your app starts
// final locationService = LocationService();
//
// // Start the service
// void startSharingLocation() {
//   locationService.initialize();
// }
//
// // Stop the service when no longer needed
// void stopSharingLocation() {
//   locationService.stopService();
// }
//
// Stream<Position> getLiveLocation() {
//   return Geolocator.getPositionStream(
//     locationSettings: const LocationSettings(
//       accuracy: LocationAccuracy.bestForNavigation,
//       distanceFilter: 10, // meters
//     ),
//   );
// }

















// import 'dart:async';
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:childcompass/services/child/child_api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../core/api_constants.dart';
// import 'dart:math';
//
// double _degToRad(double deg) {
//   return deg * (pi / 180);
// }
//
// double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
//   const radius = 6371; // Earth's radius in kilometers
//
//   // Convert degrees to radians
//   double lat1Rad = _degToRad(lat1);
//   double lon1Rad = _degToRad(lon1);
//   double lat2Rad = _degToRad(lat2);
//   double lon2Rad = _degToRad(lon2);
//
//   // Differences between the coordinates
//   double deltaLat = lat2Rad - lat1Rad;
//   double deltaLon = lon2Rad - lon1Rad;
//
//   // Haversine formula
//   double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
//       cos(lat1Rad) * cos(lat2Rad) *
//           sin(deltaLon / 2) * sin(deltaLon / 2);
//   double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//
//   // Distance in meters
//   double distance = radius * c * 1000;
//
//   return distance;
// }
//
// Stream<Position> getLiveLocation() {
//   return Geolocator.getPositionStream(
//     locationSettings: const LocationSettings(
//       accuracy: LocationAccuracy.bestForNavigation,
//       distanceFilter: 10, // meters
//     ),
//   );
// }
//
// IOWebSocketChannel? channel;
// bool isReconnecting = false;
//
// void connectWebSocket() async {
//   try {
//     channel = IOWebSocketChannel.connect(ApiConstants.locationSharingSocket);
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var childId = prefs.getString('connectionString');
//
//     channel!.sink.add(jsonEncode({
//       'type': 'register_child',
//       'childId': childId,
//     }));
//
//     channel!.stream.listen(
//           (message) {
//         print("Received: $message");
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
//   } catch (e) {
//     print("WebSocket connection failed: $e");
//     reconnect();
//   } finally {
//     isReconnecting = false; // Reset the flag after attempting to connect
//   }
// }
//
// void reconnect() {
//   if (!isReconnecting) {
//     isReconnecting = true;
//     Future.delayed(Duration(seconds: 5), () {
//       print("Attempting to reconnect...");
//       connectWebSocket();
//     });
//   }
// }
//
// void startSharingLocation() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   var childId = prefs.getString('connectionString');
//   connectWebSocket();
//
//   DateTime now = DateTime.now();
//   String todayKey = "${now.year}-${now.month}-${now.day}";
//   String? savedDate = prefs.getString('maxSpeedDate');
//   double maxSpeed = prefs.getDouble('maxSpeed') ?? 0.0;
//
//   // Reset max speed if date changed
//   if (savedDate != todayKey) {
//     await prefs.setString('maxSpeedDate', todayKey);
//     await prefs.setDouble('maxSpeed', 0.0);
//     maxSpeed = 0.0;
//   }
//
//   // Initialize last history location and time
//   Position? lastHistoryLocation;
//   DateTime? lastHistoryTime;
//
//   getLiveLocation().listen((Position position) async {
//
//     double speedKmph = position.speed * 3.6;
//
//     // Update max speed if current speed is higher
//     if (speedKmph > maxSpeed) {
//       maxSpeed = speedKmph;
//       await prefs.setDouble('maxSpeed', maxSpeed);
//     }
//
//     // Check if we need to log history
//     bool shouldLogHistory = false;
//     double distance=0;
//     if (lastHistoryLocation == null) {
//       // First location update, always log as history
//       shouldLogHistory = true;
//     } else {
//       // Calculate distance from last history location
//         distance = haversineDistance(
//         lastHistoryLocation!.latitude,
//         lastHistoryLocation!.longitude,
//         position.latitude,
//         position.longitude,
//       );
//
//       // Calculate time difference
//       DateTime currentTime = DateTime.now();
//       int timeDifference = currentTime.difference(lastHistoryTime!).inMinutes;
//
//       // Check if either threshold is met
//       if (distance >= 50 || timeDifference >= 10) {
//         shouldLogHistory = true;
//       }
//     }
//
//     // Update history location and time if needed
//     if (shouldLogHistory) {
//       lastHistoryLocation = position;
//       lastHistoryTime = DateTime.now();
//       print('logging Location History');
//       final location = {
//         'longitude': position.longitude,
//         'latitude': position.latitude,
//       };
//        childApiService.logLocationHistory(connectionString: childId!, location: location , distance:distance/1000);
//
//     }
//
//     if (channel != null) {
//       print("Longitude: ${position.longitude}, Latitude: ${position.latitude}, "
//           "Speed: $speedKmph, MaxSpeedToday: $maxSpeed, History: $shouldLogHistory , Distance: $distance");
//
//       channel!.sink.add(jsonEncode({
//         'type': 'location_update',
//         'childId': childId,
//         'latitude': position.latitude,
//         'longitude': position.longitude,
//         'speed': speedKmph,
//         'maxSpeed': maxSpeed,
//
//       }));
//     }
//   });
// }
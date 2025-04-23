import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:childcompass/core/api_constants.dart';

class childApiService {
  // Register API Call
  static Future<Map<String, dynamic>?> registerChild(
      String name, String age, String gender) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.childRegisteration),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(
            {'name': name, 'age': age, 'gender': gender.toLowerCase()}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null; // Handle error cases as needed
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  static Future<Map<String, String>?> getChildNamesByConnections(
      List<String> connectionStrings) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.childNamesByConnection),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({'connectionStrings': connectionStrings}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // Convert dynamic values to String
        return responseData
            .map((key, value) => MapEntry(key, value?.toString() ?? ""));
      } else {
        print("Failed to get names: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  static Future<bool> logAppUsage({
    required String connectionString,
    required List<dynamic> appUsage,
    required int battery,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            ApiConstants.logAppUseage), // Define this in your ApiConstants
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'connectionString': connectionString,
          'appUsage': appUsage,
          'battery': battery,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] as bool? ?? false;
      } else {
        print("Failed to log app usage: ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error logging app usage: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getChildUsage(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/child/childUsage/$childId'),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'] as Map<String, dynamic>;
        }
      }

      print("Failed to get child usage: ${response.statusCode}");
      print("Response body: ${response.body}");
      return null;
    } catch (e) {
      print("Error fetching child usage: $e");
      return null;
    }
  }

  // Get all geofence locations for a child
  static Future<List<dynamic>?> getGeofenceLocations(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.getGeofence}/$childId'),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']['geofenceLocations'] as List;
        }
      }

      print("Failed to get geofence locations: ${response.statusCode}");
      print("Response body: ${response.body}");
      return null;
    } catch (e) {
      print("Error fetching geofence locations: $e");
      return null;
    }
  }

  // Add a new geofence location
  static Future<bool> addGeofence({
    required String connectionString,
    required Map<String, dynamic> geofence,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.addGeofence),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'connectionString': connectionString,
          'geofenceLocations': geofence,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }

      print("Failed to add geofence: ${response.statusCode}");
      print("Response body: ${response.body}");
      return false;
    } catch (e) {
      print("Error adding geofence: $e");
      return false;
    }
  }

  // Remove a geofence location
  static Future<bool> removeGeofence({
    required String childConnectionString,
    required Map<String, dynamic> geofence,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.removeGeofence),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'childConnectionString': childConnectionString,
          'geofence': {
            'latitude': geofence['latitude'],
            'longitude': geofence['longitude'],
          },
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }

      print("Failed to remove geofence: ${response.statusCode}");
      print("Response body: ${response.body}");
      return false;
    } catch (e) {
      print("Error removing geofence: $e");
      return false;
    }
  }
}

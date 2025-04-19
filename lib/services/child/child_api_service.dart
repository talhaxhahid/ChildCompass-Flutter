import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:childcompass/core/api_constants.dart';

class childApiService {


  // Register API Call
  static Future<Map<String, dynamic>?> registerChild(String name, String age , String gender) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.childRegisteration),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        body: jsonEncode({'name': name, 'age': age, 'gender': gender.toLowerCase()}),
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


  static Future<Map<String, String>?> getChildNamesByConnections(List<String> connectionStrings) async {
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
        return responseData.map((key, value) => MapEntry(key, value?.toString() ?? ""));
      } else {
        print("Failed to get names: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }




}

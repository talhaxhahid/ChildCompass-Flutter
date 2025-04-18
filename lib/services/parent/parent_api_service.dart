import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:childcompass/core/api_constants.dart';

class parentApiService {


  // Register API Call
  Future<Map<String, dynamic>?> registerParent(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.parentRegister),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name.trim(),
          "email": email.trim(),
          "password": password,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {"error": "Unexpected error occurred."};
        }
      }
    } catch (e) {
      print("Error: $e");
      return {"error": "Network error, please try again later."};
    }
  }

  //VERIFY-EMAIL
  Future<dynamic> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.emailVerification),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "verificationCode": code.trim(),
        }),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return 200;
      } else {
        return 400;
      }
    } catch (e) {
      print("Network Error: $e");
      return {"error": "Network error, please try again later."};
    }
  }

  //LOGIN API
  Future<Map<String, dynamic>> loginParent(String email, String password) async {
    final url = Uri.parse(ApiConstants.parentLogin); // API endpoint
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"message": "An error occurred: $e"};
    }
  }

 static Future<Map<String, dynamic>> parentDetails(String token) async {
    final url = Uri.parse(ApiConstants.parentDetails); // API endpoint
    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json",'Authorization': 'Bearer $token'},
      );

      return {"body":jsonDecode(response.body),"status":response.statusCode};
    } catch (e) {
      return {"message": "An error occurred: $e"};
    }
  }

  //ADD-CHILD API
  Future<Map<String, dynamic>> addChild(String email, String connectionString) async {
    final url = Uri.parse(ApiConstants.connectChild);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "connectionString": connectionString}),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "message": "Child added successfully"};
      } else {
        return {"success": false, "message": "Failed to add child"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  // REMOVE-CHILD API
  Future<Map<String, dynamic>> removeChild(String email, String connectionString) async {
    final url = Uri.parse(ApiConstants.removeChild); // Make sure this endpoint is set correctly in your ApiConstants

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "connectionString": connectionString}),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "message": "Child removed successfully"};
      } else {
        return {"success": false, "message": "Failed to remove child"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }




}






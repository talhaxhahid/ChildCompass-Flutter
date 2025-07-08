import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:childcompass/core/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class parentApiService {


  // Register API Call
  Future<Map<String, dynamic>?> registerParent(String name, String email, String password) async {
    String? token = await FirebaseMessaging.instance.getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm', token!);
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.parentRegister),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name.trim(),
          "email": email.trim(),
          "password": password,
          "fcm":token
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

  Future<dynamic> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim()
        }),
      );


      if (response.statusCode == 200) {
        return {"success":true};
      } else {
        return {"success":false};
      }
    } catch (e) {
      print("Network Error: $e");
      return {"success":false,"error": "Network error, please try again later."};
    }
  }
  Future<dynamic> resetPassword(String email, String verificationCode,String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.resetPassword),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "verificationCode":verificationCode.trim(),
          "newPassword":newPassword.trim()
        }),
      );



      if (response.statusCode == 200) {
        return {"success":true};
      } else {
        return {"success":false};
      }
    } catch (e) {
      print("Network Error: $e");
      return {"success":false,"error": "Network error, please try again later."};
    }
  }

  Future<dynamic> changePassword(String email, String currentPassword,String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.changePassword),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email":email.trim(),
          "currentPassword": currentPassword.trim(),
          "newPassword":newPassword.trim()
        }),
      );



      if (response.statusCode == 200) {
        return {"success":true};
      } else {
        return {"success":false};
      }
    } catch (e) {
      print("Network Error: $e");
      return {"success":false,"error": "Network error, please try again later."};
    }
  }

  Future<Map<String, dynamic>> updateNotificationSettings(dynamic settings) async {

    final url = Uri.parse(ApiConstants.parentNotificationSettings);
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        return {"success": true};
      } else {
        return {"success": false};
      }

    } catch (e) {
      return {"message": "An error occurred: $e"};
    }
  }

  //LOGIN API
  Future<Map<String, dynamic>> loginParent(String email, String password) async {
    String? token = await FirebaseMessaging.instance.getToken();
    final url = Uri.parse(ApiConstants.parentLogin); // API endpoint
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password ,"fcm":token} ),
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm', token!);

      return jsonDecode(response.body);
    } catch (e) {
      return {"message": "An error occurred: $e"};
    }
  }

 static Future<Map<String, dynamic>> parentDetails(String token) async {
   String? fcmtoken = await FirebaseMessaging.instance.getToken();

    final url = Uri.parse(ApiConstants.parentDetails); // API endpoint
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json",'Authorization': 'Bearer $token'},
        body: jsonEncode({"fcm":fcmtoken} ),
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm', fcmtoken!);

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

  Future<List<dynamic>> getParentsByConnection(String connectionString) async {

    final url = Uri.parse(ApiConstants.parentsList+connectionString);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['parents']; // This is a List of parents
      } else {
        print('Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> changeEmail(String token, String password, String newEmail) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.changeEmail),
        headers: {"Content-Type": "application/json",'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'password': password,
          'newEmail': newEmail,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyEmailChange(String email, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyEmailChange),
        headers: {"Content-Type": "application/json",'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'email': email,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }




}






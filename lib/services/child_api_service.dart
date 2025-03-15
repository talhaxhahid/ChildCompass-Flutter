import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:childcompass/core/api_constants.dart';

class childApiService {


  // Register API Call
  static Future<Map<String, dynamic>?> registerChild(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.childRegisteration),
        body: {'email': email, 'password': password},
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


}

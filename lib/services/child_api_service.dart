import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:childcompass/core/api_constants.dart';

class childApiService {


  // Register API Call
  static Future<Map<String, dynamic>?> registerChild(String name, String age , String gender) async {
    print(name);
    print(age);
    print(gender);
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


}

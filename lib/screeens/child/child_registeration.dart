import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/child/child_api_service.dart';

class childRegistration extends StatefulWidget {
  @override
  _ChildRegistrationState createState() => _ChildRegistrationState();
}

class _ChildRegistrationState extends State<childRegistration> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String selectedGender = "Boy";

  void toggleGender() {
    setState(() {
      selectedGender = selectedGender == "Boy" ? "Girl" : "Boy";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: CircleAvatar(
            radius: 10,
            backgroundColor: Colors.black38,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: Colors.black),
              splashColor: Colors.white,
            ),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/map.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              SizedBox(height: 100,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Transform.scale(
                      scale: 1.2,
                      child: Lottie.asset(
                        "assets/animations/child.json",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/messageBox/letsdoit.png"),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 320,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              hintText: "Name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              hintText: "Age",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: toggleGender,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedGender == "Boy" ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 30),
                                ),
                                child: Text("Boy", style: TextStyle(color: selectedGender == "Boy" ? Colors.white : Colors.black)),
                              ),
                              ElevatedButton(
                                onPressed: toggleGender,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedGender == "Girl" ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 30),
                                ),
                                child: Text("Girl", style: TextStyle(color: selectedGender == "Girl" ? Colors.white : Colors.black)),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: ()=>{handleRegister(context)},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Center(
                              child: Text(
                                "Continue",
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void handleRegister(BuildContext context) async {
    final result = await childApiService.registerChild(
        _nameController.text, _ageController.text, selectedGender);

    if (result != null) {
      // Store data in local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', 'child');
      await prefs.setString('connectionString', result['child']['connectionString']);
      await prefs.setString('childName', result['child']['name']); // Example, add any data you need

      // Navigate to home if login is successful
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/childCode',
        arguments: {'connectionString': result['child']['connectionString']},
          (Route<dynamic> route) => false,
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Connection Error")),
      );
    }
  }
}

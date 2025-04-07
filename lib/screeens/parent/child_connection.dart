import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/parent/parent_api_service.dart';
import '../../provider/parent_provider.dart';

class childConnection extends ConsumerStatefulWidget {
  @override
  ConsumerState<childConnection> createState() => _childConnectionState();
}

class _childConnectionState extends ConsumerState<childConnection> {


  // Focus nodes for each text field
  FocusNode _focusNode1 = FocusNode();
  FocusNode _focusNode2 = FocusNode();
  FocusNode _focusNode3 = FocusNode();
  FocusNode _focusNode4 = FocusNode();

  // Controllers for each text field
  TextEditingController _controller1 = TextEditingController();
  TextEditingController _controller2 = TextEditingController();
  TextEditingController _controller3 = TextEditingController();
  TextEditingController _controller4 = TextEditingController();

  @override
  void dispose() {
    // Dispose of controllers and focus nodes when done
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    _focusNode4.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    super.dispose();
  }

  // Function to move to the next input field
  void _moveFocus(FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/map.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Transform.scale(
                      scale: 1.1,
                      child: Lottie.asset(
                        "assets/animations/parent.json",
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
                          image: AssetImage("assets/images/messageBox/almostdone.png"),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ClipRRect(
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
                        Text(
                          "CHILD CONNECTION",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Quantico",
                              fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Enter the Code in your Child’s App to build connection with your child. You can find the Code in the settings.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Quantico",
                              fontSize: 12),
                        ),
                        SizedBox(height: 10),
                        Row(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInputField(_controller1, _focusNode1, _focusNode2),
                            _buildInputField(_controller2, _focusNode2, _focusNode3),
                            _buildInputField(_controller3, _focusNode3, _focusNode4),
                            _buildInputField(_controller4, _focusNode4, null),
                          ],
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            var parentEmail = ref.watch(parentEmailProvider);
                            String code = _controller1.text + _controller2.text + _controller3.text + _controller4.text;

                            print("Parent Email: $parentEmail, Entered Code: $code");

                            // ✅ Call the function to add the child connection
                            if (parentEmail != null) {
                              await handleAddChild(parentEmail!, code);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Connecting to Server, Kindly Wait")),
                              );
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              var token = prefs.get('authToken');
                              final response = await parentApiService.parentDetails(token.toString());
                              print(response['body']);
                              parentEmail=response['body']['parent']['email'];
                              await handleAddChild(parentEmail!, code);

                            }

                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Center(
                            child: Text(
                              "Submit",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  // Reusable function to create input fields
  Widget _buildInputField(TextEditingController controller, FocusNode focusNode, FocusNode? nextFocus) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.text, // Accepts both numbers and letters
        inputFormatters: [
          LengthLimitingTextInputFormatter(1), // Limit input to 1 character
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), // Allow letters & numbers
        ],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 && nextFocus != null) {
            _moveFocus(focusNode, nextFocus);
          }
        },
      ),
    );
  }

  Future<void> handleAddChild(String parentEmail, String connectionString) async {
    final apiService = parentApiService(); // ✅ Ensure correct class name
    final result = await apiService.addChild(parentEmail, connectionString);

    if (result != null && result.containsKey("message")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"])),
      );

      print("API Response: ${result["message"]}");

      if (result["success"]==true) {
        print("Child added successfully!");
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/parentDashboard',
              (Route<dynamic> route) => false,
        );
      }
    }
  }



}


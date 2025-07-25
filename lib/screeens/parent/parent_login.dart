import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/parent_provider.dart';
import '../../services/parent/parent_api_service.dart';

class parentLogin extends ConsumerStatefulWidget  {
  @override
  _ParentLoginState createState() => _ParentLoginState();
}

class _ParentLoginState extends ConsumerState<parentLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
          height:    MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/map.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
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
                          image: AssetImage("assets/images/messageBox/welcomeback.png"),
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
                        Text("LOGIN", style: TextStyle(color: Colors.black , fontWeight: FontWeight.bold,fontFamily: "Quantico" , fontSize: 18),),

                        SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            hintText: "Email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword, // This will toggle between hidden and visible
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          hintText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(onTap: ()=>{Navigator.pushNamed(context, '/ForgotPasswordScreen')}, child: Text("Forgot Password ?", style: TextStyle(color: Colors.black , fontWeight: FontWeight.bold,fontFamily: "Quantico" , fontSize: 12 ),)),
                          ],
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            handleLoginResponse(
                                context,
                                _emailController.text,  // Pass email
                                _passwordController.text // Pass password
                            );
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
                              "Continue",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account ? ", style: TextStyle(color: Colors.black , fontWeight: FontWeight.bold,fontFamily: "Quantico" , fontSize: 12),),
                            InkWell(onTap: ()=>{Navigator.pushNamed(context, '/parentRegisteration')}, child: Text("Register", style: TextStyle(color: Colors.orange , fontWeight: FontWeight.bold,fontFamily: "Quantico" , fontSize: 12 ),)),
                          ],
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
  void handleLoginResponse(BuildContext context, String email, String password) async {
    final parentApiService _apiService = parentApiService();
    final response = await _apiService.loginParent(email, password);

    if (response.containsKey("token")) {
      // Login successful, store token and navigate
      final String token = response["token"];
      print("Login successful! Token: $token");
      // Navigate to dashboard or home screen
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', 'parent');
      await prefs.setString('authToken', token);
      prefs.setString('parentEmail', response['parent']['email']);
      ref.read(parentEmailProvider.notifier).state = response['parent']['email'];
      if(response['message']=='verifyEmail')
        Navigator.pushReplacementNamed(context, "/emailVerification");
      else
      Navigator.pushReplacementNamed(context, "/parentDashboard");
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Login failed")),
      );
    }
  }
}


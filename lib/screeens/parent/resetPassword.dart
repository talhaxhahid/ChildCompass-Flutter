import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent/parent_api_service.dart';
import '../../provider/parent_provider.dart';

class ResetPassword extends ConsumerStatefulWidget {


  const ResetPassword({super.key});
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends ConsumerState<ResetPassword> {
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final TextEditingController _controller3 = TextEditingController();
  final TextEditingController _controller4 = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;


  @override
  void dispose() {
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

  void _moveFocus(FocusNode currentFocus, FocusNode? nextFocus) {
    currentFocus.unfocus();
    if (nextFocus != null) {
      FocusScope.of(context).requestFocus(nextFocus);
    }
  }

  Future<void> handleVerifyEmail(BuildContext context) async {
    String? email = ref.read(parentEmailProvider);

    if (email == null || email.isEmpty) {

      return;

    }

    String verificationCode =
        _controller1.text + _controller2.text + _controller3.text + _controller4.text;

    if (verificationCode.length != 4) {
      setState(() => _errorMessage = "Enter a valid 4-digit code.");
      return;
    }
    if(_passwordController.text.length<8){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password Must be of Atleast 8 Characters ")),
      );

      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await parentApiService().resetPassword(email, verificationCode,_passwordController.text);
      if (response['success'] == true) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/parentLogin',
                (Route<dynamic> route) => false,
          );
      } else {
        setState(() => _errorMessage =  "Invalid Verification Code");
      }
    } catch (e) {
      setState(() => _errorMessage = "Network error. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(parentEmailProvider) ?? 'No email';
    print("Email from provider: $email");
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
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


                ],
              ),
              const SizedBox(height: 20),
              _buildVerificationBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text("RESET PASSWORD", style: _titleTextStyle()),
              const SizedBox(height: 10),
              Text("Enter the code, it’s in your inbox.", textAlign: TextAlign.center, style: _subtitleTextStyle()),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  _buildOtpTextField(_controller1, _focusNode1, _focusNode2),
                  _buildOtpTextField(_controller2, _focusNode2, _focusNode3),
                  _buildOtpTextField(_controller3, _focusNode3, _focusNode4),
                  _buildOtpTextField(_controller4, _focusNode4, null),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 10),

              TextField(
                controller: _passwordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  hintText: "New Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => handleVerifyEmail(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 15 ,horizontal: 20),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpTextField(TextEditingController controller, FocusNode currentFocus, FocusNode? nextFocus) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        focusNode: currentFocus,
        keyboardType: TextInputType.number,
        inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => _moveFocus(currentFocus, nextFocus),
      ),
    );
  }

  TextStyle _titleTextStyle() => const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  TextStyle _subtitleTextStyle() => const TextStyle(fontSize: 14, color: Colors.black54);
}

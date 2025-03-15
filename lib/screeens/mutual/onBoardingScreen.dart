import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class onBoardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                Text(
                  "CHILD COMPASS",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(12, 77, 115,1),
                    fontFamily: "Quantico"
                  ),
                ),
                SizedBox(height:45,
                    width: 45,
                    child: Image.asset("assets/images/icon.png")),
              ],
            ),
            const SizedBox(height: 10),
            // Illustration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Image.asset("assets/images/main-img.jpeg"),
            ),
            const SizedBox(height: 30),
            // Lottie Animations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Lottie.asset("assets/animations/child.json"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/childRegisteration');
                        // Navigate as child
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("I AM CHILD",
                      style: TextStyle(fontFamily: 'Quantico',fontWeight: FontWeight.bold, color: Colors.black),),
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Lottie.asset("assets/animations/parent.json"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/parentRegisteration');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("I AM PARENT",
                        style: TextStyle(fontFamily: 'Quantico',fontWeight: FontWeight.bold, color: Colors.black),)
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:childcompass/screeens/onBoardingScreen.dart';
import 'package:flutter/material.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp(initialRoute:'/onBoardingScreen'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Child Compass',
      initialRoute: initialRoute,
      routes: {
        '/onBoardingScreen': (context) => onBoardingScreen(),

      },
    );
  }
}

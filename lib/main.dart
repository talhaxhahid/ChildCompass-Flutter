import 'package:childcompass/screeens/child/child_code.dart';
import 'package:childcompass/screeens/child/child_dashboard.dart';
import 'package:childcompass/screeens/child/child_registeration.dart';
import 'package:childcompass/screeens/mutual/onBoardingScreen.dart';
import 'package:childcompass/screeens/parent/child_connection.dart';
import 'package:childcompass/screeens/parent/email_verification.dart';
import 'package:childcompass/screeens/parent/parent_login.dart';
import 'package:childcompass/screeens/parent/parent_registeration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/parent_email_provider.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String intial_route;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var user = prefs.get('user');
  if(user=='child')
    {
      intial_route='/childDashboard';
    }
  else if(user=='parent')
    {
      intial_route='/parentDashboard';
    }
  else{
    intial_route='/onBoardingScreen';
  }
  runApp(
    ProviderScope( // Wrap your app inside ProviderScope
      child: MyApp(initialRoute: intial_route),
    ),
  );
}

class MyApp extends StatelessWidget  {


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
        '/childRegisteration': (context) => childRegistration(),
        '/parentRegisteration': (context) => parentRegistration(),
        '/parentLogin': (context) => parentLogin(),
        '/emailVerification': (context) => EmailVerification(),
        '/childConnection': (context) => childConnection(),
        '/childCode': (context) => childCode(),
        '/childDashboard': (context) => childDashboard(),
        '/parentDashboard': (context) => childDashboard(),
      },
    );
  }
}

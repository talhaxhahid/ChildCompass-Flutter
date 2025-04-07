import 'package:childcompass/core/api_constants.dart';
import 'package:childcompass/screeens/child/child_code.dart';
import 'package:childcompass/screeens/child/child_dashboard.dart';
import 'package:childcompass/screeens/child/child_registeration.dart';
import 'package:childcompass/screeens/mutual/onBoardingScreen.dart';
import 'package:childcompass/screeens/parent/child_connection.dart';
import 'package:childcompass/screeens/parent/email_verification.dart';
import 'package:childcompass/screeens/parent/parent_dashboard.dart';
import 'package:childcompass/screeens/parent/parent_login.dart';
import 'package:childcompass/screeens/parent/parent_registeration.dart';
import 'package:childcompass/services/parent/parent_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String intial_route='/onBoardingScreen';
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var user = prefs.get('user');
  if(user=='child')
    {
      intial_route='/childDashboard';
    }
  else if(user=='parent') {
    var token = prefs.get('authToken');
    final response = await parentApiService.parentDetails(token.toString());
    if (response['status'] == 401) {
      intial_route = '/parentLogin';
    }
    else {

    if (response['status'] == 200)
      intial_route = '/parentDashboard';
    else if (response['status'] == 405)
      intial_route = '/emailVerification';
    else if (response['status'] == 406)
      intial_route = '/childConnection';
    else
      intial_route = '/onBoardingScreen';
  }
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
        '/parentDashboard': (context) => parentDashboard(),
      },
    );
  }
}

import 'package:childcompass/core/api_constants.dart';
import 'package:childcompass/provider/parent_provider.dart';
import 'package:childcompass/screeens/child/child_code.dart';
import 'package:childcompass/screeens/child/child_dashboard.dart';
import 'package:childcompass/screeens/child/child_registeration.dart';
import 'package:childcompass/screeens/child/child_taskscreen.dart';
import 'package:childcompass/screeens/mutual/onBoardingScreen.dart';
import 'package:childcompass/screeens/parent/ParentEndChildDetails.dart';
import 'package:childcompass/screeens/parent/child_connection.dart';
import 'package:childcompass/screeens/parent/email_verification.dart';
import 'package:childcompass/screeens/parent/geoFenceSetup.dart';
import 'package:childcompass/screeens/parent/geofenceLocations.dart';
import 'package:childcompass/screeens/parent/parentEndChildSettings.dart';
import 'package:childcompass/screeens/parent/parent_dashboard.dart';
import 'package:childcompass/screeens/parent/parent_login.dart';
import 'package:childcompass/screeens/parent/parent_registeration.dart';
import 'package:childcompass/screeens/parent/parentsList.dart';
import 'package:childcompass/screeens/parent/parent_taskscreen.dart';
import 'package:childcompass/services/firebaseMessaging.dart';
import 'package:childcompass/services/parent/parent_api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessagingService().initialize();
  //MapboxOptions.setAccessToken("pk.eyJ1IjoiZW1hd2F0c29uIiwiYSI6ImNtOGoyNzB5YjBhdDcyaXMzeTBjY2FiZ2sifQ.lhvhhMAAJktVCSXiDyF8Mg");
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');
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

    if (response['body'] != null && response['body']['parent'] != null) {
      await prefs.setString('parentEmail', response['body']['parent']['email'] ?? '');
      await prefs.setString('parentName', response['body']['parent']['name'] ?? '');


      // Check if 'childConnectionStrings' is not null before converting it to a list
      if (response['body']['parent']['childConnectionStrings'] != null) {
        await prefs.setStringList('connectedChilds', List<String>.from(response['body']['parent']['childConnectionStrings']));
      } else {
        await prefs.setStringList('connectedChilds', []);
      }
    } else {
      // Handle the case where 'body' or 'parent' is null (e.g., show an error or set defaults)
      print('Error: Response body or parent data is null');
    }



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
        '/parentEndChildSettings':(context)=>ParentEndChildSettings(),
        '/parentEndChildDetails':(context)=>ChildSettingsScreen(),
        '/ParentListScreen':(context)=>ParentListScreen(),
        '/GeofenceSetupScreen':(context)=>GeofenceSetupScreen(),
        '/GeofenceListScreen':(context)=>GeofenceListScreen(),
        '/childTaskscreen': (context) => ChildTaskscreen(),
        '/parentTaskScreen': (context) => ParentTaskScreen(),


      },
    );
  }
}

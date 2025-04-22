import 'package:flutter/material.dart';
import '../../core/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/child/child_background_service.dart';
import '../../services/child/child_location_service.dart';

class childDashboard extends StatefulWidget {
  @override
  _childDashboardState createState() => _childDashboardState();
}

class _childDashboardState extends State<childDashboard> {
  var childName;
  var childCode;
  var grantedPermissions =false;

  @override
  void initState() {

    _requestPermissions();
    getChildData();
    super.initState();
  }
 void getChildData() async{
   SharedPreferences prefs = await SharedPreferences.getInstance();
   childName = prefs.get('childName');
   childCode= prefs.get('connectionString');
   setState(() {

   });
}

  Future<void> _requestPermissions() async {
     grantedPermissions= await permissions.grantRequiredPermissions();
    // if( grantedPermissions){
    // ChildBackgroundService();}
     ChildBackgroundService();

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hi, '+ childName.toString(), style:  TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: "Quantico",
              fontSize: 18,
            )),
            Row(
              spacing: 15,
              children: [

                InkWell( onTap: (){
                  Navigator.pushNamed(context, '/childCode',arguments: {'connectionString': childCode},);
                }, child: Icon(Icons.person_add_alt_1_outlined, color: Colors.black)),
                InkWell( onTap: (){
                  // Navigator.pushNamed(context, '/childSettings');
                }, child: Icon(Icons.settings_rounded, color: Colors.black)),
              ],
            ),


          ],
        ),
      ),
      body: Container(
        child: Center(
          child: ElevatedButton(onPressed: ()=>{startSharingLocation()}, child: Text("Share Location")),
        ),
      )
    );
  }
}

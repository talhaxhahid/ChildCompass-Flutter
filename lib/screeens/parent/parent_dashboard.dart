import 'package:childcompass/screeens/parent/liveMap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:childcompass/provider/parent_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class parentDashboard extends ConsumerStatefulWidget {
  @override
  _parentDashboardState createState() => _parentDashboardState();
}

class _parentDashboardState extends ConsumerState<parentDashboard> {

  String? parentName;
  String? parentEmail;
  List<String>? connectedChilds;
  bool isLoading=true;

  @override
  void initState() {
    super.initState();
    initDashboard();
  }

  void initDashboard() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    parentName = prefs.getString('parentName');
    parentEmail= prefs.getString('parentEmail');
    connectedChilds=prefs.getStringList('connectedChilds');
    print(connectedChilds);
    setState(() {
    isLoading=false;
    });
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
              Text('Hi, $parentName', style:  TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: "Quantico",
                fontSize: 18,
              )),
              Row(
                spacing: 15,
                children: [

                  
                  InkWell( onTap: (){
                    // Navigator.pushNamed(context, '/childSettings');
                  }, child: Icon(Icons.settings_rounded, color: Colors.black)),
                ],
              ),


            ],
          ),
        ),
        body: Container(
          padding: EdgeInsets.symmetric(vertical: 20,horizontal: 10),
          child: Column(
            children: [
              SizedBox(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Horizontal scroll direction
                  child: Row(
                    children: List.generate(connectedChilds?.length ?? 0, (index) {
                      return Container(
                        margin: EdgeInsets.only(right: 10),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade400, // Background color for the pill
                          borderRadius: BorderRadius.circular(30), // Pill shape
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)], // Optional shadow for depth
                        ),
                        child: Text(
                          connectedChilds?[index] ?? "No Connected Childs",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white, // Text color
                          ),
                        ),
                      );
                    })..add(
                      // Add the extra "+" button
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey, // Color for the "+" button
                          borderRadius: BorderRadius.circular(30), // Pill shape
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)], // Optional shadow
                        ),
                        child: Text(
                          "+",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white, // Text color for "+"
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30,),

              !isLoading?
              LiveMap( childId: connectedChilds![0]??"", parentEmail: parentEmail??"",):Text("Map"),
            ],
          ),
        )
    );
  }
}

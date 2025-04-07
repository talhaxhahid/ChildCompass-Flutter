import 'package:flutter/material.dart';


class parentDashboard extends StatefulWidget {
  @override
  _parentDashboardState createState() => _parentDashboardState();
}

class _parentDashboardState extends State<parentDashboard> {

  @override
  void initState() {
    super.initState();
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
              Text('Hi, ', style:  TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: "Quantico",
                fontSize: 18,
              )),
              Row(
                spacing: 15,
                children: [

                  InkWell( onTap: (){

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
             child: Text("Parent Dashboard"),
          ),
        )
    );
  }
}

import 'package:childcompass/screeens/parent/dashboard_buttons.dart';
import 'package:childcompass/screeens/parent/liveMap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:childcompass/provider/parent_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/parent/parent_api_service.dart';

class parentDashboard extends ConsumerStatefulWidget {
  @override
  _parentDashboardState createState() => _parentDashboardState();
}

class _parentDashboardState extends ConsumerState<parentDashboard> {
  String? parentName;
  String? parentEmail;
  List<String>? connectedChilds;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initDashboard();
  }

  void initDashboard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.get('authToken');
    final response = await parentApiService.parentDetails(token.toString());
    parentName = response['body']['parent']['name'];
    parentEmail = response['body']['parent']['email'];
    connectedChilds =
        List<String>.from(response['body']['parent']['childConnectionStrings']);
    ref.read(parentNameProvider.notifier).state = parentName;
    ref.read(parentEmailProvider.notifier).state = parentEmail;
    ref.read(connectedChildsProvider.notifier).state = connectedChilds;
    ref.read(currentChildProvider.notifier).state = connectedChilds![0];
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF373E4E),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hi, $parentName',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Quantico",
                    fontSize: 18,
                  )),
              Row(
                spacing: 15,
                children: [
                  InkWell(
                      onTap: () {
                        // Navigator.pushNamed(context, '/childSettings');
                      },
                      child: Icon(Icons.settings_rounded, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        body: Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              connectedChildsWidget(),
              SizedBox(
                height: 30,
              ),
              !isLoading
                  ? LiveMap(
                      childId: connectedChilds![0] ?? "",
                      parentEmail: parentEmail ?? "",
                    )
                  : Text("Map"),
              SizedBox(
                height: 30,
              ),
              ParentDashboardButton(),
            ],
          ),
        ));
  }

  Widget connectedChildsWidget() {
    void _switchChild(String child) {
      ref.read(currentChildProvider.notifier).state = child;
    }

    return SizedBox(
      width: double.infinity,
      child: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      List.generate(connectedChilds?.length ?? 0, (index) {
                    return GestureDetector(
                      onTap: () => {_switchChild(connectedChilds![index])},
                      child: Container(
                        margin: EdgeInsets.only(right: 10),
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: ref.watch(currentChildProvider).toString()==connectedChilds![index]? Colors.blueGrey :Color(0xFF4D566A), // Background color for the pill
                          borderRadius: BorderRadius.circular(30), // Pill shape
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ], // Optional shadow for depth
                        ),
                        child: Text(
                          connectedChilds?[index] ?? "No Connected Childs",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white, // Text color
                            fontFamily: "Quantico",
                          ),
                        ),
                      ),
                    );
                  })),
            ),
          ),
          GestureDetector(
            onTap: () => {
              Navigator.pushNamed(
                context,
                '/childConnection',
              )
            },
            child: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF373E4E), // Color for the "+" button
                borderRadius: BorderRadius.circular(30), // Pill shape
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4)
                ], // Optional shadow
              ),
              child: Text(
                "+",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

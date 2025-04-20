import 'dart:async';
import 'dart:convert';
import 'package:childcompass/screeens/parent/dashboard_buttons.dart';
import 'package:childcompass/screeens/parent/liveMap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:childcompass/provider/parent_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/api_constants.dart';
import '../../services/child/child_api_service.dart';
import '../../services/parent/parent_api_service.dart';
import 'historyMap.dart';

class parentDashboard extends ConsumerStatefulWidget {
  @override
  _parentDashboardState createState() => _parentDashboardState();
}

class _parentDashboardState extends ConsumerState<parentDashboard> {
  String? parentName;
  String? parentEmail;
  List<String>? connectedChilds;
  bool isLoading = true;
  WebSocketChannel? channel = IOWebSocketChannel.connect(ApiConstants.ActiveStatusSharingSocket);

  @override
  void initState() {
    super.initState();
    initDashboard();
  }

  StreamSubscription? _webSocketSubscription;

  void connectToWebSocket() {
    // Send registration message
    channel!.sink.add(jsonEncode({
      'type': 'register_parent',
      'targetchildId': ref.watch(connectedChildsProvider),
      'parentId': ref.read(parentEmailProvider),
    }));

    // Only listen if not already listening
    if (_webSocketSubscription == null) {
      _webSocketSubscription = channel!.stream.listen(
            (data) {
          final decoded = jsonDecode(data);
          ref.read(connectedChildsStatusProvider.notifier).state = decoded['children'];
          print("Active Status: ${decoded['children']}");
        },
        onError: (error) {
          print("WebSocket error: $error");
        },
        onDone: () {
          print("WebSocket connection closed.");
          _webSocketSubscription = null; // reset on close
        },
        cancelOnError: true,
      );
    } else {
      print("Already listening to WebSocket.");
    }
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
    final Map<String, String?> childImagesMap = {};

    for (int i = 0; i < connectedChilds!.length; i++) {
      final childKey = connectedChilds![i];
      final imagePath = prefs.getString(childKey);
      childImagesMap[childKey] = imagePath;
    }
    print("Child Image : "+childImagesMap.toString());
    ref.read(connectedChildsImageProvider.notifier).state=childImagesMap;
    ref.read(connectedChildsNameProvider.notifier).state=await childApiService.getChildNamesByConnections(connectedChilds!);
    setState(() {
      isLoading = false;
    });


    connectToWebSocket();
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
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/parentDashboard',
                              (Route<dynamic> route) => false,
                        );
                      },
                      child: Icon(Icons.refresh, color: Colors.white)),
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
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              children: [
                connectedChildsWidget(),
                SizedBox(
                  height: 30,
                ),
                !isLoading
                    ? LiveMap(dashboardContext:context)
                    : SizedBox(height: 300, child: Center(child: CircularProgressIndicator(),),),
                SizedBox(
                  height: 30,
                ),

                ParentDashboardButton(),
                SizedBox(
                  height: 30,
                ),
                !isLoading?HistoryMap()
                : SizedBox(height: 300, child: Center(child: CircularProgressIndicator(),),),
              ],
            ),
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
                        final statusMap = ref.watch(connectedChildsStatusProvider);
                        final status = connectedChilds?[index];
                        return GestureDetector(
                          onTap: () => {_switchChild(connectedChilds![index])},
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 10),
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                decoration: BoxDecoration(
                                  color: ref.watch(currentChildProvider).toString() == connectedChilds![index]
                                      ? Colors.blueGrey
                                      : Color(0xFF4D566A),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Text(
                                  ref.watch(connectedChildsNameProvider)?[connectedChilds?[index]] ?? "No Connected Childs",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontFamily: "Quantico",
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 8,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    //color: Colors.green,
                                    color: statusMap != null && statusMap[status] == true
                                        ? Colors.green
                                        : statusMap != null && statusMap[status] == false
                                        ? Colors.red
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1), // optional border
                                  ),
                                ),
                              ),
                            ],
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

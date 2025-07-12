import 'dart:async';
import 'dart:convert';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api_constants.dart';

class SosService {


  late final String? parentId ;
  final String wsUrl = ApiConstants.sosAlertSocket;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;

  bool _isConnected = false;


  void start() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    parentId = prefs.getString('parentEmail');
    _connect();
  }

  void _connect() {

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      print("Connected to WebSocket");

      // Send child registration
      _channel!.sink.add(jsonEncode({
        'type': 'register_parent',
        'parentId': parentId,
      }));



      // Listen to incoming messages
      _channel!.stream.listen(
            (message) {
              final data = jsonDecode(message);
              if(data['type']=='sos_alert'){
                FlutterRingtonePlayer().play(
                    fromAsset: "assets/audio/sos.mp3",
                    looping: true, // or false depending on your need
                    volume: 1.0,
                    asAlarm: true
                );
                Future.delayed(Duration(seconds: 8), () {
                  FlutterRingtonePlayer().stop();
                });

              }

        },
        onDone: _handleDisconnect,
        onError: (error) {
          print("WebSocket error: $error");
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("WebSocket connection failed: $e");
      _scheduleReconnect();
    }
  }



  void _handleDisconnect() {
    if (_isConnected) {
      print("WebSocket disconnected");
      _isConnected = false;
      _channel = null;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    print("Scheduling reconnect...");
    _reconnectTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isConnected) {
        print("Trying to reconnect...");
        _connect();
      } else {
        timer.cancel();
      }
    });
  }

  void dispose() {


    _reconnectTimer?.cancel();
    _channel?.sink.close();
  }
}

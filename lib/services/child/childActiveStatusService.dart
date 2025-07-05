import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api_constants.dart';

class ChildActiveStatusService {


  late final String? childId ;
  final String wsUrl = ApiConstants.ActiveStatusSharingSocket;

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;


  void start() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('connectionString');
    _connect();
  }

  void _connect() {

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      print("Connected to WebSocket");

      // Send child registration
      _channel!.sink.add(jsonEncode({
        'type': 'register_child',
        'childId': childId,
      }));

      // Start sending pings
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(Duration(seconds: 5), (_) => _sendPing());

      // Listen to incoming messages
      _channel!.stream.listen(
            (message) {
          print("Message from server: $message");
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

  void _sendPing() {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'ping',
        'childId': childId,
      }));
      print("Ping sent");
    }
  }

  void _handleDisconnect() {
    if (_isConnected) {
      print("WebSocket disconnected");
      _isConnected = false;
      _pingTimer?.cancel();
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

    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
  }
}

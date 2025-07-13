import 'dart:async';
import 'dart:convert';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/api_constants.dart';

class SosService {
  late final String? parentId;
  final String wsUrl = ApiConstants.sosAlertSocket;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isDisposed = false;

  void start() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    parentId = prefs.getString('parentEmail');
    _connect();
  }

  void _connect() {
    if (_isDisposed) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      print("Connected to WebSocket");

      // Register parent immediately upon connection
      _registerParent();

      // Listen to incoming messages
      _channel!.stream.listen(
            (message) {
              print('Message from the server...');
          final data = jsonDecode(message);
          if (data['type'] == 'sos_alert') {
            FlutterRingtonePlayer().play(
              fromAsset: "assets/audio/sos.mp3",
              looping: true,
              volume: 1.0,
              asAlarm: true,
            );
            Future.delayed(Duration(seconds: 10), () {
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
      _handleDisconnect();
    }
  }

  void _registerParent() {
    if (_isConnected && parentId != null) {
      try {
        _channel!.sink.add(jsonEncode({
          'type': 'register_parent',
          'parentId': parentId,
        }));
        print("Parent registration sent");
      } catch (e) {
        print("Failed to send parent registration: $e");
      }
    }
  }

  void _handleDisconnect() {
    if (_isConnected || _isDisposed) {
      _isConnected = false;
      _channel?.sink.close();
      _channel = null;

      if (!_isDisposed) {
        print("WebSocket disconnected, attempting to reconnect...");
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;
    if (_isDisposed) return;

    print("Scheduling reconnect...");
    _reconnectTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isConnected && !_isDisposed) {
        print("Attempting to reconnect...");
        _connect();
      } else {
        timer.cancel();
        _reconnectTimer = null;
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    print("SosService disposed");
  }
}
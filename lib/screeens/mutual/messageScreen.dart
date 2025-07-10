import 'dart:io';
import 'package:childcompass/core/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../provider/parent_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    required this.currentUserName,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {


  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['chatId'] == _getChatId()) {

        _messages.add(message.data);
        setState(() {

        });
      }
    });
  }

  String _getChatId() {
    var ids = [widget.currentUserId, widget.otherUserId];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.messaging}history?user1=${widget.currentUserId}&user2=${widget.otherUserId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages = json.decode(response.body);
          _isLoading = false;
          if(_messages.isNotEmpty)
          http.post(
            Uri.parse('${ApiConstants.messaging}mark-read'),
              headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
              },
              body: jsonEncode({
              'chatId': _messages[0]['chatId'],
              'userId': widget.currentUserId,
              })
          );
        });
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();


    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.messaging}send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderName':widget.currentUserName,
          'senderId': widget.currentUserId,
          'receiverId': widget.otherUserId,
          'content': message,
        }),
      );

      if (response.statusCode == 201) {
        _messages.add({
          'senderId': widget.currentUserId,
          'receiverId': widget.otherUserId,
          'content': message,
        });
        setState(() {

        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.messaging}mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chatId': _getChatId(),
          'userId': widget.currentUserId,
        }),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = ref.read(connectedChildsImageProvider)?[ref.read(currentChildProvider)]??" ";
    final statusMap = ref.watch(connectedChildsStatusProvider);
    final status = ref.watch(currentChildProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF373E4E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          spacing: 10,
          children: [
            Stack(
              children: [
                Container(
                  height: 35,
                  width: 35,
                  child: ClipOval(
                    child: imageUrl!=" "?Image.file(File(imageUrl),fit: BoxFit.cover,): Image.asset(
                      'assets/images/child.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
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
            Text(widget.otherUserName ,style: TextStyle(color: Colors.white, fontFamily: "Quantico"),),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh , color: Colors.white),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['senderId'] == widget.currentUserId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Color(0xFF373E4E) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message['content'] , style: TextStyle(color: isMe?Colors.white:Colors.black),),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(message['timestamp']??DateTime.now().toString()),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send ,color: Color(0xFF373E4E),),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          SizedBox(height: 20,)
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
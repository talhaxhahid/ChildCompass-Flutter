import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/parent_provider.dart';
import '../../services/parent/parent_api_service.dart';
import '../mutual/messageScreen.dart';


  class ParentChatListScreen extends ConsumerStatefulWidget {
    final  parents;
    final childId;
    final childName;


    const ParentChatListScreen({
      required this.parents,
      required this.childId,
      required this.childName,

      Key? key,
    }) : super(key: key);

  @override
  ConsumerState<ParentChatListScreen> createState() => _ParentListScreenState();
  }

class _ParentListScreenState extends ConsumerState<ParentChatListScreen> {
  bool isLoading = false;


  @override
  void initState() {
    super.initState();

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF373E4E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Parents List',
          style: TextStyle(color: Colors.white, fontFamily: "Quantico"),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.parents.isEmpty
          ? const Center(child: Text("No parents found."))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.parents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final parent = widget.parents[index];
          return ParentCard(
            childId: widget.childId,
            name: parent['name'] ?? 'Unknown',
            email: parent['email'],
            childName: widget.childName,
          );
        },
      ),
    );
  }
}


class ParentCard extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String childId;
  final String childName;

  const ParentCard({
    super.key,
    required this.name,
    required this.email,
    required this.childName,
    required this.childId

  });

  @override
  ConsumerState<ParentCard> createState() => _ParentCardState();
}

class _ParentCardState extends ConsumerState<ParentCard> {


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:  () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUserName: widget.childName,
            currentUserId: widget.childId,
            otherUserId: widget.email,
            otherUserName: widget.name,
          ),
        ),
      );
    },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF), // light blue shade
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            // Details Column
            CircleAvatar(
              child: Icon(Icons.person),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),

                ],
              ),
            ),
            // Delete icon
            IconButton(
              icon: const Icon(Icons.navigate_next, color: Colors.blueGrey),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      currentUserName: widget.childName,
                      currentUserId: widget.childId,
                      otherUserId: widget.email,
                      otherUserName: widget.name,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

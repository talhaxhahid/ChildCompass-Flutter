import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/parent_provider.dart';
import '../../services/parent/parent_api_service.dart';





  class ParentListScreen extends ConsumerStatefulWidget {
  const ParentListScreen({super.key});

  @override
  ConsumerState<ParentListScreen> createState() => _ParentListScreenState();
  }

class _ParentListScreenState extends ConsumerState<ParentListScreen> {
  bool isLoading = true;
  List<dynamic> parents = [];

  @override
  void initState() {
    super.initState();
    fetchParents();
  }


  Future<void> fetchParents() async {
    setState(() => isLoading = true);
    final apiService = parentApiService();
    String connectionString = ref.read(currentChildProvider).toString();

    try {
      final result = await apiService.getParentsByConnection(connectionString);
      setState(() {
        parents = result; // assuming result is a List
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
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
          : parents.isEmpty
          ? const Center(child: Text("No parents found."))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: parents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final parent = parents[index];
          return ParentCard(
            name: parent['name'] ?? 'Unknown',
            email: parent['email'] ?? '',
            joinedDate:  '25 April 2025',
            lastOnlineDate: '28 April 2025',
          );
        },
      ),
    );
  }
}


class ParentCard extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String joinedDate;
  final String lastOnlineDate;

  const ParentCard({
    super.key,
    required this.name,
    required this.email,
    required this.joinedDate,
    required this.lastOnlineDate,
  });

  @override
  ConsumerState<ParentCard> createState() => _ParentCardState();
}

class _ParentCardState extends ConsumerState<ParentCard> {

  bool isLoading = false;
  Future<void> _handleUnpair(String parentEmail ) async {
    setState(() {
      isLoading = true;
    });

    final apiService = parentApiService();

    String connectionString = ref.read(currentChildProvider).toString();

    try {
      final result = await apiService.removeChild(parentEmail, connectionString);

      if(result['success']==true){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["message"])),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/parentDashboard',
              (Route<dynamic> route) => false,
        );

      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["message"])),
        );

      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF), // light blue shade
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(widget.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    )),
                const SizedBox(height: 4),
                Text('Joined on ${widget.joinedDate}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    )),
                const SizedBox(height: 2),
                Text('Last online ${widget.lastOnlineDate}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    )),
              ],
            ),
          ),
          // Delete icon
          IconButton(
            icon: isLoading?CircularProgressIndicator():const Icon(Icons.delete, color: Colors.red),
            onPressed: (

                ) {_handleUnpair(widget.email);},
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/parent_provider.dart';
import '../../services/parent/parent_api_service.dart';


class ParentEndChildSettings extends ConsumerStatefulWidget {
  const ParentEndChildSettings({super.key});

  @override
  ConsumerState<ParentEndChildSettings> createState() => _ParentEndChildSettingsState();
}

class _ParentEndChildSettingsState extends ConsumerState<ParentEndChildSettings> {
  bool isLoading = false;

  Future<void> _handleUnpair() async {
    setState(() {
      isLoading = true;
    });

    final apiService = parentApiService();
    String parentEmail = ref.read(parentEmailProvider).toString();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF373E4E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Child Settings',
          style: TextStyle(color: Colors.white, fontFamily: "Quantico"),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30,),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF373E4E)),
            title: const Text("Kid’s nickname and avatar"),
            subtitle:  Text(ref.read(connectedChildsNameProvider)?[ref.read(currentChildProvider)]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: (){

               Navigator.pushNamed(context, '/parentEndChildDetails');
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.groups, color: Color(0xFF373E4E)),
            title: const Text("Parent list"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/ParentListScreen');
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 20),
          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : TextButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              label: const Text(
                'Unpair your kid\'s device',
                style: TextStyle(color: Colors.red, fontFamily: "Quantico"),
              ),
              onPressed: _handleUnpair,
            ),
          ),
        ],
      ),
    );
  }
}

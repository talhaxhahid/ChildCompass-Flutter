import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider/parent_provider.dart';


class ChildSettingsScreen extends ConsumerStatefulWidget {
  @override
  _ChildSettingsScreenState createState() => _ChildSettingsScreenState();
}

class _ChildSettingsScreenState extends ConsumerState<ChildSettingsScreen> {
  File? _image;
  String? _gender = 'boy';
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kindly Choose an Image')),
      );
      return;
    }

    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      // Create a unique filename
      final fileName = path.basename(_image!.path);
      // Copy the file to a permanent location
      final savedImage = await _image!.copy('${appDir.path}/$fileName');

      // Save the path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentChildKey = ref.read(currentChildProvider);
      await prefs.setString(currentChildKey.toString(), savedImage.path);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settings saved successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/parentDashboard',
            (Route<dynamic> route) => false,
      );

      // Optionally navigate back
      // Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Color(0xFFF1F5FA),
                    backgroundImage: _image != null ? FileImage(_image!) : ref.read(connectedChildsImageProvider)?[ref.read(currentChildProvider)]!=null?FileImage(File(ref.read(connectedChildsImageProvider)?[ref.read(currentChildProvider)])):null,
                    child: _image == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.blue),
                        SizedBox(height: 5),
                        Text(
                          'Upload a photo',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    )
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'This is how your kid will appear in the app and notifications',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGenderOption('boy', Icons.boy, 'A boy'),
                  _buildGenderOption('girl', Icons.girl, 'A girl'),
                ],
              ),
              SizedBox(height: 60),
              Center(
                child: SizedBox(
                  width: 120,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Text('Save', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Color(0xFF373E4E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saveImage,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, String label) {
    bool selected = _gender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = gender;
        });
      },
      child: Container(
        width: 120,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Color(0xFF373E4E) : Colors.grey),
          borderRadius: BorderRadius.circular(10),
          color: selected ? Colors.deepPurple.shade50 : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: selected ? Color(0xFF373E4E) : Colors.grey),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: selected ? Color(0xFF373E4E) : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
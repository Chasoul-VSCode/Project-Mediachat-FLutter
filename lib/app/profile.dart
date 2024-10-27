import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  
  get userId => null;

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Username';
  File? _imageFile;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
        });
        await _fetchUserData();
      } else {
        print('User ID not found in SharedPreferences');
        // Handle the case when userId is not available
      }
    } catch (e) {
      print('Error loading user ID: $e');
      // Handle any errors that occur during the process
    }
  }

  Future<void> _fetchUserData() async {
    final response = await http.get(Uri.parse('http://192.168.1.7:3000/api/users/$_userId'));
    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      setState(() {
        _userName = userData['username'] ?? 'Username';
      });
    } else {
      // Handle error
      print('Failed to load user data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _changeProfilePicture,
                      child: CircleAvatar(
                        radius: 50, // Reduced from 60
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : const AssetImage('assets/default_profile.png') as ImageProvider,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 25, // Reduced from 30
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Reduced from 15
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Reduced from 20
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18), // Reduced from 20
                          onPressed: _changeUserName,
                          color: Colors.blue.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15), // Reduced from 20
                    SizedBox(
                      width: 130, // Reduced from 150
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => DashboardPage(userId: widget.userId ?? 0)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10), // Reduced from 12
                        ),
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _changeUserName() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = '';
        return AlertDialog(
          title: const Text('Username'),
          content: TextField(
            onChanged: (value) {
              newName = value;
            },
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (newName.isNotEmpty) {
                  final response = await http.put(
                    Uri.parse('http://192.168.1.7:3000/api/users/$_userId'),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(<String, String>{
                      'username': newName,
                    }),
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      _userName = newName;
                    });
                    Navigator.of(context).pop();
                  } else {
                    // Handle error
                    print('Failed to update username');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

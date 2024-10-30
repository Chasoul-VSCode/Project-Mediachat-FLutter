import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  
  get userId => null;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Username';
  File? _imageFile;
  String _userId = '';
  String? _profileImageUrl;

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
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  Future<void> _fetchUserData() async {
    final response = await http.get(Uri.parse('http://192.168.1.7:3000/api/users/$_userId'));
    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      setState(() {
        _userName = userData['username'] ?? 'Username';
        if (userData['images_profile'] != null) {
          _profileImageUrl = userData['images_profile'];
        }
      });
    } else {
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
                        radius: 50,
                        backgroundImage: _getProfileImage(),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: _changeUserName,
                          color: Colors.blue.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: 130,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => DashboardPage(userId: widget.userId ?? 0)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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

  ImageProvider<Object> _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.startsWith('data:image')) {
      return MemoryImage(base64Decode(_profileImageUrl!.split(',')[1]));
    } else if (_userId.isNotEmpty) {
      return NetworkImage('http://192.168.1.7:3000/api/users/$_userId/profile-image');
    }
    return const AssetImage('./images/default-profile.jpg');
  }

  Future<void> _changeProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        final response = await http.put(
          Uri.parse('http://192.168.1.7:3000/api/users/$_userId'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'username': _userName,
            'images_profile': base64Image,
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            _imageFile = File(image.path);
            _profileImageUrl = base64Image;
          });
          _showDialog('Success', 'Profile picture updated successfully.');
        } else {
          _handleHttpError(response);
        }
      } else {
        _showDialog('Error', 'No image selected.');
      }
    } catch (e) {
      print('Error saving profile picture: $e');
      _showDialog('Error', 'Failed to save profile picture. Please try again.');
    }
  }

  void _handleHttpError(http.Response response) {
    String message;
    switch (response.statusCode) {
      case 400:
        message = 'Bad Request: ${response.body}';
        break;
      case 404:
        message = 'User not found.';
        break;
      case 500:
        message = 'Server error: ${response.body}';
        break;
      default:
        message = 'Unexpected error: ${response.body}';
    }
    _showDialog('Error', message);
  }

  void _showDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
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

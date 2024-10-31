import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class AboutPage extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final int userId;

  const AboutPage({
    Key? key,
    required this.username,
    required this.isDarkMode,
    required this.userId,
  }) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String _error = '';
  final int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final targetUserId =
          widget.userId == _currentUserId ? _currentUserId : widget.userId;

      // Try local API first
      final localResponse = await _fetchFromApi(Config.localApiUrl, targetUserId);
      if (localResponse.statusCode == 200) {
        _handleSuccessResponse(localResponse);
        return;
      }

      // If local fails, try remote API
      final remoteResponse = await _fetchFromApi(Config.remoteApiUrl, targetUserId);
      if (remoteResponse.statusCode == 200) {
        _handleSuccessResponse(remoteResponse);
        return;
      }

      setState(() {
        _error = 'Failed to load user data';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Error fetching user data: $e';
        _isLoading = false;
      });
    }
  }

  Future<http.Response> _fetchFromApi(String apiUrl, int targetUserId) {
    return http.get(
      Uri.parse('$apiUrl/api/users/$targetUserId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
  }

  void _handleSuccessResponse(http.Response response) {
    final userData = json.decode(response.body);
    if (userData != null) {
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'User not found';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor:
            widget.isDarkMode ? Colors.grey[900] : Colors.blue.shade400,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile Info',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _userData['images_profile'] != null 
                            ? MemoryImage(base64Decode(_userData['images_profile'].split(',')[1]))
                            : const AssetImage('./images/default-profile.jpg') as ImageProvider,
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: Icon(Icons.person,
                            color:
                                widget.isDarkMode ? Colors.white : Colors.blue),
                        title: Text(
                          'Username',
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.grey
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _userData['username'] ?? '',
                          style: TextStyle(
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.phone,
                            color:
                                widget.isDarkMode ? Colors.white : Colors.blue),
                        title: Text(
                          'Phone',
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.grey
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _userData['nomor_hp'] ?? '',
                          style: TextStyle(
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.info_outline,
                            color:
                                widget.isDarkMode ? Colors.white : Colors.blue),
                        title: Text(
                          'About',
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.grey
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _userData['about'] ??
                              'Hey there! I am using this chat app.',
                          style: TextStyle(
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'isichat.dart';

class KontakPage extends StatefulWidget {
  final bool isDarkMode;

  const KontakPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _KontakPageState createState() => _KontakPageState();
}

class _KontakPageState extends State<KontakPage> {
  List<dynamic> _users = [];
  late int _loggedInUserId;
  bool _isLoading = true;
  String _error = '';
  String get apiUrl => Config.isLocal ? Config.localApiUrl : Config.remoteApiUrl;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userIdStr = prefs.getString('userId');
      if (userIdStr != null) {
        setState(() {
          _loggedInUserId = int.parse(userIdStr);
        });
        await _fetchUsers();
      } else {
        setState(() {
          _error = 'User ID tidak ditemukan';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading user ID: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Filter out the logged in user
            _users = data.where((user) => user['id_users'] != _loggedInUserId).toList();
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load users: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    await _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.blue.shade400,
        title: Text(
          'Daftar Kontak',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: _refreshUsers,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshUsers,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _users.isEmpty 
            ? Center(
                child: Text(
                  'Tidak ada kontak',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshUsers,
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: FutureBuilder<http.Response>(
                          future: http.get(Uri.parse('$apiUrl/api/users/${user['id_users']}')),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                              final userData = json.decode(snapshot.data!.body);
                              final profileImage = userData['images_profile'];
                              
                              return CircleAvatar(
                                backgroundImage: profileImage != null 
                                    ? MemoryImage(base64Decode(profileImage.replaceFirst('data:image/jpeg;base64,', '')))
                                    : const AssetImage('./images/default-profile.jpg') as ImageProvider,
                                radius: 20,
                              );
                            }
                            return CircleAvatar(
                              backgroundColor: widget.isDarkMode ? Colors.grey[800] : Colors.blue[100],
                              child: Text(
                                user['username'][0].toUpperCase(),
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        title: Text(
                          user['username'],
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'No HP: ${user['nomor_hp']}',
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IsiChatPage(
                                isDarkMode: widget.isDarkMode,
                                userName: user['username'],
                                userId: user['id_users'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:Kokit/pages/call.dart';
import 'package:Kokit/pages/community.dart';
import '../pages/about.dart';
import '../pages/call.dart';
import '../pages/chat.dart';
import '../pages/community.dart';
import '../pages/group.dart';
import '../pages/status.dart';
import '../pages/event.dart';
import '../pages/journal.dart';
import 'auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class DashboardPage extends StatefulWidget {
  final int userId;
  const DashboardPage({Key? key, required this.userId}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isDarkMode = false;
  String username = '';
  String phoneNumber = '';
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      
      if (userId == null) {
        print('User ID not found in SharedPreferences');
        return;
      }

      // Try local API first
      try {
        final response = await http.get(Uri.parse('${Config.localApiUrl}/api/users/$userId'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            username = data['username'] ?? '';
            phoneNumber = data['nomor_hp'] ?? '';
            profileImageUrl = data['images_profile'];
          });
          return;
        }
      } catch (e) {
        print('Local API error: $e');
      }

      // If local fails, try remote API
      try {
        final response = await http.get(Uri.parse('${Config.remoteApiUrl}/api/users/$userId'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            username = data['username'] ?? '';
            phoneNumber = data['nomor_hp'] ?? '';
            profileImageUrl = data['images_profile'];
          });
          return;
        }
      } catch (e) {
        print('Remote API error: $e');
      }

    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  ImageProvider _getProfileImage() {
    if (profileImageUrl != null && profileImageUrl!.startsWith('data:image')) {
      String base64Image = profileImageUrl!.split(',')[1];
      return MemoryImage(base64Decode(base64Image));
    }
    return const AssetImage('./images/default-profile.jpg');
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('KoKit', 
            style: TextStyle(
              fontSize: 18, 
              color: isDarkMode ? Colors.white : Colors.black
            )
          ),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue.shade400,
          iconTheme: IconThemeData(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, size: 20),
              onPressed: toggleTheme,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? userId = prefs.getString('userId');
                if (userId != null) {
                  // Try local API first
                  try {
                    final response = await http.post(
                      Uri.parse('${Config.localApiUrl}/api/logout/$userId')
                    );
                    if (response.statusCode == 200) {
                      await prefs.remove('userId');
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                      );
                      return;
                    }
                  } catch (e) {
                    print('Local logout failed: $e');
                  }

                  // If local fails, try remote API
                  try {
                    final response = await http.post(
                      Uri.parse('${Config.remoteApiUrl}/api/logout/$userId')
                    );
                    if (response.statusCode == 200) {
                      await prefs.remove('userId');
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                      );
                      return;
                    }
                  } catch (e) {
                    print('Remote logout failed: $e');
                  }
                }
              },
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(username, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                accountEmail: Text(phoneNumber, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)),
                currentAccountPicture: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AboutPage(
                          username: username,
                          isDarkMode: isDarkMode,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: _getProfileImage(),
                    radius: 30,
                  ),
                ),
                otherAccountsPictures: [
                  IconButton(
                    icon: const Icon(Icons.qr_code, color: Colors.white, size: 30),
                    onPressed: () {
                      // Add QR code functionality here
                    },
                  ),
                ],
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.blue.shade400,
                ),
              ),
              ListTile(
                leading: Icon(Icons.person, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Profile', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {},
              ),
             
              ListTile(
                leading: Icon(Icons.event, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Events', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventPage(isDarkMode: isDarkMode),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.book, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Journal', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalPage(isDarkMode: isDarkMode),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Notifications', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  // Implement notifications settings
                },
              ),
              ListTile(
                leading: Icon(Icons.security, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Privacy', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  // Implement privacy settings
                },
              ),
              ListTile(
                leading: Icon(Icons.storage, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Storage and Data', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  // Implement storage settings
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Help', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  // Implement help functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('About', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  // Implement about functionality
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.share, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Invite Friends', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  // Implement invite functionality
                },
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChatPage(isDarkMode: isDarkMode, userId: widget.userId),
            StatusPage(isDarkMode: isDarkMode),
            CommunityPage(isDarkMode: isDarkMode),
            EventPage(isDarkMode: isDarkMode),
            JournalPage(isDarkMode: isDarkMode),
          ],
        ),
        bottomNavigationBar: Container(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          height: 60,
          child: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.chat, size: 20), text: 'Chat'),
              Tab(icon: Icon(Icons.circle, size: 20), text: 'Status'),
              Tab(icon: Icon(Icons.group, size: 20), text: 'Community'),
              Tab(icon: Icon(Icons.event, size: 20), text: 'Event'),
              Tab(icon: Icon(Icons.book, size: 20), text: 'Journal'),
            ],
            labelColor: isDarkMode ? Colors.white : Colors.blue.shade400,
            unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey,
            labelStyle: const TextStyle(fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

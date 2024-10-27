import 'package:flutter/material.dart';
import 'package:project_chatapp_flutter/pages/call.dart';
import 'package:project_chatapp_flutter/pages/community.dart';
import '../pages/chat.dart';
import '../pages/status.dart';
import 'auth.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);
  
  get userId => null;

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isDarkMode = false;
  
  get userId => null;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
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
                accountName: Text('John Doe', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                accountEmail: Text('johndoe@example.com', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage('assets/profile_picture.jpg'),
                  radius: 30,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.blue.shade400,
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Settings', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                },
              ),
              ListTile(
                leading: Icon(Icons.info, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('About', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                },
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChatPage(isDarkMode: isDarkMode, userId: widget.userId ?? -1),
            StatusPage(isDarkMode: isDarkMode),
            CommunityPage(isDarkMode: isDarkMode),
            CallPage(isDarkMode: isDarkMode),
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
              Tab(icon: Icon(Icons.call, size: 20), text: 'Call'),
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

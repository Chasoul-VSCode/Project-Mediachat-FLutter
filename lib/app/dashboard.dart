import 'package:flutter/material.dart';
import 'package:project_chatapp_flutter/pages/call.dart';
import 'package:project_chatapp_flutter/pages/community.dart';
import '../pages/chat.dart';
import '../pages/status.dart';
import 'auth.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isDarkMode = false;

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
          title: Text('Media Chat', 
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
              icon: Icon(Icons.logout, size: 20),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => AuthPage()),
                );
              },
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: Colors.grey[900],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('John Doe', style: TextStyle(fontSize: 14, color: Colors.white)),
                accountEmail: Text('johndoe@example.com', style: TextStyle(fontSize: 12, color: Colors.white70)),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: AssetImage('assets/profile_picture.jpg'),
                  radius: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings, size: 20, color: Colors.white),
                title: Text('Settings', style: TextStyle(fontSize: 14, color: Colors.white)),
                onTap: () {
                },
              ),
              ListTile(
                leading: Icon(Icons.info, size: 20, color: Colors.white),
                title: Text('About', style: TextStyle(fontSize: 14, color: Colors.white)),
                onTap: () {
                },
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChatPage(isDarkMode: isDarkMode),
            StatusPage(isDarkMode: isDarkMode),
            CommunityPage(isDarkMode: isDarkMode),
            CallPage(isDarkMode: isDarkMode),
          ],
        ),
        bottomNavigationBar: Container(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          height: 60,
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat, size: 20), text: 'Chat'),
              Tab(icon: Icon(Icons.circle, size: 20), text: 'Status'),
              Tab(icon: Icon(Icons.group, size: 20), text: 'Community'),
              Tab(icon: Icon(Icons.call, size: 20), text: 'Call'),
            ],
            labelColor: isDarkMode ? Colors.white : Colors.blue.shade400,
            unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey,
            labelStyle: TextStyle(fontSize: 12),
            unselectedLabelStyle: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

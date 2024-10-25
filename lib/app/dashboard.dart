import 'package:flutter/material.dart';
import 'package:project_chatapp_flutter/pages/call.dart';
import 'package:project_chatapp_flutter/pages/community.dart';
import '../pages/chat.dart';
import '../pages/status.dart';
import 'auth.dart'; // Import the auth.dart file

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media Chat'),
          backgroundColor: Colors.blue.shade400,
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => AuthPage()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('John Doe'),
                accountEmail: Text('johndoe@example.com'),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: AssetImage('assets/profile_picture.jpg'),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  // TODO: Implement settings functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap: () {
                  // TODO: Implement about functionality
                },
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChatPage(),
            StatusPage(),
            CommunityPage(),
            CallPage(),
          ],
        ),
        bottomNavigationBar: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.circle), text: 'Status'),
            Tab(icon: Icon(Icons.group), text: 'Community'),
            Tab(icon: Icon(Icons.call), text: 'Call'),
          ],
          labelColor: Colors.blue.shade400,
          unselectedLabelColor: Colors.grey,
        ),
      ),
    );
  }
}

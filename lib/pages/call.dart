import 'package:flutter/material.dart';

class CallPage extends StatelessWidget {
  const CallPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.link, color: Colors.white),
            ),
            title: Text('Create call link'),
            subtitle: Text('Share a link for your WhatsApp call'),
            onTap: () {
              // TODO: Implement create call link functionality
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          _buildCallItem('John Doe', Icons.call_made, Colors.green, '10 minutes ago'),
          _buildCallItem('Jane Smith', Icons.call_received, Colors.red, '25 minutes ago'),
          _buildCallItem('Mike Johnson', Icons.call_missed, Colors.red, '1 hour ago'),
          _buildCallItem('Sarah Williams', Icons.videocam, Colors.blue, 'Yesterday, 8:30 PM'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new call functionality
        },
        child: Icon(Icons.add_call),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildCallItem(String name, IconData icon, Color iconColor, String time) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage('https://via.placeholder.com/150?text=$name'),
      ),
      title: Text(name),
      subtitle: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          SizedBox(width: 4),
          Text(time),
        ],
      ),
      trailing: Icon(Icons.call, color: Colors.green),
      onTap: () {
        // TODO: Implement call functionality
      },
    );
  }
}

import 'package:flutter/material.dart';

class CallPage extends StatelessWidget {
  final bool isDarkMode;

  const CallPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              radius: 16,
              child: Icon(Icons.link, color: Colors.white, size: 18),
            ),
            title: Text('Create call link', style: TextStyle(fontSize: 14, color: textColor)),
            subtitle: Text('Share a link for your WhatsApp call', style: TextStyle(fontSize: 12, color: subtitleColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Recent',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: subtitleColor,
                fontSize: 13,
              ),
            ),
          ),
          _buildCallItem('John Doe', Icons.call_made, Colors.green, '10 minutes ago', isDarkMode),
          _buildCallItem('Jane Smith', Icons.call_received, Colors.red, '25 minutes ago', isDarkMode),
          _buildCallItem('Mike Johnson', Icons.call_missed, Colors.red, '1 hour ago', isDarkMode),
          _buildCallItem('Sarah Williams', Icons.videocam, Colors.blue, 'Yesterday, 8:30 PM', isDarkMode),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green,
        mini: true,
        child: Icon(Icons.add_call, size: 20),
      ),
    );
  }

  Widget _buildCallItem(String name, IconData icon, Color iconColor, String time, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage('https://via.placeholder.com/150?text=$name'),
        radius: 18,
      ),
      title: Text(name, style: TextStyle(fontSize: 14, color: textColor)),
      subtitle: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(time, style: TextStyle(fontSize: 12, color: subtitleColor)),
        ],
      ),
      trailing: const Icon(Icons.call, color: Colors.green, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onTap: () {},
    );
  }
}

import 'package:flutter/material.dart';

class StatusPage extends StatelessWidget {
  final bool isDarkMode;

  const StatusPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: ListView(
        children: [
          ListTile(
            leading: Stack(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage('assets/default_profile.png'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.tealAccent[400] : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: isDarkMode ? Colors.black : Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            title: Text('My Status', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
            subtitle: Text('Tap to add status update', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
            onTap: () {
              // Add status update logic
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Recent updates',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          _buildStatusItem('John Doe', '10 minutes ago'),
          _buildStatusItem('Jane Smith', '25 minutes ago'),
          _buildStatusItem('Mike Johnson', '1 hour ago'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new status logic
        },
        backgroundColor: isDarkMode ? Colors.tealAccent[400] : Colors.blue,
        mini: true,
        child: const Icon(Icons.add, size: 20),
      ),
    );
  }

  Widget _buildStatusItem(String name, String time) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage('https://via.placeholder.com/150?text=$name'),
      ),
      title: Text(name, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
      subtitle: Text(time, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
      onTap: () {
        // View status logic
      },
      dense: true,
    );
  }
}

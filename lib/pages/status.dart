import 'package:flutter/material.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/default_profile.png'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            title: Text('My Status'),
            subtitle: Text('Tap to add status update'),
            onTap: () {
              // TODO: Implement add status functionality
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent updates',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          _buildStatusItem('John Doe', '10 minutes ago'),
          _buildStatusItem('Jane Smith', '25 minutes ago'),
          _buildStatusItem('Mike Johnson', '1 hour ago'),
          // Add more status items as needed
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add new story functionality
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatusItem(String name, String time) {
    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage('https://via.placeholder.com/150?text=$name'),
      ),
      title: Text(name),
      subtitle: Text(time),
      onTap: () {
        // TODO: Implement view status functionality
      },
    );
  }
}

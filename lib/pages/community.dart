import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  final bool isDarkMode;

  const CommunityPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.people, color: Colors.white, size: 20),
            ),
            title: Text('New community', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {},
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          Divider(height: 1, color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),
          _buildCommunityItem(
            'Flutter Developers',
            'You, John, Jane: Hello everyone!',
            'https://via.placeholder.com/150?text=Flutter',
          ),
          _buildCommunityItem(
            'Local Neighborhood',
            'Admin: Welcome to our community!',
            'https://via.placeholder.com/150?text=Local',
          ),
          _buildCommunityItem(
            'Book Club',
            'Sarah: What\'s our next book?',
            'https://via.placeholder.com/150?text=Books',
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityItem(String name, String lastMessage, String imageUrl) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
        radius: 20,
      ),
      title: Text(name, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
      ),
      childrenPadding: EdgeInsets.symmetric(horizontal: 16),
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            child: Icon(Icons.announcement, color: isDarkMode ? Colors.grey[300] : Colors.grey[700], size: 18),
            radius: 18,
          ),
          title: Text('Announcements', style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black)),
          onTap: () {},
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            child: Icon(Icons.group, color: isDarkMode ? Colors.grey[300] : Colors.grey[700], size: 18),
            radius: 18,
          ),
          title: Text('General Group', style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black)),
          onTap: () {},
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
        ListTile(
          leading: Icon(Icons.add_circle, color: Colors.teal, size: 18),
          title: Text('Create new group', style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black)),
          onTap: () {},
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }
}

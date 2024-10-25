import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.people, color: Colors.white),
            ),
            title: Text('New community'),
            onTap: () {
              // TODO: Implement new community creation
            },
          ),
          Divider(),
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
      ),
      title: Text(name),
      subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.announcement, color: Colors.grey[700]),
          ),
          title: Text('Announcements'),
          onTap: () {
            // TODO: Navigate to announcements
          },
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.group, color: Colors.grey[700]),
          ),
          title: Text('General Group'),
          onTap: () {
            // TODO: Navigate to general group
          },
        ),
        ListTile(
          leading: Icon(Icons.add_circle, color: Colors.teal),
          title: Text('Create new group'),
          onTap: () {
            // TODO: Implement new group creation
          },
        ),
      ],
    );
  }
}

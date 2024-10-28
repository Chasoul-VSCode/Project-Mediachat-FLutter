import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroupPage extends StatefulWidget {
  final bool isDarkMode;
  final int userId;

  const GroupPage({Key? key, required this.isDarkMode, required this.userId}) : super(key: key);

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  List<dynamic> _groups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://chasouluix.my.id:3000/api/groups/user/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _groups = data['data'];
        });
      }
    } catch (e) {
      // Handle error
      print('Error fetching groups: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://chasouluix.my.id:3000/api/groups'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_users': widget.userId,
          'name_groups': _groupNameController.text,
        }),
      );

      if (response.statusCode == 201) {
        _groupNameController.clear();
        _fetchGroups(); // Refresh the list
      }
    } catch (e) {
      print('Error creating group: $e');
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? Colors.grey[850] : Colors.white,
        title: Text(
          'Create New Group',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: _groupNameController,
          decoration: InputDecoration(
            hintText: 'Enter group name',
            hintStyle: TextStyle(
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _createGroup();
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      group['name_groups'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    group['name_groups'],
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black
                    ),
                  ),
                  subtitle: Text(
                    'Created: ${group['date'] ?? 'Unknown'}',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]
                    ),
                  ),
                  onTap: () {
                    // TODO: Navigate to group chat
                  },
                );
              },
            ),
    );
  }
}

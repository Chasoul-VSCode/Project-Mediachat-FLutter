// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'isichat.dart';

class ChatPage extends StatefulWidget {
  final bool isDarkMode;
  final int userId;

  const ChatPage({Key? key, required this.isDarkMode, required this.userId}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSearchVisible = false;
  List<dynamic> _chats = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _fetchChats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _fetchChats() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.7:3000/api/chats'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _chats = data['data'];
        });
      } else {
        // Handle error
        print('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isDarkMode ? Colors.white70 : Colors.blue.shade400;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final Color backgroundColor = widget.isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleSearch,
                  child: Icon(Icons.search, color: iconColor, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizeTransition(
                    sizeFactor: _animation,
                    axis: Axis.horizontal,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
                      ),
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ),
                ),
                Icon(Icons.archive, color: iconColor, size: 20),
              ],
            ),
          ),
          Expanded(
            child: _buildChatTab(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new chat functionality
        },
        backgroundColor: iconColor,
        mini: true,
        child: const Icon(Icons.add, size: 20),
      ),
    );
  }

  Widget _buildChatTab() {
    return ListView.builder(
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://via.placeholder.com/150?text=${chat['username']}'),
            radius: 20,
          ),
          title: Text(chat['username'], style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text(chat['chat'], style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
          trailing: Text(chat['date'], style: TextStyle(fontSize: 10, color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IsiChatPage(
                  isDarkMode: widget.isDarkMode,
                  userName: chat['username'], userId: widget.userId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

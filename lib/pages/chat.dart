// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'isichat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'kontak.dart'; // Add this import for date formatting

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
  late int _loggedInUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _loadUserId();
    
    // Setup periodic timer to refresh chats every 3 seconds
    Future.delayed(Duration.zero, () {
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    // Refresh every 3 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false; // Stop if widget is disposed
      await _fetchChats();
      return true; // Continue the loop
    });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _loggedInUserId = int.parse(prefs.getString('userId') ?? '0');
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
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(Uri.parse('http://chasouluix.my.id:3000/api/chats'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allChats = data['data'] as List;
        
        // Filter out chats from the logged-in user
        final filteredChats = allChats.where((chat) => 
          chat['id_users'] != _loggedInUserId
        ).toList();

        // Remove duplicates based on id_users, keeping only the most recent chat
        final Map<int, dynamic> uniqueChats = {};
        for (var chat in filteredChats) {
          final userId = chat['id_users'];
          if (!uniqueChats.containsKey(userId) || 
              DateTime.parse(chat['date']).isAfter(DateTime.parse(uniqueChats[userId]['date']))) {
            uniqueChats[userId] = chat;
          }
        }

        if (mounted) { // Check if widget is still mounted before setState
          setState(() {
            _chats = uniqueChats.values.toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // Handle error
        print('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error fetching chats: $e');
    }
  }

  Future<void> _deleteChat(int chatId) async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.delete(
        Uri.parse('http://chasouluix.my.id:3000/api/chats/$chatId'),
      );

      if (response.statusCode == 200) {
        // Remove the deleted chat from local state first
        setState(() {
          _chats.removeWhere((chat) => chat['id_chat'] == chatId);
        });
        // Then refresh the chat list
        await _fetchChats();
      } else {
        print('Failed to delete chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting chat: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildChatTab(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KontakPage(isDarkMode: widget.isDarkMode),
            ),
          );
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
        final DateTime chatDate = DateTime.parse(chat['date']);
        final String formattedTime = DateFormat('HH:mm').format(chatDate); // Format time as HH:mm
        return Dismissible(
          key: Key(chat['id_chat'].toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                  title: Text(
                    'Konfirmasi',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  content: Text(
                    'Apakah Anda yakin ingin menghapus chat ini?',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Hapus'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            _deleteChat(chat['id_chat']);
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/150?text=${chat['username']}'),
              radius: 20,
            ),
            title: Text(chat['username'], style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white : Colors.black)),
            subtitle: Text(chat['chat'], style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
            trailing: Text(formattedTime, style: TextStyle(fontSize: 10, color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IsiChatPage(
                    isDarkMode: widget.isDarkMode,
                    userName: chat['username'], 
                    userId: chat['id_users'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

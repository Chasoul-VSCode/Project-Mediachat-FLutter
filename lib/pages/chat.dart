// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'isichat.dart';
import 'kontak.dart';

class ChatPage extends StatefulWidget {
  final bool isDarkMode;
  final int userId;

  const ChatPage({
    Key? key, 
    required this.isDarkMode, 
    required this.userId
  }) : super(key: key);

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
  final Map<int, int> _unreadMessages = {};
  final Map<int, bool> _messageReadStatus = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _loadUserId();
    
    Future.delayed(Duration.zero, () {
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      await _fetchChats();
      return true;
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUserId = int.parse(prefs.getString('userId') ?? '0');
    });
    await _fetchChats();
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

      final response = await http.get(
        Uri.parse('http://192.168.1.7:3000/api/chats')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allChats = data['data'] as List;
        
        // Filter chats where for_users matches logged in user ID
        final filteredChats = allChats.where((chat) => 
          chat['for_users'] == _loggedInUserId
        ).toList();

        filteredChats.sort((a, b) => 
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']))
        );

        _unreadMessages.clear();
        _messageReadStatus.clear();
        
        for (var chat in filteredChats) {
          final userId = chat['id_users'];
          if (chat['read'] == false) {
            _unreadMessages[userId] = (_unreadMessages[userId] ?? 0) + 1;
            _messageReadStatus[chat['id_chat']] = false;
          } else {
            _messageReadStatus[chat['id_chat']] = true;
          }
        }

        final Map<int, dynamic> uniqueChats = {};
        for (var chat in filteredChats) {
          final userId = chat['id_users'];
          if (!uniqueChats.containsKey(userId)) {
            uniqueChats[userId] = chat;
          }
        }

        if (mounted) {
          setState(() {
            _chats = uniqueChats.values.toList()
              ..sort((a, b) => 
                DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']))
              );
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        debugPrint('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error fetching chats: $e');
    }
  }

  Future<void> _deleteChat(int chatId) async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.delete(
        Uri.parse('http://192.168.1.7:3000/api/chats/$chatId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _chats.removeWhere((chat) => chat['id_chat'] == chatId);
        });
        await _fetchChats();
      } else {
        debugPrint('Failed to delete chat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
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
    final iconColor = widget.isDarkMode ? Colors.white70 : Colors.blue.shade400;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = widget.isDarkMode ? Colors.black : Colors.white;

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
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 14, 
                          color: textColor.withOpacity(0.6)
                        ),
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
        final chatDate = DateTime.parse(chat['date']).toLocal().add(const Duration(hours: 24)); // Konversi ke waktu Jakarta (UTC+7)
        final formattedTime = DateFormat('HH:mm').format(chatDate);
        final unreadCount = _unreadMessages[chat['id_users']] ?? 0;
        final isRead = _messageReadStatus[chat['id_chat']] ?? false;
        
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
            return await showDialog<bool>(
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
              backgroundImage: NetworkImage(
                'https://via.placeholder.com/150?text=${chat['username']}'
              ),
              radius: 20,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    chat['username'], 
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.white : Colors.black
                    )
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Icon(
                  isRead ? Icons.done_all : Icons.done,
                  size: 16,
                  color: isRead ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    chat['chat'],
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54
                    )
                  ),
                ),
              ],
            ),
            trailing: Text(
              formattedTime,
              style: TextStyle(
                fontSize: 10,
                color: widget.isDarkMode ? Colors.white70 : Colors.black54
              )
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4
            ),
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

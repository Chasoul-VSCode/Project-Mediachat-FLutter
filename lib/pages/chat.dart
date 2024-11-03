// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
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
  int _lastMessageCount = 0;
  final RefreshController _refreshController = RefreshController();

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
      _startCheckNewMessages();
    });
  }

  void _startCheckNewMessages() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      // Check for new messages without updating UI
      final hasNewMessages = await _checkNewMessages();
      if (hasNewMessages) {
        await _fetchChats(); // Only fetch if there are new messages
      }
      
      return true;
    });
  }

  Future<bool> _checkNewMessages() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.localApiUrl}/api/chats'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allChats = data['data'] as List;
        final currentMessageCount = allChats.where((chat) =>
          chat['for_users'] == _loggedInUserId || chat['id_users'] == _loggedInUserId
        ).length;

        if (currentMessageCount != _lastMessageCount) {
          _lastMessageCount = currentMessageCount;
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking new messages: $e');
    }
    return false;
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
    _refreshController.dispose();
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

  Future<void> _onRefresh() async {
    await _fetchChats();
    _refreshController.refreshCompleted();
  }

  Future<void> _fetchChats() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Try local API first
      final localResponse = await http.get(
        Uri.parse('${Config.localApiUrl}/api/chats'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (localResponse.statusCode == 200) {
        _handleChatsResponse(localResponse);
        return;
      }

      // If local fails, try remote API
      final remoteResponse = await http.get(
        Uri.parse('${Config.remoteApiUrl}/api/chats'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (remoteResponse.statusCode == 200) {
        _handleChatsResponse(remoteResponse);
        return;
      }

      debugPrint('Failed to load chats: ${remoteResponse.statusCode}');
      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error fetching chats: $e');
    }
  }

  void _handleChatsResponse(http.Response response) {
    final data = json.decode(response.body);
    final allChats = data['data'] as List;
    
    // Filter chats where either for_users or id_users matches logged in user ID
    final filteredChats = allChats.where((chat) => 
      chat['for_users'] == _loggedInUserId || chat['id_users'] == _loggedInUserId
    ).toList();

    filteredChats.sort((a, b) => 
      DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']))
    );

    _unreadMessages.clear();
    _messageReadStatus.clear();
    
    for (var chat in filteredChats) {
      final otherUserId = chat['id_users'] == _loggedInUserId ? chat['for_users'] : chat['id_users'];
      if (chat['read'] == false && chat['for_users'] == _loggedInUserId) {
        _unreadMessages[otherUserId] = (_unreadMessages[otherUserId] ?? 0) + 1;
        _messageReadStatus[chat['id_chat']] = false;
      } else {
        _messageReadStatus[chat['id_chat']] = true;
      }
    }

    final Map<int, dynamic> uniqueChats = {};
    for (var chat in filteredChats) {
      final otherUserId = chat['id_users'] == _loggedInUserId ? chat['for_users'] : chat['id_users'];
      if (!uniqueChats.containsKey(otherUserId)) {
        uniqueChats[otherUserId] = {
          ...chat,
          'display_user_id': otherUserId // Store the ID of the other user for display
        };
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
  }

  Future<void> _deleteChat(int chatId) async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Try local API first
      final localResponse = await http.delete(
        Uri.parse('${Config.localApiUrl}/api/chats/$chatId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (localResponse.statusCode == 200) {
        _handleDeleteSuccess(chatId);
        return;
      }

      // If local fails, try remote API
      final remoteResponse = await http.delete(
        Uri.parse('${Config.remoteApiUrl}/api/chats/$chatId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (remoteResponse.statusCode == 200) {
        _handleDeleteSuccess(chatId);
        return;
      }

      debugPrint('Failed to delete chat: ${remoteResponse.statusCode}');

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

  void _handleDeleteSuccess(int chatId) {
    setState(() {
      _chats.removeWhere((chat) => chat['id_chat'] == chatId);
    });
    _fetchChats();
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
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _buildChatTab(),
                ),
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
        final chatDate = DateTime.parse(chat['date']).toLocal().add(const Duration(hours: 24));
        final formattedTime = DateFormat('HH:mm').format(chatDate);
        final unreadCount = _unreadMessages[chat['display_user_id']] ?? 0;
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
            leading: Stack(
              children: [
                FutureBuilder<http.Response>(
                  future: _fetchUserData(chat['display_user_id']),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                      final userData = json.decode(snapshot.data!.body);
                      final profileImage = userData['images_profile'];
                      
                      return CircleAvatar(
                        backgroundImage: profileImage != null 
                            ? MemoryImage(base64Decode(profileImage.split(',')[1]))
                            : const AssetImage('./images/default-profile.jpg') as ImageProvider,
                        radius: 20,
                      );
                    }
                    return const CircleAvatar(
                      backgroundImage: AssetImage('./images/default-profile.jpg'),
                      radius: 20,
                    );
                  },
                ),
                FutureBuilder<http.Response>(
                  future: _fetchUserData(chat['display_user_id']),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                      final userData = json.decode(snapshot.data!.body);
                      final bool isOnline = userData['status'].toString() == '1';
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isDarkMode ? Colors.grey[900]! : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: FutureBuilder<http.Response>(
                    future: _fetchUserData(chat['display_user_id']),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                        final userData = json.decode(snapshot.data!.body);
                        return Text(
                          userData['username'] ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDarkMode ? Colors.white : Colors.black
                          )
                        );
                      }
                      return Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDarkMode ? Colors.white : Colors.black
                        )
                      );
                    }
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
            onTap: () async {
              final response = await _fetchUserData(chat['display_user_id']);
              
              if (response.statusCode == 200) {
                final userData = json.decode(response.body);
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IsiChatPage(
                      isDarkMode: widget.isDarkMode,
                      userName: userData['username'] ?? 'Unknown User',
                      userId: chat['display_user_id'],
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<http.Response> _fetchUserData(int userId) async {
    // Try local API first
    try {
      final localResponse = await http.get(
        Uri.parse('${Config.localApiUrl}/api/users/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (localResponse.statusCode == 200) {
        return localResponse;
      }

      // If local fails, try remote API
      final remoteResponse = await http.get(
        Uri.parse('${Config.remoteApiUrl}/api/users/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      return remoteResponse;
    } catch (e) {
      // Return a fake response with error status
      return http.Response('{"error": "Failed to fetch user data"}', 500);
    }
  }
}

class RefreshController {
  void refreshCompleted() {}
  
  void dispose() {}
}

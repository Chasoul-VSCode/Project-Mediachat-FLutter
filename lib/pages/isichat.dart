import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsiChatPage extends StatefulWidget {
  final String userName;
  final bool isDarkMode;
  final int userId;

  const IsiChatPage({Key? key, required this.userName, required this.isDarkMode, required this.userId}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _IsiChatPageState createState() => _IsiChatPageState();
}

class _IsiChatPageState extends State<IsiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late int _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchChatMessages();
    // Start auto refresh when page initializes
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Refresh every 3 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false; // Stop if widget is disposed
      await _fetchChatMessages();
      return true; // Continue the loop
    });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') != null
          ? int.parse(prefs.getString('userId')!)
          : widget.userId;
    });
  }

  Future<void> _fetchChatMessages() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.7:3000/api/chats'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'Chats fetched successfully') {
          final chatsData = data['data'] as List;
          setState(() {
            _messages.clear(); // Clear existing messages
            for (var chatData in chatsData) {
              // Show messages where either:
              // 1. Current user is sender (id_users == _userId) and recipient is widget.userId (for_users == widget.userId)
              // 2. Current user is recipient (for_users == _userId) and sender is widget.userId (id_users == widget.userId)
              if ((chatData['id_users'] == _userId && chatData['for_users'] == widget.userId) ||
                  (chatData['for_users'] == _userId && chatData['id_users'] == widget.userId)) {
                _messages.add(ChatMessage(
                  text: chatData['chat'],
                  date: DateTime.parse(chatData['date']).toLocal(),
                  isMe: chatData['id_users'] == _userId,
                  isDarkMode: widget.isDarkMode,
                  userName: chatData['username'],
                  chatId: chatData['id_chat'],
                  onDelete: () => _deleteMessage(chatData['id_chat']),
                ));
              }
            }
            _messages.sort((a, b) => b.date.compareTo(a.date)); // Sort messages by date
          });
        }
      } else {
        // Handle error
        print('Failed to fetch chat messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat messages: $e');
    }
  }

  Future<void> _deleteMessage(int chatId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.1.7:3000/api/chats/$chatId'),
      );

      if (response.statusCode == 200) {
        // Message deleted successfully, refresh chat messages
        _fetchChatMessages();
      } else {
        print('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.blue.shade400,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/150?text=${widget.userName}'),
              radius: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.userName,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.video_call, color: widget.isDarkMode ? Colors.white : Colors.black, size: 18),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.call, color: widget.isDarkMode ? Colors.white : Colors.black, size: 18),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: widget.isDarkMode ? Colors.white : Colors.black, size: 18),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: widget.isDarkMode ? Colors.white70 : Colors.blue.shade400, size: 18),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
                border: InputBorder.none,
              ),
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: widget.isDarkMode ? Colors.white70 : Colors.blue.shade400, size: 18),
            onPressed: _handleSubmitted,
          ),
        ],
      ),
    );
  }

  void _handleSubmitted() {
    if (_messageController.text.isNotEmpty) {
      _sendMessage(_messageController.text);
      _messageController.clear();
    }
  }

  Future<void> _sendMessage(String message) async {
    try {
      final jakartaTime = DateTime.now().toUtc().add(const Duration(hours: 7));
      final response = await http.post(
        Uri.parse('http://192.168.1.7:3000/api/chats'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id_users': _userId,
          'chat': message,
          'date': jakartaTime.toIso8601String(),
          'for_users': widget.userId, // Set recipient to the user we're chatting with
        }),
      );

      if (response.statusCode == 201) {
        // Message sent successfully, refresh chat messages
        _fetchChatMessages();
      } else {
        print('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final DateTime date;
  final bool isMe;
  final bool isDarkMode;
  final String userName;
  final int chatId;
  final VoidCallback onDelete;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.date,
    required this.isMe,
    required this.isDarkMode,
    required this.userName,
    required this.chatId,
    required this.onDelete,
  }) : super(key: key);

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            'Hapus Pesan',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus pesan ini?',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) CircleAvatar(radius: 12, child: Text(userName[0])),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      userName,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: isMe ? () => _showDeleteDialog(context) : null,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(maxWidth: 200),
                    decoration: BoxDecoration(
                      color: isMe
                          ? (isDarkMode ? Colors.blue[700] : Colors.blue[100])
                          : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(date),
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 6),
          if (isMe) const CircleAvatar(radius: 12, child: Text('M')),
        ],
      ),
    );
  }
}

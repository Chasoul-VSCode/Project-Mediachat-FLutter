import 'package:flutter/material.dart';

class IsiChatPage extends StatefulWidget {
  final String userName;
  final bool isDarkMode;

  const IsiChatPage({Key? key, required this.userName, required this.isDarkMode}) : super(key: key);

  @override
  _IsiChatPageState createState() => _IsiChatPageState();
}

class _IsiChatPageState extends State<IsiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add example messages
    _messages.addAll([
      ChatMessage(text: "Hi there!", isMe: false, isDarkMode: widget.isDarkMode),
      ChatMessage(text: "Hello! How are you?", isMe: true, isDarkMode: widget.isDarkMode),
      ChatMessage(text: "I'm doing great, thanks for asking. How about you?", isMe: false, isDarkMode: widget.isDarkMode),
      ChatMessage(text: "I'm good too. What are your plans for the weekend?", isMe: true, isDarkMode: widget.isDarkMode),
      ChatMessage(text: "I'm thinking of going hiking. Want to join?", isMe: false, isDarkMode: widget.isDarkMode),
    ]);
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
            SizedBox(width: 8),
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
      padding: EdgeInsets.symmetric(horizontal: 6.0),
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
      ChatMessage message = ChatMessage(
        text: _messageController.text,
        isMe: true,
        isDarkMode: widget.isDarkMode,
      );
      setState(() {
        _messages.insert(0, message);
      });
      _messageController.clear();
    }
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isDarkMode;

  const ChatMessage({Key? key, required this.text, required this.isMe, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) CircleAvatar(child: Text('U'), radius: 12),
          Container(
            padding: EdgeInsets.all(8.0),
            constraints: BoxConstraints(maxWidth: 200),
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
          if (isMe) SizedBox(width: 6),
          if (isMe) CircleAvatar(child: Text('M'), radius: 12),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'isichat.dart'; // Import the IsiChatPage

class ChatPage extends StatefulWidget {
  final bool isDarkMode;

  const ChatPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
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
                SizedBox(width: 8),
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
        },
        child: Icon(Icons.add, size: 20),
        backgroundColor: iconColor,
        mini: true,
      ),
    );
  }

  Widget _buildChatTab() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://via.placeholder.com/150?text=User${index + 1}'),
            radius: 20,
          ),
          title: Text('User ${index + 1}', style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text('Last message from User ${index + 1}', style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
          trailing: Text('12:00 PM', style: TextStyle(fontSize: 10, color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IsiChatPage(
                  isDarkMode: widget.isDarkMode,
                  userName: 'User ${index + 1}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Icon(Icons.search, color: Colors.blue.shade400),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.horizontal,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.archive, color: Colors.blue.shade400),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildChatTab(),
                  Center(child: Text('Status Tab Content')),
                  Center(child: Text('Community Tab Content')),
                  Center(child: Text('Call Tab Content')),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Implement new chat functionality
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
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
          ),
          title: Text('User ${index + 1}'),
          subtitle: Text('Last message from User ${index + 1}'),
          trailing: Text('12:00 PM'),
          onTap: () {
            // TODO: Implement chat detail view
          },
        );
      },
    );
  }
}

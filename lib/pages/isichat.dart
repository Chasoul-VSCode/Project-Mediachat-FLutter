import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'about.dart';

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
  late int _userId; // Changed to late since we'll initialize in initState
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _forUserProfileImage;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId; // Initialize _userId with widget.userId immediately
    _loadUserId(); // Still call this to check for stored userId
    _fetchChatMessages();
    _fetchForUserProfile();
    // Start auto refresh when page initializes
    _startAutoRefresh();
  }

  Future<void> _fetchForUserProfile() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.7:3000/api/users/${widget.userId}'));
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _forUserProfileImage = userData['images_profile'];
        });
      }
    } catch (e) {
      print('Error fetching for_user profile: $e');
    }
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
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userIdStr = prefs.getString('userId');
      if (userIdStr != null) {
        setState(() {
          _userId = int.parse(userIdStr);
        });
      }
    } catch (e) {
      print('Error loading userId: $e');
      // Keep using widget.userId if there's an error
    }
  }

  

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      _showImagePreview();
    }
  }

  void _showImagePreview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            'Preview Image',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _selectedImage != null
                  ? Image.file(_selectedImage!)
                  : const Text('No image selected.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  var request = http.MultipartRequest(
                    'POST',
                    Uri.parse('http://192.168.1.7:3000/api/chats'),
                  );

                  // Ensure _userId is included and not null
                  request.fields['id_users'] = _userId.toString();
                  request.fields['chat'] = 'tidak ada';
                  request.fields['for_users'] = widget.userId.toString();

                  if (_selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No image selected')),
                    );
                    return;
                  }

                  // Buat nama file unik dengan timestamp
                  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                  String extension = path.extension(_selectedImage!.path);
                  String filename = '$timestamp$extension';

                  // Get application documents directory
                  Directory appDocDir = await getApplicationDocumentsDirectory();
                  String imagesPath = '${appDocDir.path}/images';
                  Directory imagesDir = Directory(imagesPath);
                  
                  // Create images directory if it doesn't exist
                  if (!await imagesDir.exists()) {
                    await imagesDir.create(recursive: true);
                  }

                  // Copy file to app documents directory
                  File newImage = await _selectedImage!.copy('$imagesPath/$filename');

                  var multipartFile = await http.MultipartFile.fromPath(
                    'images',
                    newImage.path,
                    filename: filename,
                  );
                  request.files.add(multipartFile);

                  var streamedResponse = await request.send();
                  var response = await http.Response.fromStream(streamedResponse);

                  if (response.statusCode == 201) {
                    final responseData = json.decode(response.body);
                    final jakartaTime = DateTime.now().toUtc().add(const Duration(hours: 7));
                    
                    setState(() {
                      _messages.insert(
                        0,
                        ChatMessage(
                          text: 'Sent an image',
                          date: jakartaTime,
                          isMe: true,
                          isDarkMode: widget.isDarkMode,
                          userName: 'Me', 
                          chatId: responseData['id_chat'],
                          onDelete: () {},
                          imageUrl: 'http://192.168.1.7:3000/images/$filename',
                        ),
                      );
                    });
                    
                    // Refresh messages to show new image with server data
                    _fetchChatMessages();
                  } else {
                    print('Failed to upload image: ${response.statusCode}');
                    print('Response body: ${response.body}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send image: ${response.body}')),
                    );
                  }
                } catch (e) {
                  print('Error uploading image: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sending image: $e')),
                  );
                }

                // Clear selected image
                setState(() {
                  _selectedImage = null;
                });
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadAndSaveImage(File imageFile, String message) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.7:3000/api/chats'),
      );

      // Add text fields using _userId
      request.fields['id_users'] = _userId.toString();
      request.fields['chat'] = 'tidak ada';
      request.fields['for_users'] = widget.userId.toString();

      // Buat nama file unik dengan timestamp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      String filename = '$timestamp$extension';

      // Get application documents directory
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String imagesPath = '${appDocDir.path}/images';
      Directory imagesDir = Directory(imagesPath);
      
      // Create images directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Copy file to app documents directory
      File newImage = await imageFile.copy('$imagesPath/$filename');

      // Add the image file
      var multipartFile = await http.MultipartFile.fromPath(
        'images',
        newImage.path,
        filename: filename,
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _fetchChatMessages(); // Refresh messages to show new image
      } else {
        print('Failed to upload image: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void _addImageMessage(String imageUrl, String message) {
    final jakartaTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: 'Sent an image',
          date: jakartaTime,
          isMe: true,
          isDarkMode: widget.isDarkMode,
          userName: 'Me',
          chatId: 0,
          onDelete: () {},
          imageUrl: imageUrl,
        ),
      );
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
              if ((chatData['id_users'] == _userId && chatData['for_users'] == widget.userId) ||
                  (chatData['for_users'] == _userId && chatData['id_users'] == widget.userId)) {
                String? imageUrl;
                if (chatData['images'] != 'NoImages') {
                  imageUrl = 'http://192.168.1.7:3000/images/${chatData['images']}';
                }
                _messages.add(ChatMessage(
                  text: chatData['chat'],
                  date: DateTime.parse(chatData['date']).toLocal(),
                  isMe: chatData['id_users'] == _userId,
                  isDarkMode: widget.isDarkMode,
                  userName: chatData['username'],
                  chatId: chatData['id_chat'],
                  onDelete: () => _deleteMessage(chatData['id_chat']),
                  imageUrl: imageUrl,
                ));
              }
            }
            _messages.sort((a, b) => b.date.compareTo(a.date));
          });
        }
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
              backgroundImage: _forUserProfileImage != null && _forUserProfileImage!.contains(',')
                  ? MemoryImage(base64Decode(_forUserProfileImage!.split(',')[1]))
                  : const AssetImage('./images/default-profile.jpg') as ImageProvider,
              radius: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  FutureBuilder<http.Response>(
                    future: http.get(Uri.parse('http://192.168.1.7:3000/api/users/${widget.userId}')),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                        final userData = json.decode(snapshot.data!.body);
                        final bool isOnline = userData['status'] == 1;
                        return Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 10,
                            color: isOnline 
                              ? Colors.green 
                              : widget.isDarkMode 
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.7),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutPage(
                    key: null,
                    username: widget.userName,
                    isDarkMode: widget.isDarkMode,
                    userId: widget.userId,
                  ),
                ),
              );
            },
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
            icon: Icon(Icons.camera_alt, color: widget.isDarkMode ? Colors.white70 : Colors.blue.shade400, size: 18),
            onPressed: _pickImage,
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
            icon: Icon(Icons.mic, color: widget.isDarkMode ? Colors.white70 : Colors.blue.shade400, size: 18),
            onPressed: () {
              // TODO: Implement voice note recording functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice note feature coming soon!')),
              );
            },
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
          'for_users': widget.userId,
        }),
      );

      if (response.statusCode == 201) {
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
  final String? imageUrl;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.date,
    required this.isMe,
    required this.isDarkMode,
    required this.userName,
    required this.chatId,
    required this.onDelete,
    this.imageUrl,
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
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) 
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          Image.network(
                            imageUrl!,
                            width: 180,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                        if (text != 'Sent an image')
                          Text(
                            text,
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormat('HH:mm').format(date),
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 6)
        ],
      ),
    );
  }
}

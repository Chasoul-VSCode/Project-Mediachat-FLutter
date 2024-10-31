import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../config.dart';

class StatusPage extends StatefulWidget {
  final bool isDarkMode;

  const StatusPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  List<dynamic> statuses = [];
  String? userId;
  String? username;
  String? profileImageUrl;
  final TextEditingController _captionController = TextEditingController();
  bool isLoading = false;
  String get apiUrl => Config.isLocal ? Config.localApiUrl : Config.remoteApiUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchStatuses();
    
    // Auto refresh every 30 seconds
    Future.delayed(Duration.zero, () {
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      await _fetchStatuses();
      return true;
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      username = prefs.getString('username');
      profileImageUrl = prefs.getString('profileImage');
    });
  }

  Future<void> _fetchStatuses() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            statuses = data.map((status) {
              return {
                'id_status': status['id_status'],
                'id_users': status['id_users'],
                'username': status['username'] ?? 'Unknown',
                'caption': status['caption'],
                'date': status['date'],
                'images_profile': status['images_profile']
              };
            }).toList();
          });
        }
      } else {
        print('Error fetching statuses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching statuses: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _postStatus({String? imagePath, String? caption}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('userId');

      if (currentUserId == null) {
        print('User not logged in');
        return;
      }

      String? base64Image;
      if (imagePath != null) {
        final bytes = await XFile(imagePath).readAsBytes();
        base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final response = await http.post(
        Uri.parse('$apiUrl/api/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_users': currentUserId,
          'images': base64Image ?? 'NoImages',
          'caption': caption ?? ''
        }),
      );

      if (response.statusCode == 201) {
        _fetchStatuses(); // Refresh after posting
      }
    } catch (e) {
      print('Error posting status: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      _showCaptionDialog(imagePath: image.path);
    }
  }

  void _showCaptionDialog({String? imagePath}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Add Caption',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: _captionController,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
            hintText: 'Enter caption...',
            hintStyle: TextStyle(
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captionController.clear();
            },
            child: Text('Cancel', 
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              _postStatus(
                imagePath: imagePath,
                caption: _captionController.text,
              );
              Navigator.pop(context);
              _captionController.clear();
            },
            child: const Text('Post', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.startsWith('data:image')) {
      // Handle base64 image data
      String base64Image = imageUrl.split(',')[1];
      return MemoryImage(base64Decode(base64Image));
    } else if (imageUrl != null && imageUrl != 'NoImages') {
      // Handle image URL
      return NetworkImage('$apiUrl/images/$imageUrl');
    }
    return const AssetImage('./images/default-profile.jpg');
  }

  String _formatTime(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'status',
              mini: true,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.camera_alt, color: Colors.teal, size: 20),
                          title: Text('Add Image',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage();
                          },
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.edit, color: Colors.teal, size: 20),
                          title: Text('Add Caption',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showCaptionDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              backgroundColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.teal,
              elevation: 3,
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStatuses,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My Status Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.teal,
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: _getProfileImage(profileImageUrl),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Status',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to add status update',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Recent Updates Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'Recent updates',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final status = statuses[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.teal,
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: _getProfileImage(status['images_profile']),
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status['username'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            _formatTime(status['date']),
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          status['caption'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      onTap: () {
                        // View status functionality
                      },
                    ),
                  );
                },
                childCount: statuses.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

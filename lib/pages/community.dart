import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'dart:async';

import 'isicommunity.dart';

class CommunityPage extends StatefulWidget {
  final bool isDarkMode;

  const CommunityPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<dynamic> communities = [];
  Map<int, int> communityMemberCounts = {};
  final TextEditingController _communityNameController = TextEditingController();
  late int _loggedInUserId;
  bool _isLoading = false;
  Timer? _timer;
  String _lastUpdateHash = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
    // Set timer to check for updates every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _communityNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUserId = int.parse(prefs.getString('userId') ?? '0');
    });
    await fetchCommunities();
  }

  // Generate hash from communities data
  String _generateHash(List<dynamic> data) {
    return json.encode(data).hashCode.toString();
  }

  // Check for updates without loading indicator
  Future<void> _checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.localApiUrl}/api/communities'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final newCommunities = json.decode(response.body);
        final newHash = _generateHash(newCommunities);
        
        // Only update if data has changed
        if (newHash != _lastUpdateHash) {
          setState(() {
            communities = newCommunities;
            _lastUpdateHash = newHash;
          });
          await _fetchMemberCounts();
        }
      }
    } catch (e) {
      debugPrint('Error checking updates: $e');
    }
  }

  Future<void> _fetchMemberCounts() async {
    try {
      for (var community in communities) {
        final response = await http.get(
          Uri.parse('${Config.localApiUrl}/api/community-members/${community['id']}'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
        );

        if (response.statusCode == 200) {
          final members = json.decode(response.body);
          setState(() {
            communityMemberCounts[community['id']] = members.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching member counts: $e');
    }
  }

  Future<void> fetchCommunities() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.localApiUrl}/api/communities'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final newCommunities = json.decode(response.body);
        final newHash = _generateHash(newCommunities);
        setState(() {
          communities = newCommunities;
          _lastUpdateHash = newHash;
        });
        await _fetchMemberCounts();
      } else {
        debugPrint('Error fetching communities: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching communities: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> createCommunity(String communityName) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.localApiUrl}/api/communities'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'id_users': _loggedInUserId,
          'community_name': communityName,
        }),
      );

      if (response.statusCode == 201) {
        await fetchCommunities();
        _communityNameController.clear();
      } else {
        debugPrint('Error creating community: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating community: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateCommunityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text('Create New Community', 
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        content: TextField(
          controller: _communityNameController,
          decoration: InputDecoration(
            hintText: 'Community Name',
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              if (_communityNameController.text.isNotEmpty) {
                createCommunity(_communityNameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      body: RefreshIndicator(
        onRefresh: fetchCommunities,
        child: ListView(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.people, color: Colors.white, size: 20),
              ),
              title: Text('New community', 
                style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white : Colors.black)),
              onTap: _showCreateCommunityDialog,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            Divider(height: 1, color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (communities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No communities found',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ...communities.map((community) => _buildCommunityItem(
                community['community_name'],
                'Created by: ${community['username']}\nCreated on: ${DateTime.parse(community['date']).toLocal().toString().split(' ')[0]}\nMembers: ${communityMemberCounts[community['id']] ?? 0}',
                community['images_profile'] != null && community['images_profile'].isNotEmpty
                    ? community['images_profile']
                    : 'https://via.placeholder.com/150?text=${community['community_name'].toString().split(' ')[0]}',
                community['id_users'] == _loggedInUserId,
                community['id'] ?? 0,
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityItem(String name, String details, String imageUrl, bool isOwner, int communityId) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
        radius: 20,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name, 
              style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white : Colors.black)
            ),
          ),
          if (isOwner)
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 16,
            ),
        ],
      ),
      subtitle: Text(
        details,
        style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
            radius: 18,
            child: Icon(Icons.announcement, color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700], size: 18),
          ),
          title: Text('Announcements', style: TextStyle(fontSize: 13, color: widget.isDarkMode ? Colors.white : Colors.black)),
          onTap: () {},
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
            radius: 18,
            child: Icon(Icons.group, color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700], size: 18),
          ),
          title: Text('Join Group', style: TextStyle(fontSize: 13, color: widget.isDarkMode ? Colors.white : Colors.black)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IsiCommunityPage(
                  isDarkMode: widget.isDarkMode,
                  communityId: communityId,
                ),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        
      ],
    );
  }
}

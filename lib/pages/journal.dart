import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalPage extends StatefulWidget {
  final bool isDarkMode;

  const JournalPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _contacts = [];
  List<String> _selectedContacts = [];
  bool _isPrivate = true;

  @override
  void initState() {
    super.initState();
    _fetchJournals();
    _fetchContacts();
  }

  Future<void> _fetchJournals() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.localApiUrl}/api/journals/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> journalsJson = json.decode(response.body);
        setState(() {
          _journals = journalsJson.map((journal) => {
            'id_journal': journal['id_journal'].toString(),
            'title': journal['judul'] ?? '',
            'content': journal['isi'] ?? '',
            'isPrivate': journal['for_users'] == null || journal['for_users'] == '0',
            'date': _formatDate(journal['date']),
            'username': journal['username'] ?? '',
          }).toList();
        });
      } else {
        print('Failed to fetch journals: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching journals: $e');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _fetchContacts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.localApiUrl}/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> contactsJson = json.decode(response.body);
        setState(() {
          _contacts = contactsJson.map((contact) => {
            'id': contact['id_users'].toString(),
            'name': contact['username'] ?? '',
          }).toList();
        });
      } else {
        print('Failed to fetch contacts: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  Future<void> _saveJournal() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      String forUsers = _isPrivate ? '0' : _selectedContacts.join(',');

      final response = await http.post(
        Uri.parse('${Config.localApiUrl}/api/journals'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'id_users': userId,
          'judul': _titleController.text,
          'isi': _contentController.text,
          'for_users': forUsers,
        }),
      );

      if (response.statusCode == 201) {
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _isPrivate = true;
          _selectedContacts = [];
        });
        await _fetchJournals();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journal saved successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save journal')),
          );
        }
        print('Failed to save journal: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error saving journal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving journal')),
        );
      }
    }
  }

  void _showAddJournalForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Journal Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, 
                      color: widget.isDarkMode ? Colors.white : Colors.black87
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 8,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Content',
                  labelStyle: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  'Private Entry',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                value: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
              ),
              if (!_isPrivate) ...[
                const SizedBox(height: 8),
                Text(
                  'Share with:',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: _contacts.map((contact) {
                    return FilterChip(
                      label: Text(contact['name']),
                      selected: _selectedContacts.contains(contact['id']),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedContacts.add(contact['id']);
                          } else {
                            _selectedContacts.remove(contact['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveJournal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Journal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddJournalForm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _journals.length,
        itemBuilder: (context, index) {
          final journal = _journals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      journal['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    'by ${journal['username']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    journal['content'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        journal['isPrivate'] ? Icons.lock_outline : Icons.people_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        journal['date'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

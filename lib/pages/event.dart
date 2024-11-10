import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config.dart';
import 'package:intl/intl.dart';

class EventPage extends StatefulWidget {
  final bool isDarkMode;

  const EventPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final _formKey = GlobalKey<FormState>();
  final _isiController = TextEditingController();
  List<Map<String, dynamic>> _events = [];
  String? _userId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchEvents();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _fetchEvents() async {
    try {
      final response = await http.get(Uri.parse('${Config.localApiUrl}/api/events'));
      if (response.statusCode == 200) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final DateTime eventDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final response = await http.post(
          Uri.parse('${Config.localApiUrl}/api/events'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'id_users': _userId,
            'isi': _isiController.text,
            'date': eventDateTime.toIso8601String(),
          }),
        );

        if (response.statusCode == 201) {
          _fetchEvents();
          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Event created successfully'),
              backgroundColor: widget.isDarkMode ? Colors.blueGrey : Colors.blue,
            ),
          );
        }
      } catch (e) {
        print('Error creating event: $e');
      }
    }
  }

  void _clearForm() {
    _isiController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _isiController,
                          decoration: InputDecoration(
                            labelText: 'Event Content',
                            labelStyle: TextStyle(
                              fontSize: 14,
                              color: widget.isDarkMode ? Colors.white70 : Colors.grey[700],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter event content';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectDate(context),
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectTime(context),
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  _selectedTime.format(context),
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _createEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Create',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                child: Text(
                  'All Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              FutureBuilder<http.Response>(
                future: http.get(Uri.parse('${Config.localApiUrl}/api/events')),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading events: ${snapshot.error}',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: Text(
                        'No events found',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    );
                  }
                  final decodedData = json.decode(snapshot.data!.body) as Map<String, dynamic>;
                  final events = (decodedData['data'] ?? []) as List;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            event['username'] ?? 'Anonymous',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: widget.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                event['isi'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(event['date'])),
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isiController.dispose();
    super.dispose();
  }
}

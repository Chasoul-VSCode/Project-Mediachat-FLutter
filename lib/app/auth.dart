// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:project_chatapp_flutter/app/registration.dart';
import 'profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://chasouluix.my.id:3000/api/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'nomor_hp': _phoneController.text,
        'password': _passwordController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      // Login successful
      final responseData = jsonDecode(response.body);
      print('Login successful: ${responseData['message']}');
      
      // Save user ID to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', responseData['user']['id_users'].toString());
      } catch (e) {
        print('Error saving user ID to SharedPreferences: $e');
        // Handle the error, maybe show a message to the user
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } else if (response.statusCode == 401) {
      // Unauthorized - Invalid credentials
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number or password')),
      );
    } else {
      // Other errors
      print('Login failed with status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'KoKit',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Welcome to Komunikasi Kita',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black87),
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        hintStyle: const TextStyle(color: Colors.black54),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.black54),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const RegistrationPage()),
                        );
                      },
                      child: Text(
                        'Don\'t have an account? Sign Up',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

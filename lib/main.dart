import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app/auth.dart';
import 'pages/chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  bool? isDarkMode = prefs.getBool('isDarkMode') ?? false;

  Widget initialPage = const AuthPage();

  if (userId != null) {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.7:3000/api/users/$userId')
      );
      
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        // Check user status
        if (userData['status'] == 1) {
          // Redirect to ChatPage if status is 1
          initialPage = ChatPage(
            userId: int.parse(userId), 
            isDarkMode: isDarkMode
          );
        } else if (userData['status'] == 0) {
          // Redirect to AuthPage if status is 0
          initialPage = const AuthPage();
          // Clear stored userId since we're logging out
          await prefs.remove('userId');
        }
      }
    } catch (e) {
      print('Error checking user status: $e');
    }
  }

  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  
  const MyApp({Key? key, required this.initialPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KoKit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: initialPage,
      debugShowCheckedModeBanner: false,
    );
  }
}

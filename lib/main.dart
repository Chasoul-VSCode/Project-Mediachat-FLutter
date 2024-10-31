import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app/auth.dart';
import 'config.dart';
import 'pages/chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  bool? isDarkMode = prefs.getBool('isDarkMode') ?? false;

  Widget initialPage = const AuthPage();

  if (userId != null) {
    try {
      // Try local API first
      final localResponse = await http.get(
        Uri.parse('${Config.localApiUrl}/api/users/$userId')
      );

      if (localResponse.statusCode == 200) {
        Config.isLocal = true;
        _handleUserResponse(localResponse, userId, isDarkMode, prefs);
      } else if (Config.isLocal == false){
        // If local fails, try remote API
        final remoteResponse = await http.get(
          Uri.parse('${Config.remoteApiUrl}/api/users/$userId')
        );

        if (remoteResponse.statusCode == 200) {
          Config.isLocal = false;
          _handleUserResponse(remoteResponse, userId, isDarkMode, prefs);
        }
      }
    } catch (e) {
      print('Error checking user status: $e');
    }
  }

  runApp(MyApp(initialPage: initialPage));
}

void _handleUserResponse(http.Response response, String userId, bool isDarkMode, SharedPreferences prefs) {
  final userData = json.decode(response.body);
  // Check user status
  if (userData['status'] == 1) {
    // Redirect to ChatPage if status is 1
    var initialPage = ChatPage(
      userId: int.parse(userId),
      isDarkMode: isDarkMode
    );
  } else if (userData['status'] == 0) {
    // Redirect to AuthPage if status is 0
    var initialPage = const AuthPage();
    // Clear stored userId since we're logging out
    prefs.remove('userId');
  }
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

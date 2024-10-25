import 'package:flutter/material.dart';
import 'app/auth.dart'; // Import the auth.dart file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthPage(), // Change the home page to AuthPage
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

// Remove the MyHomePage and _MyHomePageState classes as they are no longer needed

import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const EcoTagApp());
}

class EcoTagApp extends StatelessWidget {
  const EcoTagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(), // first screen
    );
  }
}

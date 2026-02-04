import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_page.dart';
import 'screens/home_page.dart'; // ✅ add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const EcoTagApp());
}

class EcoTagApp extends StatelessWidget {
  const EcoTagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ first screen
      initialRoute: "/",

      // ✅ routes added
      routes: {
        "/": (context) => const LoginPage(),
        "/home": (context) => const HomePage(),
      },
    );
  }
}

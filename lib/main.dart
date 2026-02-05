import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/forgot_password_page.dart';

void main() async {
  // 🔥 REQUIRED
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 THIS FIXES YOUR ERROR
  await Firebase.initializeApp();

  runApp(const EcoTagApp());
}

class EcoTagApp extends StatelessWidget {
  const EcoTagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: "/",

      routes: {
        "/": (context) => LoginPage(),
        "/home": (context) => HomePage(),
        "/signup": (context) => SignupPage(),
        "/forgot": (context) => ForgotPasswordPage(),
      },
    );
  }
}

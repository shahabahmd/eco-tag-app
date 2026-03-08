import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/signup_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/admin_dashboard_page.dart';
import 'screens/admin_verification_page.dart';
import 'screens/splash_screen.dart';

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
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),
        "/signup": (context) => SignupPage(),
        "/home": (context) => HomePage(),
        "/forgot": (context) => ForgotPasswordPage(),
        "/admin_dashboard": (context) => const AdminDashboardPage(),
        "/admin_verification": (context) => const AdminVerificationPage(),
      },
    );
  }
}

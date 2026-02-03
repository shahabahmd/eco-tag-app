import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool hide = true;

  void login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: buildCard()),
      ),
    );
  }

  Widget buildCard() {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco, size: 60, color: Color(0xFF11998e)),

          const SizedBox(height: 20),

          buildField("Email", email),
          const SizedBox(height: 15),

          buildPassword(),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11998e),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Login"),
          ),
          const SizedBox(height: 12),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
        );
      },
      child: const Text(
        "Forgot password?",
        style: TextStyle(
          color: Color(0xFF11998e),
          fontSize: 13,
        ),
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupPage()),
        );
      },
      child: const Text(
        "Create account",
        style: TextStyle(
          color: Color(0xFF11998e),
          fontSize: 13,
        ),
      ),
    ),
  ],
),

        ],
      ),
    );
  }

  Widget buildField(String hint, controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE8F5E9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget buildPassword() {
    return TextField(
      controller: pass,
      obscureText: hide,
      decoration: InputDecoration(
        hintText: "Password",
        filled: true,
        fillColor: const Color(0xFFE8F5E9),
        suffixIcon: IconButton(
          icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => hide = !hide),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

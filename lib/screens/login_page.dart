import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'forgot_password_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool hide = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 🔥🔥 ANDROID SAFE GOOGLE LOGIN (STEP 2 FIX)
  Future<void> signInWithGoogle() async {
    try {
      // open google account picker
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      print("Google login error: $e");
    }
  }

  // normal login (optional)
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

          // ✅ GOOGLE LOGIN BUTTON
          ElevatedButton.icon(
            onPressed: signInWithGoogle,
            icon: const Icon(Icons.login),
            label: const Text("Sign in with Google"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11998e),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage()),
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
                    MaterialPageRoute(
                        builder: (_) => const SignupPage()),
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

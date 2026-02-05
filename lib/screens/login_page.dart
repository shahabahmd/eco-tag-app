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
  bool loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 🔥 AUTO LOGIN (if already logged in)
  @override
  void initState() {
    super.initState();

    if (_auth.currentUser != null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      });
    }
  }

  // ==============================
  // 🔥 EMAIL/PASSWORD LOGIN
  // ==============================
  Future<void> login() async {
    try {
      setState(() => loading = true);

      await _auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      setState(() => loading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);

      String message = "Login failed";

      if (e.code == 'user-not-found') {
        message = "User not found";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ==============================
  // 🔥 GOOGLE LOGIN
  // ==============================
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      print("Google login error: $e");
    }
  }

  // ==============================
  // UI
  // ==============================

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

          // 🔥 EMAIL LOGIN BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11998e),
                foregroundColor: Colors.white,
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),
          ),

          const SizedBox(height: 12),

          // 🔥 GOOGLE LOGIN BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: signInWithGoogle,
              icon: Image.network(
                "https://cdn-icons-png.flaticon.com/512/281/281764.png",
                height: 22,
              ),
              label: const Text(
                "Sign in with Google",
                style: TextStyle(color: Colors.black87),
              ),
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
                  style: TextStyle(color: Color(0xFF11998e)),
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
                  style: TextStyle(color: Color(0xFF11998e)),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
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
          icon:
              Icon(hide ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => hide = !hide),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}

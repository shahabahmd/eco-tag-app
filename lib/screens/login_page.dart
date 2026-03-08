import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'forgot_password_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _kG1         = Color(0xFF4DBB87);
const _kG2         = Color(0xFF7ED6A7);
const _kMint       = Color(0xFFEAF7F0);
const _kOffWhite   = Color(0xFFF8FBF9);
const _kLightGreen = Color(0xFFBFEAD3);
const _kTextDark   = Color(0xFF1D3A2C);
const _kTextMuted  = Color(0xFF7CA48F);
final _kGradient   = const LinearGradient(colors: [_kG1, _kG2], begin: Alignment.topLeft, end: Alignment.bottomRight);
// ─────────────────────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass  = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      Future.microtask(() => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage())));
    }
  }

  Future<void> _login() async {
    try {
      setState(() => _loading = true);
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.text.trim(), password: pass.text.trim());
      setState(() => _loading = false);
      if (!mounted) return;
      if (cred.user?.email?.endsWith('@ug.cusat.ac.in') == true) {
        Navigator.pushReplacementNamed(context,
            cred.user!.emailVerified ? '/admin_dashboard' : '/admin_verification');
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) _snack('Login failed. Check your credentials.');
    }
  }

  Future<void> _googleLogin() async {
    final gUser = await _google.signIn();
    if (gUser == null) return;
    final gAuth = await gUser.authentication;
    final cred  = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: gAuth.idToken));
    if (!mounted) return;
    if (cred.user?.email?.endsWith('@ug.cusat.ac.in') == true) {
      Navigator.pushReplacementNamed(context,
          cred.user!.emailVerified ? '/admin_dashboard' : '/admin_verification');
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: _kG1, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        // Full-screen gradient background matching the eco header
        decoration: BoxDecoration(gradient: _kGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 32),

              // ── Logo block ─────────────────────────────────────────────
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 14),
              const Text('Eco-Tag',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 1)),
              const SizedBox(height: 6),
              const Text('Protect nature together',
                style: TextStyle(color: Colors.white70, fontSize: 14)),

              const SizedBox(height: 36),

              // ── Card ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: _kOffWhite,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Email
                  _EcoField(label: 'Email', icon: Icons.email_outlined,
                    controller: email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),

                  // Password
                  _EcoField(label: 'Password', icon: Icons.lock_outline_rounded,
                    controller: pass, obscure: _hide,
                    suffix: IconButton(
                      icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: _kTextMuted),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  _GradBtn(
                    label: 'Login', loading: _loading, onPressed: _login),
                  const SizedBox(height: 12),

                  // Google button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _googleLogin,
                      icon: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/281/281764.png', height: 20),
                      label: const Text('Sign in with Google',
                        style: TextStyle(color: _kTextDark, fontWeight: FontWeight.w600, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: _kLightGreen, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                      child: const Text('Forgot password?',
                        style: TextStyle(color: _kG1, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SignupPage())),
                      child: const Text('Create account',
                        style: TextStyle(color: _kG1, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Shared eco input field ────────────────────────────────────────────────────
class _EcoField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  const _EcoField({required this.label, required this.icon, required this.controller,
    this.obscure = false, this.suffix, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, obscureText: obscure, keyboardType: keyboardType,
      style: const TextStyle(color: _kTextDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: label, hintStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: _kG1, size: 20),
        suffixIcon: suffix,
        filled: true, fillColor: _kMint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kG1, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── Gradient button ──────────────────────────────────────────────────────────
class _GradBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _GradBtn({required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: loading ? null : const LinearGradient(colors: [_kG1, _kG2]),
          color: loading ? _kLightGreen : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading ? [] : [BoxShadow(color: _kG1.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Center(child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
      ),
    );
  }
}

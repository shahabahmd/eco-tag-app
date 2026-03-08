import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final name    = TextEditingController();
  final email   = TextEditingController();
  final pass    = TextEditingController();
  final confirm = TextEditingController();
  bool _hidePass    = true;
  bool _hideConfirm = true;
  bool _loading     = false;
  final _auth = FirebaseAuth.instance;

  Future<void> _signup() async {
    if (pass.text != confirm.text) {
      _snack('Passwords do not match'); return;
    }
    try {
      setState(() => _loading = true);
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(), password: pass.text.trim());
      await cred.user!.updateDisplayName(name.text.trim());
      setState(() => _loading = false);
      if (!mounted) return;
      _snack('Account created successfully 🌿');
      if (cred.user?.email?.endsWith('@ug.cusat.ac.in') == true) {
        await cred.user!.sendEmailVerification();
        Navigator.pushNamedAndRemoveUntil(context, '/admin_verification', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      final msgs = {
        'email-already-in-use': 'Email already in use',
        'weak-password': 'Password must be at least 6 chars',
        'invalid-email': 'Invalid email address',
      };
      _snack(msgs[e.code] ?? 'Signup failed');
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
        decoration: BoxDecoration(gradient: _kGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 24),

              // ── Logo ───────────────────────────────────────────────────
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              const Text('Create Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Join the eco community',
                style: TextStyle(color: Colors.white70, fontSize: 13)),

              const SizedBox(height: 30),

              // ── Card ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kOffWhite, borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _EcoField(label: 'Full Name', icon: Icons.person_outline_rounded, controller: name),
                  const SizedBox(height: 12),
                  _EcoField(label: 'Email', icon: Icons.email_outlined, controller: email,
                    keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _EcoField(label: 'Password', icon: Icons.lock_outline_rounded,
                    controller: pass, obscure: _hidePass,
                    suffix: IconButton(
                      icon: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: _kTextMuted),
                      onPressed: () => setState(() => _hidePass = !_hidePass))),
                  const SizedBox(height: 12),
                  _EcoField(label: 'Confirm Password', icon: Icons.lock_outline_rounded,
                    controller: confirm, obscure: _hideConfirm,
                    suffix: IconButton(
                      icon: Icon(_hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: _kTextMuted),
                      onPressed: () => setState(() => _hideConfirm = !_hideConfirm))),
                  const SizedBox(height: 24),
                  _GradBtn(label: 'Sign Up', loading: _loading, onPressed: _signup),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Login',
                      style: TextStyle(color: _kG1, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
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

// ─── Eco Input Field ──────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) => TextField(
    controller: controller, obscureText: obscure, keyboardType: keyboardType,
    style: const TextStyle(color: _kTextDark, fontSize: 14),
    decoration: InputDecoration(
      hintText: label, hintStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: _kG1, size: 20),
      suffixIcon: suffix,
      filled: true, fillColor: _kMint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kG1, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class _GradBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _GradBtn({required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => InkWell(
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

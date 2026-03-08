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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _reset() async {
    final userEmail = _emailCtrl.text.trim();
    if (userEmail.isEmpty) { _snack('Please enter your email'); return; }
    try {
      setState(() => _loading = true);
      await _auth.sendPasswordResetEmail(email: userEmail);
      setState(() => _loading = false);
      if (!mounted) return;
      _snack('Reset link sent! Check your inbox 📩');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      final msgs = {
        'user-not-found': 'No account found with this email',
        'invalid-email':  'Invalid email address',
      };
      _snack(msgs[e.code] ?? 'Something went wrong');
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
              const SizedBox(height: 40),

              // ── Icon block ─────────────────────────────────────────────
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              const Text('Reset Password',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('We\'ll send a reset link to your email',
                style: TextStyle(color: Colors.white70, fontSize: 13)),

              const SizedBox(height: 36),

              // ── Card ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: _kOffWhite, borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kMint, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kLightGreen)),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded, color: _kG1, size: 18),
                      SizedBox(width: 10),
                      Expanded(child: Text(
                        'Enter your registered email. We\'ll email you a link to reset your password.',
                        style: TextStyle(color: _kTextDark, fontSize: 12, height: 1.5))),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: _kTextDark, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.email_outlined, color: _kG1, size: 20),
                      filled: true, fillColor: _kMint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _kG1, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Send button
                  InkWell(
                    onTap: _loading ? null : _reset,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity, height: 52,
                      decoration: BoxDecoration(
                        gradient: _loading ? null : const LinearGradient(colors: [_kG1, _kG2]),
                        color: _loading ? _kLightGreen : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _loading ? [] : [BoxShadow(color: _kG1.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
                      ),
                      child: Center(child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Send Reset Link',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                    ),
                  ),
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

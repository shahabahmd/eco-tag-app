import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/municipality_service.dart';
import 'municipality_selection_page.dart';

class AdminVerificationPage extends StatefulWidget {
  const AdminVerificationPage({super.key});

  @override
  State<AdminVerificationPage> createState() => _AdminVerificationPageState();
}

class _AdminVerificationPageState extends State<AdminVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);

    // Reload user to get latest verification status
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;

    setState(() => _isLoading = false);

    if (user != null && user.emailVerified) {
      if (!mounted) return;

      // Check if municipality is already locked
      final status = await MunicipalityService.getMunicipalityStatus(user.uid);
      final locked = status['municipalityLocked'] == true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Email Verified! Welcome Admin."),
          backgroundColor: Colors.green,
        ),
      );

      if (locked) {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MunicipalitySelectionPage()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email not verified yet. Please check your inbox."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email resent. Check your inbox.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Verification"),
        backgroundColor: const Color(0xFF11998e),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: Color(0xFF11998e),
              ),
              const SizedBox(height: 24),
              const Text(
                "Verify Your Email",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "A verification email has been sent. Please click 'Verify Now' in your email to activate admin access.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF11998e))
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11998e),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _checkVerificationStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh Verification Status",
                        style: TextStyle(fontSize: 16)),
                  ),
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF11998e),
                    side: const BorderSide(color: Color(0xFF11998e)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _resendVerificationEmail,
                  icon: const Icon(Icons.send),
                  label: const Text("Resend Verification Email",
                      style: TextStyle(fontSize: 16)),
                ),
              ),

              const Spacer(),

              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout",
                    style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/municipality_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kG1         = Color(0xFF4DBB87);
const _kG2         = Color(0xFF7ED6A7);
const _kMint       = Color(0xFFEAF7F0);
const _kOffWhite   = Color(0xFFF8FBF9);
const _kLightGreen = Color(0xFFBFEAD3);
const _kTextDark   = Color(0xFF1D3A2C);
const _kTextMuted  = Color(0xFF7CA48F);
// ─────────────────────────────────────────────────────────────────────────────

enum _Reason { municipalityChange, others }

class ContactAdminPage extends StatefulWidget {
  const ContactAdminPage({super.key});

  @override
  State<ContactAdminPage> createState() => _ContactAdminPageState();
}

class _ContactAdminPageState extends State<ContactAdminPage> {
  _Reason _reason = _Reason.municipalityChange;
  final _descController = TextEditingController();
  bool _loading = false;
  String? _municipality;

  @override
  void initState() {
    super.initState();
    _loadMunicipality();
  }

  Future<void> _loadMunicipality() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final status = await MunicipalityService.getMunicipalityStatus(uid);
    if (mounted) setState(() => _municipality = status['municipality'] as String?);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Validate description for "Others"
    if (_reason == _Reason.others && _descController.text.trim().isEmpty) {
      _snack('Please describe your issue.');
      return;
    }

    setState(() => _loading = true);

    final reasonLabel = _reason == _Reason.municipalityChange
        ? 'Municipality Change'
        : 'Others';
    final description = _reason == _Reason.others
        ? _descController.text.trim()
        : '';

    try {
      // ── Save support request to Firestore ────────────────────────────────
      await FirebaseFirestore.instance.collection('support_requests').add({
        'adminEmail':    user.email ?? '',
        'adminUid':      user.uid,
        'municipality':  _municipality ?? 'Unknown',
        'reason':        reasonLabel,
        'description':   description,
        'status':        'pending',
        'createdAt':     FieldValue.serverTimestamp(),
      });
      // ─────────────────────────────────────────────────────────────────────

      setState(() => _loading = false);
      _descController.clear();
      if (mounted) await _showSuccessDialog();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _snack('Failed to submit. Please try again.');
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _kOffWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_kG1, _kG2]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              const Text('Request Sent!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: _kTextDark)),
              const SizedBox(height: 10),
              const Text(
                'Your request has been sent to the Super Admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextMuted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);   // close dialog
                    Navigator.pop(context);   // back to dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kG1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Dashboard',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      backgroundColor: _kMint,
      appBar: AppBar(
        title: const Text('Contact Super Admin'),
        backgroundColor: _kG1,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header card ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kG1, _kG2],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Super Admin Support',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text('Municipality: ${_municipality ?? '...'}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  ],
                )),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Form card ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _kOffWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16, offset: const Offset(0, 5),
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Reason label ──────────────────────────────────────
                  const Text('Reason for Contact',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: _kTextMuted)),
                  const SizedBox(height: 8),

                  // ── Reason dropdown ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kLightGreen),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_Reason>(
                        value: _reason,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _kG1),
                        dropdownColor: _kOffWhite,
                        borderRadius: BorderRadius.circular(16),
                        style: const TextStyle(
                            color: _kTextDark, fontSize: 14,
                            fontWeight: FontWeight.w500),
                        items: const [
                          DropdownMenuItem(
                            value: _Reason.municipalityChange,
                            child: Text('Municipality Change'),
                          ),
                          DropdownMenuItem(
                            value: _Reason.others,
                            child: Text('Others'),
                          ),
                        ],
                        onChanged: _loading
                            ? null
                            : (v) {
                                if (v != null) setState(() => _reason = v);
                              },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Contextual content based on reason ────────────────
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 280),
                    crossFadeState: _reason == _Reason.municipalityChange
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kMint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kLightGreen),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline_rounded,
                              color: _kG1, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your request to change the municipality will '
                              'be reviewed by the Super Admin. '
                              'Changes are subject to approval.',
                              style: TextStyle(
                                  fontSize: 13, color: _kTextDark,
                                  fontWeight: FontWeight.w500, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Describe Your Issue',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kTextMuted)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descController,
                          maxLines: 4,
                          enabled: !_loading,
                          style: const TextStyle(
                              color: _kTextDark, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Explain the issue in detail...',
                            hintStyle: const TextStyle(
                                color: _kTextMuted, fontSize: 13),
                            filled: true,
                            fillColor: _kMint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: _kG1, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Submit button ─────────────────────────────────────
                  InkWell(
                    onTap: _loading ? null : _submit,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: _loading
                            ? null
                            : const LinearGradient(colors: [_kG1, _kG2]),
                        color: _loading ? _kLightGreen : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _loading
                            ? []
                            : [BoxShadow(
                                color: _kG1.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              )],
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.send_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Submit Request',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Discreet info strip — no email shown ───────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kOffWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kLightGreen),
              ),
              child: const Row(children: [
                Icon(Icons.verified_user_rounded, color: _kG1, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your request will be securely forwarded to the Super Admin.',
                    style: TextStyle(
                        color: _kTextMuted, fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

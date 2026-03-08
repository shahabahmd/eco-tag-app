import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/municipality_service.dart';

// ─── Design Tokens (matches eco auth theme) ───────────────────────────────────
const _kG1         = Color(0xFF4DBB87);
const _kG2         = Color(0xFF7ED6A7);
const _kMint       = Color(0xFFEAF7F0);
const _kOffWhite   = Color(0xFFF8FBF9);
const _kLightGreen = Color(0xFFBFEAD3);
const _kTextDark   = Color(0xFF1D3A2C);
const _kTextMuted  = Color(0xFF7CA48F);
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kMunicipalities = [
  'Adoor', 'Alappuzha', 'Aluva', 'Angamaly', 'Attingal',
  'Chalakkudy', 'Changanassery', 'Chavakkad', 'Chengannur', 'Cherthala',
  'Chittur-Thathamangalam', 'Eloor', 'Ettumanoor', 'Feroke', 'Guruvayur',
  'Haripad', 'Irinjalakuda', 'Iritty', 'Kalamassery', 'Kalpetta',
  'Kanhangad', 'Karunagappally', 'Kasaragod', 'Kattappana', 'Kayamkulam',
  'Kodungallur', 'Koduvally', 'Kondotty', 'Kothamangalam', 'Kottakkal',
  'Kottarakkara', 'Kottayam', 'Koyilandy', 'Kunnamkulam', 'Kunnathunad',
  'Kuthuparamba', 'Mananthavady', 'Manjeri', 'Mannarkkad', 'Maradu',
  'Mattannur', 'Mavelikkara', 'Mukkam', 'Muvattupuzha', 'Nedumangad',
  'Neyyattinkara', 'Nilambur', 'Nileshwaram', 'North Paravur', 'Ottapalam',
  'Pala', 'Palakkad', 'Parappanangadi', 'Paravur', 'Pathanamthitta',
  'Pattambi', 'Payyannur', 'Payyoli', 'Perinthalmanna', 'Perumbavoor',
  'Ponnani', 'Punalur', 'Ramanattukara', 'Shoranur', 'Sulthan Bathery',
  'Taliparamba', 'Tanur', 'Thalassery', 'Thiruvalla', 'Thodupuzha',
  'Thrikkakara', 'Thrippunithura', 'Tirur', 'Tirurangadi', 'Vadakara',
  'Vaikom', 'Valanchery', 'Varkala', 'Wadakkanchery',
];

class MunicipalitySelectionPage extends StatefulWidget {
  const MunicipalitySelectionPage({super.key});

  @override
  State<MunicipalitySelectionPage> createState() => _MunicipalitySelectionPageState();
}

class _MunicipalitySelectionPageState extends State<MunicipalitySelectionPage> {
  String _selected = _kMunicipalities.first;
  bool _loading = false;

  Future<void> _confirm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await MunicipalityService.saveMunicipality(
        user.uid,
        user.email ?? '',
        _selected,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/admin_dashboard', (_) => false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving municipality: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Block back navigation — selection is mandatory
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kG1, _kG2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Icon ──────────────────────────────────────────────────
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: const Icon(Icons.location_city_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ─────────────────────────────────────────────────
                  const Text(
                    'Select Your Municipality',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is a one-time selection and cannot\nbe changed from the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),

                  const SizedBox(height: 36),

                  // ── Card ──────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _kOffWhite,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 30, offset: const Offset(0, 10),
                      )],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Info Banner ────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kMint,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kLightGreen),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: _kG1.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_rounded,
                                    color: _kG1, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Your municipality is permanent once confirmed. Choose carefully.',
                                  style: TextStyle(
                                      fontSize: 12, color: _kTextDark,
                                      fontWeight: FontWeight.w500, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text('Kerala Municipality',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600, color: _kTextMuted)),
                        const SizedBox(height: 8),

                        // ── Dropdown ───────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kMint,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kLightGreen),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selected,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: _kG1),
                              style: const TextStyle(
                                  color: _kTextDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              dropdownColor: _kOffWhite,
                              borderRadius: BorderRadius.circular(16),
                              items: _kMunicipalities
                                  .map((v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v),
                                      ))
                                  .toList(),
                              onChanged: _loading
                                  ? null
                                  : (v) {
                                      if (v != null) setState(() => _selected = v);
                                    },
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Confirm Button ─────────────────────────────────
                        InkWell(
                          onTap: _loading ? null : _confirm,
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
                                      blurRadius: 12, offset: const Offset(0, 5),
                                    )],
                            ),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.check_circle_rounded,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text('Confirm Municipality',
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

                  const SizedBox(height: 24),

                  // ── Bottom hint ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.white70, size: 14),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'To change your municipality later, contact the Super Admin.',
                            style: TextStyle(color: Colors.white70, fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

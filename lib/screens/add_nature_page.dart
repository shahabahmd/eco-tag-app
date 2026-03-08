import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../services/cloudinary_service.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const kG1         = Color(0xFF4DBB87);
const kG2         = Color(0xFF7ED6A7);
const kMint       = Color(0xFFEAF7F0);
const kOffWhite   = Color(0xFFF8FBF9);
const kLightGreen = Color(0xFFBFEAD3);
const kTextDark   = Color(0xFF1D3A2C);
const kTextMuted  = Color(0xFF7CA48F);

final kGradient = const LinearGradient(colors: [kG1, kG2], begin: Alignment.topLeft, end: Alignment.bottomRight);
final kCardShadow = [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 5))];

// ─── Municipality helpers ─────────────────────────────────────────────────────
const List<String> _validMunicipalities = [
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

Future<String> _getMunicipality(double lat, double lng) async {
  String out = 'Unknown';
  try {
    final pms = await placemarkFromCoordinates(lat, lng);
    if (pms.isNotEmpty) {
      final p = pms.first;
      final names = [p.subLocality, p.locality, p.subAdministrativeArea, p.administrativeArea];
      outer: for (final n in names) {
        if (n != null && n.trim().isNotEmpty) {
          final l = n.trim().toLowerCase();
          for (final v in _validMunicipalities) {
            if (l.contains(v.toLowerCase())) { out = v; break outer; }
          }
        }
      }
      if (out == 'Unknown') {
        for (final n in names) { if (n != null && n.trim().isNotEmpty) { out = n.trim(); break; } }
      }
    }
  } catch (e) { debugPrint('Geocoding: $e'); }
  return out;
}
// ─────────────────────────────────────────────────────────────────────────────

class AddNaturePage extends StatefulWidget {
  const AddNaturePage({super.key});
  @override
  State<AddNaturePage> createState() => _AddNaturePageState();
}

class _AddNaturePageState extends State<AddNaturePage> {
  File? _image;
  final _desc = TextEditingController();
  String _natureType = 'Park';
  bool _isLoading = false;
  final _picker = ImagePicker();

  @override
  void dispose() { _desc.dispose(); super.dispose(); }

  Future<void> _openCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _submit() async {
    if (_image == null) { _snack('📸 Please capture a beautiful photo!', isWarn: true); return; }
    if (_desc.text.trim().isEmpty) { _snack('📝 Tell us why this spot is special.', isWarn: true); return; }
    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final url = await CloudinaryService.uploadImage(_image!);
      if (url == null) throw Exception('Image upload failed');
      final mun = await _getMunicipality(pos.latitude, pos.longitude);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': uid, 'type': 'nature', 'natureType': _natureType,
        'description': _desc.text.trim(), 'imageUrl': url,
        'lat': pos.latitude, 'lng': pos.longitude,
        'municipality': mun, 'timestamp': FieldValue.serverTimestamp(), 'likes': 0,
      });
      if (mounted) { _snack('🌿 Nature spot added!'); Navigator.pop(context); }
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false, bool isWarn = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: isError ? Colors.redAccent : isWarn ? Colors.orange : kG1,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMint,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Gradient SliverAppBar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: kGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 30),
                        Text('Add Nature Spot',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                        SizedBox(height: 6),
                        Text('Share a beautiful location.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),

          // ─── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _PhotoCard(image: _image, onTap: _openCamera),
              const SizedBox(height: 24),

              const _SectionLabel(label: 'Spot Details'),
              const SizedBox(height: 14),

              _DropdownField(
                value: _natureType,
                items: ['Park', 'Forest', 'Waterfall', 'Garden', 'Lake', 'Viewpoint', 'Other'],
                icon: _iconForNature,
                onChanged: (v) => setState(() => _natureType = v!),
              ),
              const SizedBox(height: 14),

              _DescField(controller: _desc, hint: 'What makes this place special?'),
              const SizedBox(height: 32),

              _GradientButton(loading: _isLoading, label: 'Add Nature Spot', icon: Icons.add_location_alt_rounded, onPressed: _submit),
            ])),
          ),
        ],
      ),
    );
  }

  IconData _iconForNature(String t) {
    switch (t) {
      case 'Park': return Icons.park;
      case 'Forest': return Icons.forest;
      case 'Waterfall': return Icons.water_drop;
      case 'Garden': return Icons.local_florist;
      case 'Lake': return Icons.pool;
      case 'Viewpoint': return Icons.visibility;
      default: return Icons.nature;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  const _PhotoCard({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 220, width: double.infinity,
        decoration: BoxDecoration(
          color: image == null ? kLightGreen.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: image == null ? kG1.withValues(alpha: 0.4) : kG1, width: 2),
          boxShadow: kCardShadow,
        ),
        child: image == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(gradient: kGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.landscape_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                const Text('Tap to capture view', style: TextStyle(color: kTextMuted, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Camera only', style: TextStyle(color: kTextMuted, fontSize: 11)),
              ])
            : ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(fit: StackFit.expand, children: [
                  Image.file(image!, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.3)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    )),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white54),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Retake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    ),
                  ),
                ]),
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark, letterSpacing: 0.2));
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData Function(String) icon;
  final void Function(String?) onChanged;
  const _DropdownField({required this.value, required this.items, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: kOffWhite, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLightGreen), boxShadow: kCardShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kG1),
          style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w500, fontSize: 14),
          items: items.map((v) => DropdownMenuItem(
            value: v,
            child: Row(children: [
              Icon(icon(v), color: kTextMuted, size: 18), const SizedBox(width: 10), Text(v),
            ]),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DescField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _DescField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, maxLines: 4,
      style: const TextStyle(color: kTextDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
        filled: true, fillColor: kOffWhite, contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLightGreen)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLightGreen)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kG1, width: 2)),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final bool loading;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _GradientButton({required this.loading, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: loading ? const LinearGradient(colors: [Color(0xFFB0D8C4), Color(0xFFC8E8D6)]) : kGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: loading ? [] : [BoxShadow(color: kG1.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10),
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3)),
                ]),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _kG1         = Color(0xFF4DBB87);
const _kG2         = Color(0xFF7ED6A7);
const _kMint       = Color(0xFFEAF7F0);
const _kOffWhite   = Color(0xFFF8FBF9);
const _kLightGreen = Color(0xFFBFEAD3);
const _kTextDark   = Color(0xFF1D3A2C);
const _kTextMuted  = Color(0xFF7CA48F);
final _kGradient   = const LinearGradient(colors: [_kG1, _kG2], begin: Alignment.topLeft, end: Alignment.bottomRight);
final _kShadow     = [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 5))];
// ─────────────────────────────────────────────────────────────────────────────

class NearbySpotsPage extends StatefulWidget {
  final LatLng currentPos;
  const NearbySpotsPage({super.key, required this.currentPos});
  @override
  State<NearbySpotsPage> createState() => _NearbySpotsPageState();
}

class _NearbySpotsPageState extends State<NearbySpotsPage> {
  String _locationName = 'Locating…';
  List<Map<String, dynamic>> _spots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpots();
  }

  Future<void> _fetchSpots() async {
    try {
      final pms = await placemarkFromCoordinates(
          widget.currentPos.latitude, widget.currentPos.longitude);
      if (pms.isNotEmpty && mounted) {
        setState(() => _locationName = pms.first.locality ?? 'Your Location');
      }

      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .where('type', isEqualTo: 'nature')
          .get();

      final List<Map<String, dynamic>> fetched = [];
      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['lat'] != null && d['lng'] != null && d['imageUrl'] != null) {
          final dist = Geolocator.distanceBetween(
            widget.currentPos.latitude, widget.currentPos.longitude,
            d['lat'], d['lng'],
          );
          if (dist <= 5000) fetched.add({...d, 'distanceInMeters': dist});
        }
      }
      fetched.sort((a, b) =>
          (a['distanceInMeters'] as double).compareTo(b['distanceInMeters'] as double));

      if (mounted) setState(() { _spots = fetched; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
            backgroundColor: _kG1, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    }
  }

  void _showDetails(Map<String, dynamic> data) {
    // Use spotName if available, otherwise first sentence of description
    final name = (data['spotName'] as String?)?.isNotEmpty == true
        ? data['spotName'] as String
        : (data['description']?.toString().split('.').first ?? 'Nature Spot');
    final description = data['description'] ?? 'No description available.';
    final municipality = data['municipality'] as String? ?? '';
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Container(
          decoration: BoxDecoration(
              color: _kOffWhite, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image with overlaid badge + close ────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    child: Image.network(
                      data['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: _kLightGreen,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_rounded,
                              color: _kG1, size: 40),
                        ),
                      ),
                    ),
                  ),
                  // Eco badge
                  Positioned(
                    top: 12, left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          gradient: _kGradient,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded,
                              color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text('NATURE SPOT',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 12, right: 14,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 17, color: _kTextDark),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Text content ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spot name
                    Text(name,
                      style: const TextStyle(fontSize: 19,
                          fontWeight: FontWeight.bold, color: _kTextDark,
                          letterSpacing: -0.3)),
                    const SizedBox(height: 6),

                    // Municipality chip (only if available)
                    if (municipality.isNotEmpty) ...[
                      Row(children: [
                        const Icon(Icons.location_city_rounded,
                            color: _kG1, size: 14),
                        const SizedBox(width: 5),
                        Text(municipality,
                          style: const TextStyle(
                              color: _kTextMuted, fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 10),
                    ],

                    // Description
                    const Text('DESCRIPTION',
                      style: TextStyle(color: _kTextMuted, fontSize: 10,
                          fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Text(description,
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _kTextDark,
                          fontSize: 14, height: 1.45, fontWeight: FontWeight.w500)),

                    const SizedBox(height: 18),

                    // Get Directions button
                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: lat != null && lng != null
                            ? () async {
                                final uri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                );
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                                }
                              }
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: _kGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _kG1.withValues(alpha: 0.30),
                                blurRadius: 10, offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Get Directions',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kMint,
      body: Column(
        children: [
          // ── Gradient Header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 28),
            decoration: BoxDecoration(
              gradient: _kGradient,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Nearby Nature Spots',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                    const SizedBox(height: 3),
                    Text('around $_locationName',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kG1))
                : _spots.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        itemCount: _spots.length,
                        itemBuilder: (_, i) => _SpotCard(
                          data: _spots[i],
                          onTap: () => _showDetails(_spots[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_kG1.withValues(alpha: 0.15), _kG2.withValues(alpha: 0.15)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.nature_people_rounded, size: 40, color: _kG1),
        ),
        const SizedBox(height: 20),
        const Text('No nature spots within 5 km.',
          style: TextStyle(color: _kTextDark, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Be the first to add one!',
          style: TextStyle(color: _kTextMuted, fontSize: 13)),
      ]),
    );
  }
}

// ─── Spot Card ────────────────────────────────────────────────────────────────
class _SpotCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _SpotCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final distKm = ((data['distanceInMeters'] as double) / 1000).toStringAsFixed(1);
    final title = data['description']?.toString().split('.').first ?? 'Beautiful Spot';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: _kOffWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _kShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(children: [
              Image.network(data['imageUrl'], height: 220, width: double.infinity, fit: BoxFit.cover),
              // Gradient overlay
              Positioned.fill(child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.25)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                )),
              )),
              // Distance badge
              Positioned(top: 14, right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _kShadow,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: _kG1),
                    const SizedBox(width: 4),
                    Text('$distKm km',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _kTextDark)),
                  ]),
                ),
              ),
              // Eco badge
              Positioned(top: 14, left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: _kGradient, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.eco_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('NATURE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ]),
                ),
              ),
            ]),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: _kTextDark, letterSpacing: -0.3)),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kLightGreen.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(data['natureType']?.toString() ?? 'Nature',
                    style: const TextStyle(color: _kG1, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const Spacer(),
                const Icon(Icons.touch_app_rounded, size: 14, color: _kTextMuted),
                const SizedBox(width: 4),
                const Text('Tap for details', style: TextStyle(color: _kTextMuted, fontSize: 11)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/municipality_service.dart';
import '../services/municipality_coords.dart';
import 'full_screen_map_page.dart';
import 'contact_admin_page.dart';

// ─── Design Tokens (matches user analytics style) ────────────────────────────
const kG1         = Color(0xFF4DBB87);
const kG2         = Color(0xFF7ED6A7);
const kMint       = Color(0xFFEAF7F0);
const kOffWhite   = Color(0xFFF8FBF9);
const kLightGreen = Color(0xFFBFEAD3);
const kTextDark   = Color(0xFF1D3A2C);
const kTextMuted  = Color(0xFF7CA48F);
final kGradient   = const LinearGradient(colors: [kG1, kG2], begin: Alignment.topLeft, end: Alignment.bottomRight);
final kCardShadow = [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 5))];
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _filterType = 'All';
  String? _selectedMunicipality;
  bool _isHeatmapMode = false;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _heatmapCircles = {};
  LatLng? _mapCenter;

  static const List<String> _municipalities = [
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

  @override
  void initState() {
    super.initState();
    _loadMunicipality();
  }

  /// Reads the locked municipality from Firestore and sets the default map center.
  Future<void> _loadMunicipality() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final status = await MunicipalityService.getMunicipalityStatus(uid);
    if (mounted) {
      final mun = status['municipality'] as String?;
      setState(() {
        _selectedMunicipality = mun;
        // Pre-center the map on the municipality immediately
        _mapCenter = MunicipalityCoords.coordsFor(mun);
      });
    }
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('reports').doc(docId).update({'status': newStatus});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status → ${newStatus.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kG1, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showReportDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kOffWhite, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(data['type'] == 'nature' ? 'Nature Spot' : 'Issue Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: kLightGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: kTextDark))),
            ]),
            const SizedBox(height: 12),
            if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(data['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 14),
            const Text('Description', style: TextStyle(color: kTextMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(data['description'] ?? 'No description', style: const TextStyle(fontSize: 15, color: kTextDark)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: kG1, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Lat: ${data['lat']?.toStringAsFixed(4)}, Lng: ${data['lng']?.toStringAsFixed(4)}',
                  style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w500, fontSize: 13))),
              ]),
            ),
            if (data['type'] == 'issue') ...[
              const SizedBox(height: 12),
              Row(children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                const SizedBox(width: 6),
                _StatusBadge(status: data['status'] ?? 'pending'),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Color _getStatusColor(String s) {
    if (s == 'resolved') return const Color(0xFF45C4A4);
    if (s == 'in progress') return const Color(0xFFE8B66A);
    return const Color(0xFFE07979);
  }

  void _processMapData(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) return;
    // Only move to first-report center if coord-based center wasn't already set
    if (_mapCenter == null) {
      _mapCenter = LatLng(reports.first['lat'], reports.first['lng']);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_mapCenter!, 12));
      });
    }
    _markers.clear();
    _heatmapCircles.clear();

    // Build markers — skip resolved issues (their red pin is removed once resolved).
    // Nature spots and non-resolved issues always get a marker.
    // Heatmap circles are built from ALL reports for accurate density.
    for (final d in reports) {
      final isResolvedIssue = d['type'] == 'issue' && d['status'] == 'resolved';
      if (isResolvedIssue) continue; // resolved issues: no map pin
      _markers.add(Marker(
        markerId: MarkerId(d['id']),
        position: LatLng(d['lat'], d['lng']),
        icon: d['type'] == 'nature'
            ? BitmapDescriptor.defaultMarkerWithHue(100)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () => _showReportDetails(d),
      ));
    }

    const radius = 1000.0;
    final List<Map<String, dynamic>> clusters = [];
    for (final rep in reports) {
      bool added = false;
      for (final cl in clusters) {
        if (Geolocator.distanceBetween(rep['lat'], rep['lng'], cl['lat'], cl['lng']) < radius) {
          cl['count'] = (cl['count'] ?? 1) + 1; added = true; break;
        }
      }
      if (!added) clusters.add({'lat': rep['lat'], 'lng': rep['lng'], 'count': 1});
    }
    for (var i = 0; i < clusters.length; i++) {
      final c = clusters[i];
      final col = c['count'] >= 5
          ? Colors.red.withValues(alpha: 0.5)
          : c['count'] >= 2
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.green.withValues(alpha: 0.5);
      _heatmapCircles.add(Circle(
        circleId: CircleId('h$i'),
        center: LatLng(c['lat'], c['lng']),
        radius: 800, fillColor: col, strokeWidth: 0,
      ));
    }
  }

  /// Shows the Help / Support bottom sheet.
  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: kOffWhite,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: kLightGreen, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: kGradient, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            const Text('Help & Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: kTextDark)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kMint, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kLightGreen),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: kG1, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Municipality selection is permanent. To request a change, '
                      'please contact the Super Admin.',
                      style: TextStyle(fontSize: 13, color: kTextDark,
                          fontWeight: FontWeight.w500, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactAdminPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.email_rounded, size: 18),
                label: const Text('Contact Super Admin',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kG1, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedMunicipality == null) {
      return const Scaffold(
        backgroundColor: kMint,
        body: Center(child: CircularProgressIndicator(color: kG1)),
      );
    }

    return Scaffold(
      backgroundColor: kMint,
      // ── Logout pinned at bottom — always visible ───────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          color: kOffWhite,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Help / Support button
              Expanded(
                child: TextButton.icon(
                  onPressed: _showHelpSheet,
                  icon: const Icon(Icons.help_outline_rounded,
                      color: kTextMuted),
                  label: const Text('Help',
                    style: TextStyle(color: kTextMuted,
                        fontWeight: FontWeight.bold, fontSize: 14)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: kMint,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Logout button
              Expanded(
                flex: 2,
                child: TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.redAccent),
                  label: const Text('Logout Admin',
                    style: TextStyle(color: Colors.redAccent,
                        fontWeight: FontWeight.bold, fontSize: 14)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kG1));
          }

          List<Map<String, dynamic>> all = [];
          if (snapshot.hasData) {
            all = snapshot.data!.docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['municipality'] == _selectedMunicipality;
            }).map((e) => {'id': e.id, ...e.data() as Map<String, dynamic>}).toList();
          }

          if (all.isNotEmpty) _processMapData(all);

          final total    = all.length;
          final pending  = all.where((d) => d['type'] == 'issue' && (d['status'] == 'pending' || d['status'] == null)).length;
          final resolved = all.where((d) => d['status'] == 'resolved').length;
          final nature   = all.where((d) => d['type'] == 'nature').length;

          var filtered = all;
          if (_filterType == 'Issues')       filtered = filtered.where((d) => d['type'] == 'issue').toList();
          if (_filterType == 'Nature Spots') filtered = filtered.where((d) => d['type'] == 'nature').toList();

          // ── Everything in ONE scrollable — header, cards, map, list ────────
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Gradient header
              SliverToBoxAdapter(
                child: _AdminHeader(
                  municipality: _selectedMunicipality!,
                  onHelp: _showHelpSheet,
                ),
              ),

              // Stat cards — normal flow, no overlap
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _StatCards(total: total, pending: pending, resolved: resolved, nature: nature),
                ),
              ),

              // Map — tap to open full-screen
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenMapPage(
                            municipality: _selectedMunicipality!,
                            mapCenter: _mapCenter ?? MunicipalityCoords.coordsFor(_selectedMunicipality),
                            markers: _markers,
                            heatmapCircles: _heatmapCircles,
                            isHeatmapMode: _isHeatmapMode,
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        _MapCard(
                          mapCenter: _mapCenter ?? MunicipalityCoords.coordsFor(_selectedMunicipality),
                          isHeatmap: _isHeatmapMode,
                          markers: _markers,
                          circles: _heatmapCircles,
                          onToggleHeatmap: () => setState(() => _isHeatmapMode = !_isHeatmapMode),
                          onMapCreated: (c) => _mapController = c,
                        ),
                        // Tap hint overlay
                        Positioned(
                          top: 10, left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_full_rounded,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Tap for full map',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reports & Spots',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kTextDark)),
                      _FilterChip(
                        value: _filterType,
                        onChanged: (v) { if (v != null) setState(() => _filterType = v); },
                      ),
                    ],
                  ),
                ),
              ),

              // Empty state
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_outlined, size: 56, color: kTextMuted),
                      const SizedBox(height: 10),
                      Text('No items found for $_selectedMunicipality.',
                        style: const TextStyle(color: kTextMuted, fontSize: 15)),
                    ]),
                  ),
                ),

              // Report cards — inline, no nested scroll
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ReportCard(
                      data: filtered[i],
                      onTap: () => _showReportDetails(filtered[i]),
                      onStatusChange: (v) => _updateStatus(filtered[i]['id'], v),
                      statusColor: _getStatusColor(filtered[i]['status'] ?? 'pending'),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Admin Gradient Header ────────────────────────────────────────────────────
class _AdminHeader extends StatelessWidget {
  final String municipality;
  final VoidCallback onHelp;
  const _AdminHeader({required this.municipality, required this.onHelp});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 24),
      decoration: BoxDecoration(
        gradient: kGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                const SizedBox(height: 8),
                // ── Read-only municipality display (locked) ──────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 6),
                    Text(municipality,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ],
            ),
          ),
          // ── Help icon ─────────────────────────────────────────────────
          GestureDetector(
            onTap: onHelp,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Cards ───────────────────────────────────────────────────────────────
class _StatCards extends StatelessWidget {
  final int total, pending, resolved, nature;
  const _StatCards({required this.total, required this.pending,
      required this.resolved, required this.nature});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _StatCard('Total', total, Icons.folder_special_rounded, [kG1, kG2])),
        const SizedBox(width: 12),
        Expanded(child: _StatCard('Pending', pending, Icons.hourglass_bottom_rounded,
            [const Color(0xFFE8B66A), const Color(0xFFF5C882)])),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatCard('Resolved', resolved, Icons.task_alt_rounded,
            [const Color(0xFF45C4A4), const Color(0xFF72D8BF)])),
        const SizedBox(width: 12),
        Expanded(child: _StatCard('Nature Spots', nature, Icons.eco_rounded,
            [const Color(0xFF6DB875), const Color(0xFF90D498)])),
      ]),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final List<Color> colors;
  const _StatCard(this.label, this.count, this.icon, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1)),
          Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}

// ─── Map Card ─────────────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  final LatLng mapCenter;
  final bool isHeatmap;
  final Set<Marker> markers;
  final Set<Circle> circles;
  final VoidCallback onToggleHeatmap;
  final void Function(GoogleMapController) onMapCreated;
  const _MapCard({required this.mapCenter, required this.isHeatmap,
    required this.markers, required this.circles,
    required this.onToggleHeatmap, required this.onMapCreated});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: kCardShadow,
      ),
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: mapCenter, zoom: 12),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            markers: isHeatmap ? {} : markers,
            circles: isHeatmap ? circles : {},
            onMapCreated: onMapCreated,
          ),
        ),
        // Toggle button
        Positioned(top: 10, right: 10,
          child: GestureDetector(
            onTap: onToggleHeatmap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: kGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: kCardShadow,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isHeatmap ? Icons.map_rounded : Icons.blur_on_rounded,
                    size: 16, color: Colors.white),
                const SizedBox(width: 5),
                Text(isHeatmap ? 'Map Pins' : 'Heatmap',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ]),
            ),
          ),
        ),
        // Legend
        Positioned(bottom: 10, left: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: isHeatmap
                  ? [_L(Colors.red, 'High'), _L(Colors.orange, 'Medium'), _L(Colors.green, 'Low')]
                  : [_L(Colors.red, 'Issue'), _L(Colors.green, 'Nature')]),
          ),
        ),
      ]),
    );
  }

  Widget _L(Color c, String l) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kTextDark)),
    ]),
  );
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String value;
  final void Function(String?) onChanged;
  const _FilterChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kOffWhite, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLightGreen),
        boxShadow: kCardShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.filter_list_rounded, size: 14, color: kG1),
          style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 12),
          items: ['All', 'Issues', 'Nature Spots']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Report Card ──────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final void Function(String) onStatusChange;
  final Color statusColor;
  const _ReportCard({required this.data, required this.onTap,
      required this.onStatusChange, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final type   = data['type'] == 'nature' ? 'Nature' : 'Issue';
    final desc   = data['description']?.toString() ?? 'N/A';
    final status = data['status'] ?? 'pending';
    final dateStr = data['timestamp'] != null
        ? DateFormat('MMM dd, yyyy').format((data['timestamp'] as Timestamp).toDate())
        : 'Unknown';
    final mun = data['municipality']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty
                    ? Image.network(data['imageUrl'], width: 74, height: 74, fit: BoxFit.cover)
                    : Container(width: 74, height: 74, color: kLightGreen,
                        child: const Icon(Icons.image_outlined, color: kG1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: type == 'Issue'
                            ? const Color(0xFFE07979).withValues(alpha: 0.12)
                            : kLightGreen.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(type,
                        style: TextStyle(
                          color: type == 'Issue' ? const Color(0xFFE07979) : kG1,
                          fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    Text(dateStr, style: const TextStyle(color: kTextMuted, fontSize: 10)),
                  ]),
                  const SizedBox(height: 6),
                  Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextDark)),
                  const SizedBox(height: 4),
                  Text(mun, style: const TextStyle(color: kTextMuted, fontSize: 11)),
                  if (type == 'Issue') ...[
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        Container(width: 8, height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                          color: kLightGreen.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: status, isDense: true,
                            icon: const Icon(Icons.edit_rounded, size: 12, color: kTextMuted),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kTextDark),
                            items: ['pending', 'in progress', 'resolved']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                            onChanged: (v) { if (v != null) onStatusChange(v); },
                          ),
                        ),
                      ),
                    ]),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    if (status == 'resolved') return const Color(0xFF45C4A4);
    if (status == 'in progress') return const Color(0xFFE8B66A);
    return const Color(0xFFE07979);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(),
        style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

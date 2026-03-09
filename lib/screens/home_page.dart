import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_issue_page.dart';
import 'add_nature_page.dart';
import 'nearby_spots_page.dart' as nearby_spots;
import 'analytics_page.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _kG1         = Color(0xFF4DBB87);
const _kG2         = Color(0xFF7ED6A7);
const _kOffWhite   = Color(0xFFF8FBF9);
const _kLightGreen = Color(0xFFBFEAD3);
const _kTextDark   = Color(0xFF1D3A2C);
const _kTextMuted  = Color(0xFF7CA48F);
final _kGradient   = const LinearGradient(colors: [_kG1, _kG2], begin: Alignment.topLeft, end: Alignment.bottomRight);
final _kShadow     = [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4))];
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;
  final TextEditingController _searchController = TextEditingController();

  LatLng currentPos = const LatLng(10.8505, 76.2711);
  final Set<Marker> markers = {};
  final Set<Circle> _heatmapCircles = {};
  bool _isLoading = false;
  String _selectedTimeline = 'All Time';
  bool _isHeatmapMode = false;

  @override
  void initState() {
    super.initState();
    getLocation();
    loadReports();
  }

  Future<void> getLocation() async {
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition();
    currentPos = LatLng(position.latitude, position.longitude);
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentPos, 15));
    setState(() {});
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      List<Location> locations = await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        final newPos = LatLng(locations.first.latitude, locations.first.longitude);
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 14));
        setState(() => currentPos = newPos);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location not found: $e'),
            backgroundColor: _kG1, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateHeatmapCircles(List<Map<String, dynamic>> reports) {
    const double radius = 1000;
    List<Map<String, dynamic>> clusters = [];
    for (var r in reports) {
      bool added = false;
      for (var c in clusters) {
        if (Geolocator.distanceBetween(r['lat'], r['lng'], c['lat'], c['lng']) < radius) {
          c['count'] = (c['count'] ?? 1) + 1; added = true; break;
        }
      }
      if (!added) clusters.add({'lat': r['lat'], 'lng': r['lng'], 'count': 1});
    }
    int i = 0;
    for (var c in clusters) {
      final col = c['count'] >= 5
          ? Colors.red.withValues(alpha: 0.5)
          : c['count'] >= 2
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.green.withValues(alpha: 0.5);
      _heatmapCircles.add(Circle(
        circleId: CircleId('heat_${i++}'),
        center: LatLng(c['lat'], c['lng']),
        radius: 800, fillColor: col, strokeWidth: 0,
      ));
    }
  }

  Future<void> loadReports() async {
    Query query = FirebaseFirestore.instance.collection('reports');
    if (_selectedTimeline != 'All Time') {
      final now = DateTime.now();
      DateTime start;
      if (_selectedTimeline == 'Last 24 hours') start = now.subtract(const Duration(hours: 24));
      else if (_selectedTimeline == 'Last 7 days') start = now.subtract(const Duration(days: 7));
      else if (_selectedTimeline == 'Last 30 days') start = now.subtract(const Duration(days: 30));
      else start = now.subtract(const Duration(days: 180));
      query = query.where('timestamp', isGreaterThanOrEqualTo: start);
    }
    final snap = await query.get();
    markers.clear(); _heatmapCircles.clear();
    List<Map<String, dynamic>> data = [];
    for (var doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      data.add({'id': doc.id, ...d});
      // Skip resolved issues — no red pin should remain on the user's map
      // after an admin marks the issue as resolved.
      final isResolvedIssue = d['type'] == 'issue' && d['status'] == 'resolved';
      if (!_isHeatmapMode && !isResolvedIssue) {
        markers.add(Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(d['lat'], d['lng']),
          icon: d['type'] == 'nature'
              ? BitmapDescriptor.defaultMarkerWithHue(100)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _showReportSheet(d),
        ));
      }
    }
    if (_isHeatmapMode) _generateHeatmapCircles(data);
    setState(() {});
  }

  void _showReportSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _kOffWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: _kLightGreen, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 20),
          // Type badge + icon
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(gradient: _kGradient, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(data['type'] == 'nature' ? Icons.eco_rounded : Icons.warning_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(data['type']?.toString().toUpperCase() ?? 'REPORT',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(data['imageUrl'], height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 14),
          const Text('Description',
            style: TextStyle(color: _kTextMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(data['description'] ?? 'No details provided.',
            style: const TextStyle(fontSize: 15, color: _kTextDark, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _kOffWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: _kLightGreen, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 18),
          const Text('Choose Action',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kTextDark)),
          const SizedBox(height: 20),
          _ActionTile(
            icon: Icons.report_rounded, label: 'Report Issue',
            subtitle: 'Report waste or problems',
            color: const Color(0xFFE07979),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssuePage()));
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.eco_rounded, label: 'Add Nature Spot',
            subtitle: 'Mark beautiful locations',
            color: _kG1,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNaturePage()));
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Map fills the screen ───────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(target: currentPos, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _isHeatmapMode ? {} : markers,
            circles: _isHeatmapMode ? _heatmapCircles : {},
            onMapCreated: (c) => mapController = c,
          ),

          // ── Search bar ────────────────────────────────────────────────────
          Positioned(
            top: topPad + 12, left: 16, right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: _kOffWhite, borderRadius: BorderRadius.circular(30),
                boxShadow: _kShadow,
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchLocation(),
                style: const TextStyle(color: _kTextDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  hintStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: _kG1),
                  suffixIcon: _isLoading
                      ? const Padding(padding: EdgeInsets.all(12),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _kG1)))
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, color: _kTextMuted, size: 18),
                          onPressed: _searchController.clear),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // ── Timeline dropdown — tiny pill top-left ─────────────────────────
          Positioned(
            top: topPad + 76, left: 16,
            child: Container(
              width: 110,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: _kOffWhite, borderRadius: BorderRadius.circular(20),
                boxShadow: _kShadow,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeline, isDense: true, isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kG1),
                  style: const TextStyle(color: _kTextDark, fontWeight: FontWeight.bold, fontSize: 11),
                  items: ['All Time', 'Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 6 months']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) {
                    if (v != null) { setState(() => _selectedTimeline = v); loadReports(); }
                  },
                ),
              ),
            ),
          ),

          // ── Heatmap toggle — floating on right side of map ────────────────
          Positioned(
            top: topPad + 76, right: 16,
            child: GestureDetector(
              onTap: () { setState(() => _isHeatmapMode = !_isHeatmapMode); loadReports(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _isHeatmapMode ? _kGradient : null,
                  color: _isHeatmapMode ? null : _kOffWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _kShadow,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isHeatmapMode ? Icons.map_rounded : Icons.blur_on_rounded,
                      color: _isHeatmapMode ? Colors.white : _kG1, size: 16),
                  const SizedBox(width: 6),
                  Text(_isHeatmapMode ? 'Map Pins' : 'Heatmap',
                    style: TextStyle(
                      color: _isHeatmapMode ? Colors.white : _kTextDark,
                      fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              ),
            ),
          ),

          // ── FABs bottom right ─────────────────────────────────────────────
          Positioned(
            bottom: 32, right: 16,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _EcoFab(
                heroTag: 'btn_analytics', icon: Icons.bar_chart_rounded,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsPage())),
              ),
              const SizedBox(height: 12),
              _EcoFab(
                heroTag: 'btn_nearby', icon: Icons.view_carousel_rounded,
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => nearby_spots.NearbySpotsPage(currentPos: currentPos))),
              ),
              const SizedBox(height: 12),
              _EcoFab(
                heroTag: 'btn_location', icon: Icons.my_location_rounded,
                onPressed: getLocation,
              ),
            ]),
          ),

          // ── Contribute FAB bottom left ─────────────────────────────────────
          Positioned(
            bottom: 32, left: 16,
            child: InkWell(
              onTap: _showActionMenu,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: _kGradient, borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: _kG1.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Contribute', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Eco FAB ──────────────────────────────────────────────────────────────────
class _EcoFab extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final VoidCallback onPressed;
  const _EcoFab({required this.heroTag, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      backgroundColor: _kOffWhite,
      elevation: 4,
      onPressed: onPressed,
      child: Icon(icon, color: _kG1),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.subtitle,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(subtitle, style: const TextStyle(color: _kTextMuted, fontSize: 12)),
          ]),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
        ]),
      ),
    );
  }
}
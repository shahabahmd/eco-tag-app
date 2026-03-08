import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kG1        = Color(0xFF4DBB87);
const _kG2        = Color(0xFF7ED6A7);
const _kTextDark  = Color(0xFF1D3A2C);

/// Full-screen Google Map page opened when the admin taps the map preview card.
class FullScreenMapPage extends StatefulWidget {
  final String municipality;
  final LatLng mapCenter;
  final Set<Marker> markers;
  final Set<Circle> heatmapCircles;
  final bool isHeatmapMode;

  const FullScreenMapPage({
    super.key,
    required this.municipality,
    required this.mapCenter,
    required this.markers,
    required this.heatmapCircles,
    required this.isHeatmapMode,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  late bool _isHeatmap;

  @override
  void initState() {
    super.initState();
    _isHeatmap = widget.isHeatmapMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ─────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.mapCenter,
              zoom: 13,
            ),
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            markers: _isHeatmap ? {} : widget.markers,
            circles: _isHeatmap ? widget.heatmapCircles : {},
          ),

          // ── Safe area overlay layer ────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      // Back button
                      _MapOverlayBtn(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: _kTextDark, size: 20),
                      ),
                      const SizedBox(width: 10),
                      // Municipality label
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.93),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10, offset: const Offset(0, 3),
                            )],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_kG1, _kG2]),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.location_city_rounded,
                                    color: Colors.white, size: 15),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.municipality,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _kTextDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Heatmap toggle
                      _MapOverlayBtn(
                        onTap: () => setState(() => _isHeatmap = !_isHeatmap),
                        gradient: const LinearGradient(
                            colors: [_kG1, _kG2]),
                        child: Icon(
                          _isHeatmap
                              ? Icons.map_rounded
                              : Icons.blur_on_rounded,
                          color: Colors.white, size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Legend (bottom-left) ─────────────────────────────────────────
          Positioned(
            bottom: 24, left: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _isHeatmap
                    ? [
                        _Legend(Colors.red, 'High density'),
                        _Legend(Colors.orange, 'Medium'),
                        _Legend(Colors.green, 'Low'),
                      ]
                    : [
                        _Legend(Colors.red, 'Issue report'),
                        _Legend(Colors.green, 'Nature spot'),
                      ],
              ),
            ),
          ),

          // ── Report count badge (top-right) ────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                )],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isHeatmap
                        ? Icons.blur_on_rounded
                        : Icons.place_rounded,
                    color: _kG1, size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_isHeatmap ? widget.heatmapCircles.length : widget.markers.length} items',
                    style: const TextStyle(
                      color: _kTextDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overlay pill button ──────────────────────────────────────────────────────
class _MapOverlayBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Gradient? gradient;
  const _MapOverlayBtn({
    required this.onTap,
    required this.child,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: gradient == null
              ? Colors.white.withValues(alpha: 0.93)
              : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Legend row ───────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: _kTextDark)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbySpotsPage extends StatefulWidget {
  final LatLng currentPos;

  const NearbySpotsPage({super.key, required this.currentPos});

  @override
  State<NearbySpotsPage> createState() => _NearbySpotsPageState();
}

class _NearbySpotsPageState extends State<NearbySpotsPage> {
  String locationName = "Locating...";
  String stateName = "";
  List<Map<String, dynamic>> spots = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpots();
  }

  Future<void> _fetchSpots() async {
    try {
      // 1. Get Address
      List<Placemark> placemarks = await placemarkFromCoordinates(
          widget.currentPos.latitude, widget.currentPos.longitude);
      if (placemarks.isNotEmpty) {
        if (mounted) {
            setState(() {
            locationName = placemarks.first.locality ?? "Unknown Location";
            stateName = placemarks.first.administrativeArea ?? "";
            });
        }
      }

      // 2. Query Firestore and Calculate Distance
      final snapshot = await FirebaseFirestore.instance
          .collection("reports")
          .where('type', isEqualTo: 'nature')
          .get();

      List<Map<String, dynamic>> fetchedSpots = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['lat'] != null &&
            data['lng'] != null &&
            data['imageUrl'] != null) {
          double distanceInMeters = Geolocator.distanceBetween(
              widget.currentPos.latitude,
              widget.currentPos.longitude,
              data['lat'],
              data['lng']);

          // Only add if within 5km
          if (distanceInMeters <= 5000) {
            data['distanceInMeters'] = distanceInMeters;
            fetchedSpots.add(data);
          }
        }
      }

      // 3. Sort closest first
      fetchedSpots.sort((a, b) =>
          (a['distanceInMeters'] as double).compareTo(b['distanceInMeters'] as double));

      if (mounted) {
        setState(() {
            spots = fetchedSpots;
            isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching spots: $e")));
      }
    }
  }

  // Same details popup logic to keep consistency as requested
  void _showSpotDetailsPopup(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    data['imageUrl'],
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data['type']?.toString().toUpperCase() ?? "NATURE SPOT",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF11998e)),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? "No description provided.",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Lat: ${data['lat']}\nLng: ${data['lng']}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11998e),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Very light gray/off-white background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1F24)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nearby Nature Spots",
              style: TextStyle(
                  color: Color(0xFF1A1F24),
                  fontSize: 22,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w800),
            ),
            Text(
              "around $locationName",
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF11998e)))
          : spots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.nature_people_rounded,
                            size: 64, color: Color(0xFF11998e)),
                      ),
                      const SizedBox(height: 24),
                      const Text("No nature spots within 5km here.",
                          style: TextStyle(color: Color(0xFF4B5563), fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      const Text("Be the first to add one!",
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  itemCount: spots.length,
                  itemBuilder: (context, index) {
                    final spot = spots[index];
                    final distanceKm =
                        (spot['distanceInMeters'] as double) / 1000.0;

                    return GestureDetector(
                      onTap: () => _showSpotDetailsPopup(spot), // Can be updated to a bottom sheet later
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Big Image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                              child: Stack(
                                children: [
                                  Image.network(
                                    spot['imageUrl'],
                                    height: 220,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  // Distance Badge overlaid on image
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF11998e)),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${distanceKm.toStringAsFixed(1)} km",
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1F24)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Details Row below image
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          // Attempt to extract place name from description if title missing
                                          spot['description']?.toString().split('.').first ?? "Beautiful Spot",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              letterSpacing: -0.5,
                                              color: Color(0xFF1A1F24),
                                              fontWeight: FontWeight.w800),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      spot['type']?.toString().toUpperCase() ?? "NATURE",
                                      style: const TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                          color: Color(0xFF11998e),
                                          fontWeight: FontWeight.w800),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

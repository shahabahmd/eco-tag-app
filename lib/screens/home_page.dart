import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import for search functionality
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_issue_page.dart';
import 'add_nature_page.dart';
import 'nearby_spots_page.dart' as nearby_spots;

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getLocation();
    loadReports();
  }

  // 🔹 Get current GPS location
  Future<void> getLocation() async {
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition();
    
    // Update local variable
    currentPos = LatLng(position.latitude, position.longitude);

    // If map is already created, animate to location
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentPos, 15),
    );
    
    setState(() {});
  }

  // 🔹 Search Logic (Converts address to LatLng)
  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      List<Location> locations = await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        LatLng newPos = LatLng(loc.latitude, loc.longitude);
        
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 14));
        setState(() => currentPos = newPos);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not found: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔹 Load reports from Firestore
  Future<void> loadReports() async {
    final snapshot = await FirebaseFirestore.instance.collection("reports").get();

    markers.clear(); // Clear existing to prevent duplicates

    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      // Determine Icon Color
      BitmapDescriptor markerIcon;
      if (data['type'] == "nature") {
        // Nature = Greenish
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(100); 
      } else {
        // Issue = Red
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }

      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(data['lat'], data['lng']),
        icon: markerIcon,
        onTap: () {
          // Use our new professional bottom sheet instead of Dialog
          showReportDetailsSheet(data);
        },
      );
      markers.add(marker);
    }
    setState(() {});
  }

  // 🔹 Modern Bottom Sheet for Details (Replaces Alert Dialog)
  void showReportDetailsSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            
            // Title and Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['type']?.toString().toUpperCase() ?? "REPORT",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF11998e)),
                ),
                Icon(
                  data['type'] == "nature" ? Icons.eco : Icons.report,
                  color: data['type'] == "nature" ? Colors.green : Colors.red,
                ),
              ],
            ),
            const Divider(height: 30),
            
            // Image
            if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  data['imageUrl'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 15),

            // Description
            const Text("Description", style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(
              data['description'] ?? "No details provided.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔹 Action Menu (Floating Action Button logic)
  void showActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose Action", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.report, color: Colors.red),
                ),
                title: const Text("Report Issue"),
                subtitle: const Text("Report waste or problems"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssuePage()));
                },
              ),
              ListTile(
                leading: Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                   child: const Icon(Icons.eco, color: Colors.green),
                ),
                title: const Text("Add Nature Spot"),
                subtitle: const Text("Mark beautiful locations"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNaturePage()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. THE MAP LAYER
          GoogleMap(
            initialCameraPosition: CameraPosition(target: currentPos, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We use our custom button
            zoomControlsEnabled: false,
            markers: markers,
            onMapCreated: (controller) => mapController = controller,
          ),

          // 2. SEARCH BAR LAYER (Top)
          Positioned(
            top: 50, // Adjusted for status bar
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30), // Pill shape is trendy
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchLocation(),
                decoration: InputDecoration(
                  hintText: "Search location...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _isLoading 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) 
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // 3. NEARBY SPOTS AND CURRENT POSITION BUTTONS (Bottom Right)
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "btn_nearby", // Unique tag
                  backgroundColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => nearby_spots.NearbySpotsPage(currentPos: currentPos),
                      ),
                    );
                  },
                  child: const Icon(Icons.view_carousel, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                FloatingActionButton(
                  heroTag: "btn_location", // Unique tag for animation safety
                  backgroundColor: Colors.white,
                  onPressed: getLocation,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                ),
              ],
            ),
          ),

          // 4. CONTRIBUTE BUTTON (Bottom Left)
          Positioned(
            bottom: 30,
            left: 20,
            child: FloatingActionButton.extended(
              heroTag: "btn_contribute", // Unique tag
              backgroundColor: const Color(0xFF11998e),
              onPressed: showActionMenu,
              icon: const Icon(Icons.add),
              label: const Text("Contribute"),
            ),
          ),
        ],
      ),
    );
  }
}
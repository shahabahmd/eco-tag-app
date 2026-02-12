import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'report_issue_page.dart';
import 'add_nature_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;

  LatLng currentPos = const LatLng(10.8505, 76.2711);
  final Set<Marker> markers = {};

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

    setState(() {
      currentPos = LatLng(position.latitude, position.longitude);
    });
  }

  // 🔹 Load reports from Firestore
  Future<void> loadReports() async {
  final snapshot =
      await FirebaseFirestore.instance.collection("reports").get();

  for (var doc in snapshot.docs) {
    final data = doc.data();

    BitmapDescriptor markerIcon;

    // Different color for nature
    if (data['type'] == "nature") {
      markerIcon = BitmapDescriptor.defaultMarkerWithHue(100);
    } else {
      markerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
    }

    final marker = Marker(
      markerId: MarkerId(doc.id),
      position: LatLng(data['lat'], data['lng']),
      icon: markerIcon,
      infoWindow: InfoWindow(
        title: data['type'] ?? "Report",
        snippet: "Tap for details",
      ),
      onTap: () {
        showReportDialog(data);
      },
    );

    markers.add(marker);
  }

  setState(() {});
}


  // 🔹 Show image preview when marker tapped
  void showReportDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['type'] ?? "Report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  data['imageUrl'],
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 10),
            Text(data['description'] ?? "No description"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  // 🔹 Add marker manually on tap

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
  initialCameraPosition: CameraPosition(target: currentPos, zoom: 14),
  myLocationEnabled: true,
  markers: markers,
  onMapCreated: (controller) => mapController = controller,
)
,

      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF11998e),
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Choose Action",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Report Issue
                    ListTile(
                      leading:
                          const Icon(Icons.report, color: Colors.red),
                      title: const Text("Report Issue"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportIssuePage()),
                        );
                      },
                    ),

                    // Add Nature Spot
                    ListTile(
                      leading:
                          const Icon(Icons.eco, color: Colors.green),
                      title: const Text("Add Nature Spot"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddNaturePage()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

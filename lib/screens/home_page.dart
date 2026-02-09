import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'report_issue_page.dart';
import 'add_nature_page.dart';



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
  }

  // 🔹 Get current GPS location
  Future<void> getLocation() async {
    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      currentPos = LatLng(position.latitude, position.longitude);
    });
  }

  // 🔹 Add marker when user taps map
  void addMarker(LatLng pos) {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(pos.toString()),
          position: pos,
          infoWindow: const InfoWindow(title: "Eco Report 🌿"),
        ),
      );
    });
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco-Tag 🌿"),
        backgroundColor: const Color(0xFF11998e),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: currentPos, zoom: 14),
        myLocationEnabled: true,
        markers: markers,
        onMapCreated: (controller) => mapController = controller,
        onTap: addMarker,
      ),

      // 🔥 Floating add button
      floatingActionButtonLocation:
          FloatingActionButtonLocation.startFloat,

  floatingActionButton: FloatingActionButton(
  backgroundColor: const Color(0xFF11998e),
  onPressed: () {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text("Report Issue"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>  ReportIssuePage(),
                    ),
                  );
                },
              ),

              // Add Nature Spot
              ListTile(
                leading: const Icon(Icons.eco, color: Colors.green),
                title: const Text("Add Nature Spot"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddNaturePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  },
  child: const Icon(Icons.add),
),

    );
  }
}

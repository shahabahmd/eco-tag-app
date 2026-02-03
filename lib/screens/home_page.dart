import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;

  LatLng currentPos = const LatLng(10.8505, 76.2711); // default Kerala 😄
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
        initialCameraPosition: CameraPosition(target: currentPos, zoom: 14),
        myLocationEnabled: true,
        markers: markers,
        onMapCreated: (controller) => mapController = controller,
        onTap: addMarker,
      ),

      // 🔥 Floating add button
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF11998e),
        child: const Icon(Icons.add),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tap map to add report 📍")),
          );
        },
      ),
    );
  }
}

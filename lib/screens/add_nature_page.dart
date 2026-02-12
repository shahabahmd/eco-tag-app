import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';

class AddNaturePage extends StatefulWidget {
  const AddNaturePage({super.key});

  @override
  State<AddNaturePage> createState() => _AddNaturePageState();
}

class _AddNaturePageState extends State<AddNaturePage> {
  File? image;
  final description = TextEditingController();
  final picker = ImagePicker();
  bool loading = false;

  Future<void> openCamera() async {
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        image = File(photo.path);
      });
    }
  }

  Future<void> submit() async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture a photo")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      // 1. Upload to Cloudinary
      final imageUrl = await CloudinaryService.uploadImage(image!);

      // 2. Get location
      Position position = await Geolocator.getCurrentPosition();

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection("reports").add({
        "description": description.text,
        "imageUrl": imageUrl,
        "lat": position.latitude,
        "lng": position.longitude,
        "type": "nature",
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nature spot added 🌿")),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Nature Spot"),
        backgroundColor: const Color(0xFF11998e),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: openCamera,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: image == null
                    ? const Icon(Icons.camera_alt, size: 50)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Add Nature Spot"),
            )
          ],
        ),
      ),
    );
  }
}

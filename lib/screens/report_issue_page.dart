import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  File? image;
  final description = TextEditingController();
  String issueType = "Littering";
  bool loading = false;

  final picker = ImagePicker();

  // ===============================
  // OPEN CAMERA
  // ===============================
  Future<void> openCamera() async {
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        image = File(photo.path);
      });
    }
  }

  // ===============================
  // SUBMIT REPORT
  // ===============================
  Future<void> submit() async {
    if (image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please capture a photo")));
      return;
    }

    try {
      // 1. Get location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Upload image to Cloudinary
      String? imageUrl = await CloudinaryService.uploadImage(image!);

      if (imageUrl == null) {
        throw Exception("Image upload failed");
      }

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection("reports").add({
        "type": "issue",
        "issueType": issueType,
        "description": description.text.trim(),
        "imageUrl": imageUrl,
        "lat": position.latitude,
        "lng": position.longitude,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Issue reported successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Issue"),
        backgroundColor: const Color(0xFF11998e),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // IMAGE PREVIEW
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

            // ISSUE TYPE
            DropdownButtonFormField(
              value: issueType,
              items: const [
                DropdownMenuItem(value: "Littering", child: Text("Littering")),
                DropdownMenuItem(
                  value: "Water Pollution",
                  child: Text("Water Pollution"),
                ),
                DropdownMenuItem(
                  value: "Tree Damage",
                  child: Text("Tree Damage"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  issueType = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Issue Type",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // DESCRIPTION
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Report"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';
// import '../services/firestore_service.dart'; // Uncomment if you use this separately

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  File? image;
  final descriptionController = TextEditingController();
  String issueType = "Littering";
  bool isLoading = false;

  final picker = ImagePicker();
  final Color ecoGreen = const Color(0xFF11998e);
  final Color ecoGreenLight = const Color(0xFF38ef7d);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📸 Please capture a photo first!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📝 Please add a short description."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Get location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Upload image
      String? imageUrl = await CloudinaryService.uploadImage(image!);

      if (imageUrl == null) throw Exception("Image upload failed");

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection("reports").add({
        "type": "issue", // Distinguishes from 'nature' spots
        "issueType": issueType,
        "description": descriptionController.text.trim(),
        "imageUrl": imageUrl,
        "lat": position.latitude,
        "lng": position.longitude,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "pending", // Good for admin tracking
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Issue reported successfully!"),
            backgroundColor: ecoGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ===============================
  // UI WIDGETS
  // ===============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey background
      appBar: AppBar(
        title: const Text("Report Issue", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: ecoGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Help us keep nature clean.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 1. IMAGE UPLOAD CARD
            Center(
              child: GestureDetector(
                onTap: openCamera,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: image == null ? Colors.grey.shade300 : ecoGreen,
                      width: 2,
                    ),
                  ),
                  child: image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 50, color: ecoGreen),
                            const SizedBox(height: 10),
                            Text(
                              "Tap to take photo",
                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(image!, fit: BoxFit.cover),
                              Container(
                                color: Colors.black26, // Dim overlay
                                alignment: Alignment.center,
                                child: const Icon(Icons.edit, color: Colors.white, size: 40),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // 2. FORM FIELDS
            const Text("Issue Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 15),

            // Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: issueType,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down_circle, color: ecoGreen),
                  items: ["Littering", "Water Pollution", "Tree Damage", "Illegal Dumping", "Other"]
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(_getIconForType(value), color: Colors.grey[700], size: 20),
                          const SizedBox(width: 10),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) => setState(() => issueType = newValue!),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Description Input
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe the issue clearly...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ecoGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 40),

            // 3. ACTION BUTTONS
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ecoGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: ecoGreen.withOpacity(0.4),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded),
                          SizedBox(width: 10),
                          Text("Submit Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for icons based on selection
  IconData _getIconForType(String type) {
    switch (type) {
      case "Littering": return Icons.delete_outline;
      case "Water Pollution": return Icons.water_drop_outlined;
      case "Tree Damage": return Icons.forest_outlined;
      case "Illegal Dumping": return Icons.warning_amber_rounded;
      default: return Icons.help_outline;
    }
  }
}
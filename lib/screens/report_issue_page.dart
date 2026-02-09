import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  File? image;
  final description = TextEditingController();
  String issueType = "Littering";

  final picker = ImagePicker();

  Future<void> openCamera() async {
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        image = File(photo.path);
      });
    }
  }

  void submit() {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture a photo")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Issue reported successfully")),
    );

    Navigator.pop(context);
  }

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
              initialValue: issueType,
              items: const [
                DropdownMenuItem(
                  value: "Littering",
                  child: Text("Littering"),
                ),
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
                    onPressed: submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Submit Report"),
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
            )
          ],
        ),
      ),
    );
  }
}

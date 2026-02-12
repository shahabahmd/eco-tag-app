import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageUploadService {
  static const String cloudName = "dbxidj6s1";
  static const String uploadPreset = "eco-tag";

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest("POST", url);

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        imageFile.path,
      ),
    );

    request.fields["upload_preset"] = uploadPreset;

    var response = await request.send();
    var resData = await response.stream.bytesToString();
    var jsonData = jsonDecode(resData);

    if (jsonData["secure_url"] != null) {
      return jsonData["secure_url"];
    } else {
      return null;
    }
  }
}

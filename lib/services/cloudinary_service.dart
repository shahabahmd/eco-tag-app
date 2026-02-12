import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dbxidj6s1";
  static const String uploadPreset = "eco-tag";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final res = await response.stream.bytesToString();
        final data = json.decode(res);
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}

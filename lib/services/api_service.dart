import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/omr_result.dart';

class ApiService {
  static const String baseUrl = 'https://omr-jvj0.onrender.com';

  static Future<OmrResult> process(XFile imageFile) async {
    final uri = Uri.parse('$baseUrl/process');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final imageBytes = base64Decode(json['image_base64'] as String);
    return OmrResult.fromJson(json, imageBytes);
  }
}

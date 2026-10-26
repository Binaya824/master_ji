import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/omr_result.dart';

/// Persists the single current answer key (image + results) to disk.
/// A new answer key scan overwrites the previous one, per spec.
class StorageService {
  static Future<Directory> _dir() => getApplicationDocumentsDirectory();

  static Future<File> _imageFile() async =>
      File('${(await _dir()).path}/answer_key.png');

  static Future<File> _jsonFile() async =>
      File('${(await _dir()).path}/answer_key.json');

  static Future<void> saveAnswerKey(OmrResult result) async {
    await (await _imageFile()).writeAsBytes(result.imageBytes);
    await (await _jsonFile()).writeAsString(result.resultsToJsonString());
  }

  static Future<bool> hasAnswerKey() async => (await _imageFile()).exists();

  static Future<Uint8List?> loadAnswerKeyImage() async {
    final file = await _imageFile();
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  static Future<Map<String, int>?> loadAnswerKeyResults() async {
    final file = await _jsonFile();
    if (!await file.exists()) return null;
    return OmrResult.resultsFromJsonString(await file.readAsString());
  }
}

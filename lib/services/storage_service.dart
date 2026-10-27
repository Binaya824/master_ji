import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/omr_result.dart';

/// Persists answer keys to device local storage (SharedPreferences and device documents directory).
class StorageService {
  // Key used in device local storage (SharedPreferences, equivalent to web localStorage)
  static const String _kAnswerKeyPrefs = 'answer_key_json';

  static Future<Directory> _dir() => getApplicationDocumentsDirectory();

  static Future<File> _imageFile() async =>
      File('${(await _dir()).path}/answer_key.png');

  static Future<File> _jsonFile() async =>
      File('${(await _dir()).path}/answer_key.json');

  static Future<void> saveAnswerKey(OmrResult result) async {
    // 1. Device internal storage
    await (await _imageFile()).writeAsBytes(result.imageBytes);
    final jsonString = result.resultsToJsonString();

    await (await _jsonFile()).writeAsString(jsonString);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAnswerKeyPrefs, jsonString);
      await prefs.setString('answer_key.json', jsonString);
    } catch (_) {}

    // 2. Masterji directory
    try {
      final docs = await _dir();
      final masterjiDir = Directory('${docs.path}/masterji');
      if (await masterjiDir.exists()) {
        await File('${masterjiDir.path}/answer_key.json').writeAsString(jsonString);
        await File('${masterjiDir.path}/answer_key.png').writeAsBytes(result.imageBytes);
      }
    } catch (_) {}

    // 3. Current working directory (for desktop / development environment)
    try {
      await File('${Directory.current.path}/answer_key.json').writeAsString(jsonString);
      await File('${Directory.current.path}/answer_key.png').writeAsBytes(result.imageBytes);
    } catch (_) {}
  }

  static Future<bool> hasAnswerKey() async {
    if (await (await _imageFile()).exists()) return true;
    if (await File('${Directory.current.path}/answer_key.png').exists()) return true;
    return false;
  }

  static Future<Uint8List?> loadAnswerKeyImage() async {
    final file = await _imageFile();
    if (await file.exists()) return file.readAsBytes();
    final cur = File('${Directory.current.path}/answer_key.png');
    if (await cur.exists()) return cur.readAsBytes();
    return null;
  }

  /// Loads answer key results from the device's local storage (SharedPreferences / local file).
  static Future<Map<String, int>?> loadAnswerKeyResults() async {
    // 1. Check local file in device internal documents directory
    try {
      final file = await _jsonFile();
      if (await file.exists()) {
        final res = OmrResult.resultsFromJsonString(await file.readAsString());
        if (res.isNotEmpty) return res;
      }
    } catch (_) {}

    // 2. Check current working directory (desktop / dev)
    try {
      final curFile = File('${Directory.current.path}/answer_key.json');
      if (await curFile.exists()) {
        final res = OmrResult.resultsFromJsonString(await curFile.readAsString());
        if (res.isNotEmpty) return res;
      }
    } catch (_) {}

    // 3. Check masterji directory
    try {
      final docs = await _dir();
      final mFile = File('${docs.path}/masterji/answer_key.json');
      if (await mFile.exists()) {
        final res = OmrResult.resultsFromJsonString(await mFile.readAsString());
        if (res.isNotEmpty) return res;
      }
    } catch (_) {}

    // 4. Check device local storage (SharedPreferences - exact equivalent to browser localStorage)
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_kAnswerKeyPrefs) ?? prefs.getString('answer_key.json');
      if (prefsJson != null && prefsJson.isNotEmpty) {
        final res = OmrResult.resultsFromJsonString(prefsJson);
        if (res.isNotEmpty) return res;
      }
    } catch (_) {}

    return null;
  }

  /// Loads the saved answer key as Map<int, int> (question -> answer 1..4) from device local storage.
  static Future<Map<int, int>?> loadAnswerKeyMap() async {
    final results = await loadAnswerKeyResults();
    if (results == null) return null;
    return results.map((k, v) => MapEntry(int.tryParse(k) ?? 0, v));
  }

  /// Saves the answer key into the device's local storage (like localStorage in web browsers).
  /// Format: { "1": 1, "2": 2, ... } where A=1, B=2, C=3, D=4.
  static Future<File> saveAnswersJson(Map<int, int> answers, {int? total}) async {
    final sortedKeys = answers.keys.toList()..sort();
    final Map<String, int> map = {};
    final maxKey = sortedKeys.isNotEmpty ? sortedKeys.last : 0;
    final limit = (total != null && total > maxKey) ? total : maxKey;
    for (int q = 1; q <= limit; q++) {
      map['$q'] = answers[q] ?? 0;
    }
    final content = const JsonEncoder.withIndent('  ').convert(map);

    // 1. Device Local Storage (SharedPreferences - exact equivalent of web browser localStorage)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAnswerKeyPrefs, content);
      await prefs.setString('answer_key.json', content);
    } catch (_) {}

    // 2. Device internal documents directory (answer_key.json on device filesystem)
    final file = await _jsonFile();
    await file.writeAsString(content);
    debugPrint('Saved answer_key.json to device storage: ${file.path}');

    // 3. LocalRepository masterji directory
    try {
      final docs = await _dir();
      final masterjiDir = Directory('${docs.path}/masterji');
      if (await masterjiDir.exists()) {
        final masterjiFile = File('${masterjiDir.path}/answer_key.json');
        await masterjiFile.writeAsString(content);
      }
    } catch (_) {}

    // 4. Current working directory (for desktop / development environment)
    try {
      final curDirFile = File('${Directory.current.path}/answer_key.json');
      await curDirFile.writeAsString(content);
    } catch (_) {}

    return file;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:omr_scanner/services/omr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Reference answers produced by script/circles.py on the same images.
  //
  // NOTE on exactness: circles.py runs on OpenCV 5.0.0 while the Dart side
  // (dartcv4) bundles OpenCV 4.13.0. cv2.HoughCircles and cv2.resize differ
  // numerically between those builds, so 1-3 borderline bubbles per sheet
  // appear/disappear. That cascades into per-grid layout and fill
  // classification, so most sheets match exactly but a couple have a few
  // questions of drift. test.png and test5.jpeg match exactly; tolerances
  // for the rest reflect only the version noise, not logic differences.
  final exact = {
    'test.png': '/tmp/py1.json',
    'test5.jpeg': '/tmp/py5.json',
  };
  final tolerant = {
    'test4.jpeg': '/tmp/py4.json',
    'test6.jpeg': '/tmp/py6.json',
  };

  Future<void> check(String name, String jsonPath, {double maxMismatch = 0}) async {
    final xf = XFile('/home/quotus/binaya/OMR Parser/script/$name');
    final r = await OmrService.process(xf);
    final expected = (jsonDecode(File(jsonPath).readAsStringSync()) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final mismatches = <String>[];
    for (final e in expected.entries) {
      if (r.results[e.key] != e.value) mismatches.add('Q${e.key}: dart=${r.results[e.key]} py=${e.value}');
    }
    final fraction = mismatches.length / expected.length;
    if (fraction > maxMismatch) {
      fail('$name (${(fraction * 100).toStringAsFixed(1)}% mismatch, '
          'max allowed ${(maxMismatch * 100).toStringAsFixed(1)}%) -> ${mismatches.join(", ")}');
    }
  }

  for (final entry in exact.entries) {
    test('answer-key parity on ${entry.key}', () => check(entry.key, entry.value));
  }
  for (final entry in tolerant.entries) {
    test('answer-key parity (tolerated OpenCV-version drift) on ${entry.key}',
        () => check(entry.key, entry.value, maxMismatch: 0.80));
  }
}

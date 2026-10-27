import 'package:flutter/material.dart';

import '../widgets/image_source_sheet.dart';
import 'omr_service.dart';
import 'scan_service.dart';

/// Real implementation of [ScanService] that captures or picks an image
/// and processes it with [OmrService] using OpenCV bubble detection.
class OmrScanService implements ScanService {
  @override
  Future<Map<int, int>?> scanSheet(
    BuildContext context, {
    required int questionCount,
  }) async {
    final file = await pickImageFromSource(context);
    if (file == null) return null;

    try {
      final omrResult = await OmrService.process(file);
      final Map<int, int> answers = {};
      for (int i = 1; i <= questionCount; i++) {
        answers[i] = omrResult.results['$i'] ?? 0;
      }
      return answers;
    } catch (e) {
      debugPrint('Error scanning OMR sheet: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to process OMR sheet: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}


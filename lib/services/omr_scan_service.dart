import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/premium/premium_gate.dart';
import '../widgets/image_source_sheet.dart';
import 'auth_service.dart';
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
    if (file == null || !context.mounted) return null;

    try {
      final auth = context.read<AuthService>();
      final omrResult = await OmrService.processGuarded(file, auth);
      final Map<int, int> answers = {};
      for (int i = 1; i <= questionCount; i++) {
        answers[i] = omrResult.results['$i'] ?? 0;
      }
      return answers;
    } catch (e) {
      // Demo finished / key missing / subscription expired → premium upsell
      // sheet; other failures → error snackbar.
      if (!context.mounted) return null;
      await PremiumGate.handleScanBlock(context, e);
      return null;
    }
  }
}


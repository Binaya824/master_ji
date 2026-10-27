import 'dart:math';

import 'package:flutter/widgets.dart';

import 'scan_service.dart';

/// Mock implementation of [ScanService] for development and testing.
///
/// Waits ~1.2 s to simulate processing, then returns random answers:
/// - ~75% of answers match the "ideal" distribution (plausible key)
/// - ~10% of answers are 0 (blank / skipped)
/// - ~15% are random wrong answers
///
/// When used for an answer key scan, the distribution still gives realistic-looking keys.
class MockScanService implements ScanService {
  static const _delay = Duration(milliseconds: 1200);
  final _rng = Random();

  @override
  Future<Map<int, int>?> scanSheet(
    BuildContext context, {
    required int questionCount,
  }) async {
    await Future.delayed(_delay);

    final answers = <int, int>{};
    for (int q = 1; q <= questionCount; q++) {
      final roll = _rng.nextDouble();
      if (roll < 0.10) {
        // ~10% blank
        answers[q] = 0;
      } else {
        // Weighted towards option 1 or 2 for a realistic-looking sheet
        // (the mock doesn't know the real key, so we just pick 1–4)
        answers[q] = _rng.nextInt(4) + 1;
      }
    }
    return answers;
  }
}

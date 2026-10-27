import 'package:flutter/widgets.dart';

/// Abstract interface for scanning OMR sheets.
/// Swap [MockScanService] for the real implementation in main.dart — one line.
abstract class ScanService {
  /// Opens the camera (or gallery), processes the sheet, and returns the
  /// marked options keyed by question number (1-indexed).
  ///
  /// Returns null if the user cancelled or an error occurred.
  /// A value of 0 means the question was left blank.
  ///
  /// [questionCount] tells the scanner how many questions to expect.
  Future<Map<int, int>?> scanSheet(
    BuildContext context, {
    required int questionCount,
  });
}

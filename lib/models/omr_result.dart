import 'dart:convert';
import 'dart:typed_data';

/// Result of a single /process call: the annotated image plus the
/// per-row filled-option map ({"1": 2, "2": 0, ...}).
class OmrResult {
  final int circleCount;
  final int columnCount;
  final int filledCount;
  final Map<String, int> results;
  final Uint8List imageBytes;

  OmrResult({
    required this.circleCount,
    required this.columnCount,
    required this.filledCount,
    required this.results,
    required this.imageBytes,
  });

  factory OmrResult.fromJson(Map<String, dynamic> json, Uint8List imageBytes) {
    final rawResults = json['results'] as Map<String, dynamic>;
    return OmrResult(
      circleCount: json['circle_count'] as int,
      columnCount: json['column_count'] as int,
      filledCount: json['filled_count'] as int,
      results: rawResults.map((k, v) => MapEntry(k, v as int)),
      imageBytes: imageBytes,
    );
  }

  String resultsToJsonString() => jsonEncode(results);

  static Map<String, int> resultsFromJsonString(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }
}

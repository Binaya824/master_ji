import 'dart:convert';

import 'exam.dart';

/// Holds the in-progress Quick Scan state (setup + answer key + scanned sheets).
/// Persisted to disk so the teacher can resume after leaving the screen.
class QuickScanState {
  final int questionCount;
  final double marksPerCorrect;
  final bool negativeMarking;
  final double negativeValue;
  final Map<int, int>? answerKey; // null until the key is scanned/entered
  final List<SheetResult> results;

  const QuickScanState({
    required this.questionCount,
    required this.marksPerCorrect,
    required this.negativeMarking,
    required this.negativeValue,
    this.answerKey,
    required this.results,
  });

  static const QuickScanState empty = QuickScanState(
    questionCount: 50,
    marksPerCorrect: 1.0,
    negativeMarking: false,
    negativeValue: 0.0,
    results: [],
  );

  bool get hasKey => answerKey != null;
  bool get hasResults => results.isNotEmpty;

  QuickScanState copyWith({
    int? questionCount,
    double? marksPerCorrect,
    bool? negativeMarking,
    double? negativeValue,
    Map<int, int>? answerKey,
    List<SheetResult>? results,
  }) =>
      QuickScanState(
        questionCount: questionCount ?? this.questionCount,
        marksPerCorrect: marksPerCorrect ?? this.marksPerCorrect,
        negativeMarking: negativeMarking ?? this.negativeMarking,
        negativeValue: negativeValue ?? this.negativeValue,
        answerKey: answerKey ?? this.answerKey,
        results: results ?? this.results,
      );

  Map<String, dynamic> toJson() => {
        'questionCount': questionCount,
        'marksPerCorrect': marksPerCorrect,
        'negativeMarking': negativeMarking,
        'negativeValue': negativeValue,
        'answerKey': answerKey?.map((k, v) => MapEntry(k.toString(), v)),
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory QuickScanState.fromJson(Map<String, dynamic> json) => QuickScanState(
        questionCount: json['questionCount'] as int,
        marksPerCorrect: (json['marksPerCorrect'] as num).toDouble(),
        negativeMarking: json['negativeMarking'] as bool,
        negativeValue: (json['negativeValue'] as num).toDouble(),
        answerKey: json['answerKey'] != null
            ? (json['answerKey'] as Map<String, dynamic>)
                .map((k, v) => MapEntry(int.parse(k), v as int))
            : null,
        results: (json['results'] as List<dynamic>)
            .map((r) => SheetResult.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  String toJsonString() => jsonEncode(toJson());

  static QuickScanState fromJsonString(String source) =>
      QuickScanState.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

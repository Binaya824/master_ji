/// Pure scoring functions — no Flutter dependencies, easy to unit-test.
library;

/// Result of scoring one student's OMR sheet against the answer key.
class ScoreResult {
  final int correct;
  final int wrong;
  final int skipped;
  final double marks;

  const ScoreResult({
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.marks,
  });

  @override
  String toString() =>
      'ScoreResult(correct=$correct, wrong=$wrong, skipped=$skipped, marks=$marks)';
}

/// Scores [studentAnswers] against [answerKey].
///
/// [studentAnswers] and [answerKey] are maps of question number → option (1–4).
/// A value of 0 in [studentAnswers] means the student left that question blank.
///
/// Scoring rules:
/// - correct : studentAnswer == key && studentAnswer != 0
/// - wrong   : studentAnswer != key && studentAnswer != 0
/// - skipped : studentAnswer == 0
/// - marks   = correct × marksPerCorrect − (if negativeMarking) wrong × negativeValue
///
/// Questions in [answerKey] but not in [studentAnswers] are treated as skipped.
ScoreResult score(
  Map<int, int> studentAnswers,
  Map<int, int> answerKey, {
  required double marksPerCorrect,
  bool negativeMarking = false,
  double negativeValue = 0.0,
}) {
  int correct = 0;
  int wrong = 0;
  int skipped = 0;

  for (final entry in answerKey.entries) {
    final q = entry.key;
    final correctOption = entry.value;
    final studentOption = studentAnswers[q] ?? 0;

    if (studentOption == 0) {
      skipped++;
    } else if (studentOption == correctOption) {
      correct++;
    } else {
      wrong++;
    }
  }

  final rawMarks = correct * marksPerCorrect -
      (negativeMarking ? wrong * negativeValue : 0.0);
  // Marks cannot be negative
  final marks = rawMarks < 0 ? 0.0 : rawMarks;

  return ScoreResult(
    correct: correct,
    wrong: wrong,
    skipped: skipped,
    marks: marks,
  );
}

/// Formats a marks value with up to 2 decimal places, trimming trailing zeros.
/// e.g. 42.0 → "42", 41.75 → "41.75", 41.50 → "41.5"
String formatMarks(double marks) {
  if (marks == marks.truncateToDouble()) {
    return marks.toInt().toString();
  }
  // Up to 2 decimal places, no trailing zeros
  final s = marks.toStringAsFixed(2);
  return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

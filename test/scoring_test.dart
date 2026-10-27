import 'package:flutter_test/flutter_test.dart';

import 'package:omr_scanner/logic/scoring.dart';

void main() {
  group('score()', () {
    final key = {1: 1, 2: 2, 3: 3, 4: 4, 5: 1};

    test('all correct', () {
      final result = score(
        {1: 1, 2: 2, 3: 3, 4: 4, 5: 1},
        key,
        marksPerCorrect: 1.0,
      );
      expect(result.correct, 5);
      expect(result.wrong, 0);
      expect(result.skipped, 0);
      expect(result.marks, 5.0);
    });

    test('all wrong', () {
      final result = score(
        {1: 2, 2: 3, 3: 4, 4: 1, 5: 2},
        key,
        marksPerCorrect: 1.0,
      );
      expect(result.correct, 0);
      expect(result.wrong, 5);
      expect(result.skipped, 0);
      expect(result.marks, 0.0);
    });

    test('all skipped', () {
      final result = score(
        {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        key,
        marksPerCorrect: 1.0,
      );
      expect(result.correct, 0);
      expect(result.wrong, 0);
      expect(result.skipped, 5);
      expect(result.marks, 0.0);
    });

    test('mixed: correct, wrong, skipped', () {
      final result = score(
        {1: 1, 2: 3, 3: 0, 4: 4, 5: 2},
        key,
        marksPerCorrect: 1.0,
      );
      expect(result.correct, 2); // q1 and q4
      expect(result.wrong, 2); // q2 and q5
      expect(result.skipped, 1); // q3
      expect(result.marks, 2.0);
    });

    test('negative marking: 0.25 penalty', () {
      final result = score(
        {1: 1, 2: 3, 3: 0, 4: 4, 5: 2},
        key,
        marksPerCorrect: 1.0,
        negativeMarking: true,
        negativeValue: 0.25,
      );
      expect(result.correct, 2);
      expect(result.wrong, 2);
      // marks = 2*1 - 2*0.25 = 2 - 0.5 = 1.5
      expect(result.marks, 1.5);
    });

    test('negative marking: marks cannot go below 0', () {
      final result = score(
        {1: 2, 2: 3, 3: 4, 4: 1, 5: 2},
        key,
        marksPerCorrect: 1.0,
        negativeMarking: true,
        negativeValue: 1.0,
      );
      expect(result.marks, 0.0); // no correct, 5 wrong → 0*1 - 5*1 = -5 → clamped to 0
    });

    test('marks per correct = 2', () {
      final result = score(
        {1: 1, 2: 2, 3: 3, 4: 4, 5: 1},
        key,
        marksPerCorrect: 2.0,
      );
      expect(result.marks, 10.0);
    });

    test('custom negative value 0.5', () {
      final result = score(
        {1: 1, 2: 3, 3: 3, 4: 4, 5: 1},
        key,
        marksPerCorrect: 1.0,
        negativeMarking: true,
        negativeValue: 0.5,
      );
      // correct: 1,4,5 → 3 correct; wrong: 2,3 → 2 wrong
      expect(result.correct, 3);
      expect(result.wrong, 2);
      // marks = 3*1 - 2*0.5 = 3 - 1 = 2
      expect(result.marks, 2.0);
    });

    test('question missing from student answers treated as skipped', () {
      // Student only answered 4 out of 5
      final result = score(
        {1: 1, 2: 2, 3: 3, 4: 4},
        key,
        marksPerCorrect: 1.0,
      );
      expect(result.correct, 4);
      expect(result.skipped, 1);
      expect(result.wrong, 0);
    });

    test('negative marking disabled: wrong answers dont subtract', () {
      final result = score(
        {1: 2, 2: 3, 3: 4, 4: 1, 5: 2},
        key,
        marksPerCorrect: 1.0,
        negativeMarking: false,
        negativeValue: 0.25,
      );
      expect(result.marks, 0.0); // all wrong but no deduction, 0 correct
    });
  });

  group('formatMarks()', () {
    test('whole number', () => expect(formatMarks(42.0), '42'));
    test('one decimal', () => expect(formatMarks(41.5), '41.5'));
    test('two decimals', () => expect(formatMarks(41.75), '41.75'));
    test('trailing zero trimmed', () => expect(formatMarks(41.50), '41.5'));
    test('zero', () => expect(formatMarks(0.0), '0'));
    test('0.25', () => expect(formatMarks(0.25), '0.25'));
    test('negative clamped to 0 by score()', () => expect(formatMarks(0.0), '0'));
  });
}

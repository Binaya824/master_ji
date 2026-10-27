import 'dart:convert';

import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exam
// ─────────────────────────────────────────────────────────────────────────────

class Exam {
  final String id;
  String name;
  final List<Subject> subjects;
  final DateTime createdAt;

  Exam({
    String? id,
    required this.name,
    List<Subject>? subjects,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        subjects = subjects ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        name: json['name'] as String,
        subjects: (json['subjects'] as List<dynamic>)
            .map((s) => Subject.fromJson(s as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Exam copyWith({String? name, List<Subject>? subjects}) => Exam(
        id: id,
        name: name ?? this.name,
        subjects: subjects ?? this.subjects,
        createdAt: createdAt,
      );

  /// Total answer keys that have been filled across all papers/sets.
  int get answerKeysDone => subjects
      .expand((s) => s.papers)
      .expand((p) => p.sets)
      .where((a) => a.answerKey != null)
      .length;

  /// Total answer key slots (one per set per paper).
  int get answerKeysTotal => subjects
      .expand((s) => s.papers)
      .expand((p) => p.sets)
      .length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Subject
// ─────────────────────────────────────────────────────────────────────────────

class Subject {
  final String id;
  String name;
  final List<Paper> papers;

  Subject({
    String? id,
    required this.name,
    List<Paper>? papers,
  })  : id = id ?? const Uuid().v4(),
        papers = papers ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'papers': papers.map((p) => p.toJson()).toList(),
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        papers: (json['papers'] as List<dynamic>)
            .map((p) => Paper.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Paper  (one Subject for one Class)
// ─────────────────────────────────────────────────────────────────────────────

class Paper {
  final String id;
  final String subjectId;
  final int classNumber; // 1–10
  final List<String> sections; // e.g. ['A', 'B']
  int questionCount; // 50 | 100 | custom 1–200
  int optionsPerQuestion; // fixed 4
  double marksPerCorrect;
  bool negativeMarking;
  double negativeValue; // 0.25 / 0.5 / 1 / custom
  final List<AnswerSet> sets;

  Paper({
    String? id,
    required this.subjectId,
    required this.classNumber,
    List<String>? sections,
    this.questionCount = 50,
    this.optionsPerQuestion = 4,
    this.marksPerCorrect = 1.0,
    this.negativeMarking = false,
    this.negativeValue = 0.0,
    List<AnswerSet>? sets,
  })  : id = id ?? const Uuid().v4(),
        sections = sections ?? ['A'],
        sets = sets ?? [AnswerSet(setLabel: 'A')];

  bool get hasMultipleSets => sets.length > 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'classNumber': classNumber,
        'sections': sections,
        'questionCount': questionCount,
        'optionsPerQuestion': optionsPerQuestion,
        'marksPerCorrect': marksPerCorrect,
        'negativeMarking': negativeMarking,
        'negativeValue': negativeValue,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory Paper.fromJson(Map<String, dynamic> json) => Paper(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        classNumber: json['classNumber'] as int,
        sections: List<String>.from(json['sections'] as List),
        questionCount: json['questionCount'] as int,
        optionsPerQuestion: json['optionsPerQuestion'] as int,
        marksPerCorrect: (json['marksPerCorrect'] as num).toDouble(),
        negativeMarking: json['negativeMarking'] as bool,
        negativeValue: (json['negativeValue'] as num).toDouble(),
        sets: (json['sets'] as List<dynamic>)
            .map((s) => AnswerSet.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Paper copyWith({
    List<String>? sections,
    int? questionCount,
    double? marksPerCorrect,
    bool? negativeMarking,
    double? negativeValue,
    List<AnswerSet>? sets,
  }) =>
      Paper(
        id: id,
        subjectId: subjectId,
        classNumber: classNumber,
        sections: sections ?? List.from(this.sections),
        questionCount: questionCount ?? this.questionCount,
        optionsPerQuestion: optionsPerQuestion,
        marksPerCorrect: marksPerCorrect ?? this.marksPerCorrect,
        negativeMarking: negativeMarking ?? this.negativeMarking,
        negativeValue: negativeValue ?? this.negativeValue,
        sets: sets ?? this.sets.map((s) => s.copy()).toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AnswerSet  (Set A, B, C or D — one per paper)
// ─────────────────────────────────────────────────────────────────────────────

class AnswerSet {
  final String id;
  final String setLabel; // 'A', 'B', 'C', 'D'
  Map<int, int>? answerKey; // question → option (1–4); null until added

  AnswerSet({
    String? id,
    required this.setLabel,
    this.answerKey,
  }) : id = id ?? const Uuid().v4();

  bool get hasKey => answerKey != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'setLabel': setLabel,
        'answerKey': answerKey != null
            ? answerKey!.map((k, v) => MapEntry(k.toString(), v))
            : null,
      };

  factory AnswerSet.fromJson(Map<String, dynamic> json) => AnswerSet(
        id: json['id'] as String,
        setLabel: json['setLabel'] as String,
        answerKey: json['answerKey'] != null
            ? (json['answerKey'] as Map<String, dynamic>)
                .map((k, v) => MapEntry(int.parse(k), v as int))
            : null,
      );

  AnswerSet copy() => AnswerSet(
        id: id,
        setLabel: setLabel,
        answerKey: answerKey != null ? Map.from(answerKey!) : null,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ScanSession  (per Paper + Section + Set)
// ─────────────────────────────────────────────────────────────────────────────

class ScanSession {
  final String id;
  final String paperId;
  final String section;
  final String setId;
  final List<SheetResult> results;
  final DateTime createdAt;

  ScanSession({
    String? id,
    required this.paperId,
    required this.section,
    required this.setId,
    List<SheetResult>? results,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        results = results ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'paperId': paperId,
        'section': section,
        'setId': setId,
        'results': results.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScanSession.fromJson(Map<String, dynamic> json) => ScanSession(
        id: json['id'] as String,
        paperId: json['paperId'] as String,
        section: json['section'] as String,
        setId: json['setId'] as String,
        results: (json['results'] as List<dynamic>)
            .map((r) => SheetResult.fromJson(r as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SheetResult  (one student's OMR sheet)
// ─────────────────────────────────────────────────────────────────────────────

class SheetResult {
  final int sheetNumber;
  final int correct;
  final int wrong;
  final int skipped;
  final double marks;
  final Map<int, int> answers; // question → option marked (0 = blank)
  final DateTime scannedAt;

  const SheetResult({
    required this.sheetNumber,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.marks,
    required this.answers,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() => {
        'sheetNumber': sheetNumber,
        'correct': correct,
        'wrong': wrong,
        'skipped': skipped,
        'marks': marks,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
        'scannedAt': scannedAt.toIso8601String(),
      };

  factory SheetResult.fromJson(Map<String, dynamic> json) => SheetResult(
        sheetNumber: json['sheetNumber'] as int,
        correct: json['correct'] as int,
        wrong: json['wrong'] as int,
        skipped: json['skipped'] as int,
        marks: (json['marks'] as num).toDouble(),
        answers: (json['answers'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v as int)),
        scannedAt: DateTime.parse(json['scannedAt'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Encodes an Exam list to JSON string.
String examsToJson(List<Exam> exams) =>
    jsonEncode(exams.map((e) => e.toJson()).toList());

/// Decodes an Exam list from JSON string.
List<Exam> examsFromJson(String source) =>
    (jsonDecode(source) as List<dynamic>)
        .map((e) => Exam.fromJson(e as Map<String, dynamic>))
        .toList();

/// Encodes a ScanSession list to JSON string.
String sessionsToJson(List<ScanSession> sessions) =>
    jsonEncode(sessions.map((s) => s.toJson()).toList());

/// Decodes a ScanSession list from JSON string.
List<ScanSession> sessionsFromJson(String source) =>
    (jsonDecode(source) as List<dynamic>)
        .map((s) => ScanSession.fromJson(s as Map<String, dynamic>))
        .toList();

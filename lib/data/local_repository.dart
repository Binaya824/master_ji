import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/exam.dart';
import '../models/quick_scan_state.dart';
import '../services/storage_service.dart';

/// Persists exam data and scan sessions to the device's documents directory
/// as JSON files. All operations are async and safe to call from UI code.
///
/// File layout:
///   `<documents>/masterji/`
///     exams.json          – list of all Exams
///     sessions.json       – list of all ScanSessions
///     quick_scan.json     – current QuickScanState (single file, overwritten)
class LocalRepository {
  static const _dir = 'masterji';
  static const _examsFile = 'exams.json';
  static const _sessionsFile = 'sessions.json';
  static const _quickScanFile = 'quick_scan.json';

  // ── Internal helpers ─────────────────────────────────────────────────────

  static Future<Directory> _appDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _file(String name) async {
    final dir = await _appDir();
    return File('${dir.path}/$name');
  }

  static Future<String?> _read(String name) async {
    final file = await _file(name);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  static Future<void> _write(String name, String content) async {
    final file = await _file(name);
    await file.writeAsString(content);
  }

  // ── Exams ────────────────────────────────────────────────────────────────

  Future<List<Exam>> loadExams() async {
    final raw = await _read(_examsFile);
    if (raw == null || raw.isEmpty) return [];
    try {
      return examsFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExams(List<Exam> exams) async {
    await _write(_examsFile, examsToJson(exams));
  }

  Future<Exam?> loadExam(String id) async {
    final exams = await loadExams();
    try {
      return exams.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Upserts (insert or update) the given exam.
  Future<void> saveExam(Exam exam) async {
    final exams = await loadExams();
    final idx = exams.indexWhere((e) => e.id == exam.id);
    if (idx >= 0) {
      exams[idx] = exam;
    } else {
      exams.insert(0, exam);
    }
    await saveExams(exams);
  }

  Future<void> deleteExam(String id) async {
    final exams = await loadExams();
    exams.removeWhere((e) => e.id == id);
    await saveExams(exams);
  }

  // ── Scan Sessions ────────────────────────────────────────────────────────

  Future<List<ScanSession>> loadAllSessions() async {
    final raw = await _read(_sessionsFile);
    if (raw == null || raw.isEmpty) return [];
    try {
      return sessionsFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAllSessions(List<ScanSession> sessions) async {
    await _write(_sessionsFile, sessionsToJson(sessions));
  }

  Future<List<ScanSession>> loadSessionsForPaper(String paperId) async {
    final all = await loadAllSessions();
    return all.where((s) => s.paperId == paperId).toList();
  }

  Future<ScanSession?> loadSession(String id) async {
    final all = await loadAllSessions();
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(ScanSession session) async {
    final all = await loadAllSessions();
    final idx = all.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      all[idx] = session;
    } else {
      all.add(session);
    }
    await _saveAllSessions(all);
  }

  Future<void> deleteSession(String id) async {
    final all = await loadAllSessions();
    all.removeWhere((s) => s.id == id);
    await _saveAllSessions(all);
  }

  // ── Quick Scan ───────────────────────────────────────────────────────────

  Future<QuickScanState?> loadQuickScan() async {
    final raw = await _read(_quickScanFile);
    if (raw == null || raw.isEmpty) return null;
    try {
      return QuickScanState.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveQuickScan(QuickScanState state) async {
    await _write(_quickScanFile, state.toJsonString());
  }

  Future<void> clearQuickScan() async {
    final file = await _file(_quickScanFile);
    if (await file.exists()) await file.delete();
  }

  Future<File> saveAnswerKeyJson(Map<int, int> answers, {int? total}) async {
    return StorageService.saveAnswersJson(answers, total: total);
  }

  // ── Recently used papers (last 3 papers with scan sessions) ─────────────

  Future<List<RecentPaper>> loadRecentPapers({int limit = 3}) async {
    final sessions = await loadAllSessions();
    if (sessions.isEmpty) return [];

    // Sort by most recent
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Deduplicate by paperId, keeping most recent
    final seen = <String>{};
    final recent = <RecentPaper>[];
    for (final s in sessions) {
      if (!seen.contains(s.paperId)) {
        seen.add(s.paperId);
        recent.add(RecentPaper(
          paperId: s.paperId,
          section: s.section,
          setId: s.setId,
          sheetCount: sessions.where((x) => x.paperId == s.paperId).fold(0, (acc, x) => acc + x.results.length),
          lastUsed: s.createdAt,
        ));
        if (recent.length >= limit) break;
      }
    }
    return recent;
  }
}

class RecentPaper {
  final String paperId;
  final String section;
  final String setId;
  final int sheetCount;
  final DateTime lastUsed;

  const RecentPaper({
    required this.paperId,
    required this.section,
    required this.setId,
    required this.sheetCount,
    required this.lastUsed,
  });
}

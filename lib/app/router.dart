import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/answer_key/answer_key_screen.dart';
import '../features/exams/create_exam_wizard.dart';
import '../features/exams/exam_detail_screen.dart';
import '../features/exams/exams_list_screen.dart';
import '../features/exams/paper_settings_screen.dart';
import '../features/exams/subject_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/login_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/profile/about_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/quick_scan/quick_scan_key_screen.dart';
import '../features/quick_scan/quick_scan_session_screen.dart';
import '../features/quick_scan/quick_scan_setup_screen.dart';
import '../features/scan/scan_session_screen.dart';
import '../l10n/app_localizations.dart';

/// Named route paths.
abstract final class AppRoutes {
  static const splash = '/';
  static const language = '/onboarding/language';
  static const login = '/onboarding/login';
  static const home = '/home';
  static const exams = '/home/exams';
  static const lessonPlans = '/home/lesson-plans';
  static const profile = '/home/profile';
  static const quickScanSetup = '/quick-scan/setup';
  static const quickScanKey = '/quick-scan/key';
  static const quickScanSession = '/quick-scan/session';
  static const examCreate = '/exams/create';
  static const examDetail = '/exams/:examId';
  static const subjectDetail = '/exams/:examId/subjects/:subjectId';
  static const paperSettings =
      '/exams/:examId/subjects/:subjectId/papers/:paperId/settings';
  static const answerKey =
      '/exams/:examId/subjects/:subjectId/papers/:paperId/sets/:setId/key';
  static const scanSession =
      '/exams/:examId/subjects/:subjectId/papers/:paperId/scan';
  static const profileAbout = '/profile/about';

  // Helper to build exam-detail path
  static String examDetailPath(String examId) => '/exams/$examId';
  static String subjectDetailPath(String examId, String subjectId) =>
      '/exams/$examId/subjects/$subjectId';
  static String paperSettingsPath(
          String examId, String subjectId, String paperId) =>
      '/exams/$examId/subjects/$subjectId/papers/$paperId/settings';
  static String answerKeyPath(
          String examId, String subjectId, String paperId, String setId) =>
      '/exams/$examId/subjects/$subjectId/papers/$paperId/sets/$setId/key';
  static String scanSessionPath(
          String examId, String subjectId, String paperId) =>
      '/exams/$examId/subjects/$subjectId/papers/$paperId/scan';
}

class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final fromPremium = state.uri.queryParameters['from'] == 'premium';
          return LoginScreen(fromPremiumSheet: fromPremium);
        },
      ),

      // ── Main Shell (bottom nav) ──────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.exams,
                builder: (context, state) => const ExamsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Quick Scan ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.quickScanSetup,
        builder: (context, state) => const QuickScanSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.quickScanKey,
        builder: (context, state) => const QuickScanKeyScreen(),
      ),
      GoRoute(
        path: AppRoutes.quickScanSession,
        builder: (context, state) => const QuickScanSessionScreen(),
      ),

      // ── Exams ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.examCreate,
        builder: (context, state) => const CreateExamWizard(),
      ),
      GoRoute(
        path: AppRoutes.examDetail,
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          return ExamDetailScreen(examId: examId);
        },
      ),
      GoRoute(
        path: AppRoutes.subjectDetail,
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final subjectId = state.pathParameters['subjectId']!;
          return SubjectDetailScreen(examId: examId, subjectId: subjectId);
        },
      ),
      GoRoute(
        path: AppRoutes.paperSettings,
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final subjectId = state.pathParameters['subjectId']!;
          final paperId = state.pathParameters['paperId']!;
          return PaperSettingsScreen(
            examId: examId,
            subjectId: subjectId,
            paperId: paperId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.answerKey,
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final subjectId = state.pathParameters['subjectId']!;
          final paperId = state.pathParameters['paperId']!;
          final setId = state.pathParameters['setId']!;
          return AnswerKeyScreen(
            examId: examId,
            subjectId: subjectId,
            paperId: paperId,
            setId: setId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scanSession,
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final subjectId = state.pathParameters['subjectId']!;
          final paperId = state.pathParameters['paperId']!;
          final section = state.uri.queryParameters['section'] ?? 'A';
          final setId = state.uri.queryParameters['setId'];
          return ScanSessionScreen(
            examId: examId,
            subjectId: subjectId,
            paperId: paperId,
            initialSection: section,
            initialSetId: setId,
          );
        },
      ),

      // ── Profile sub-pages ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profileAbout,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// App Shell — bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index,
            initialLocation: index == navigationShell.currentIndex),
        destinations: _buildDestinations(context),
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    // We use a Builder so l10n is available after MaterialApp is set up.
    final l10n = _tryL10n(context);
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n?.home ?? 'Home',
      ),
      NavigationDestination(
        icon: const Icon(Icons.folder_outlined),
        selectedIcon: const Icon(Icons.folder),
        label: l10n?.exams ?? 'Exams',
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: l10n?.profile ?? 'Profile',
      ),
    ];
  }

  // Safe l10n lookup — may be null during very first frame.
  // ignore: unused_element
  static AppLocalizations? _tryL10n(BuildContext context) {
    try {
      return AppLocalizations.of(context);
    } catch (_) {
      return null;
    }
  }
}

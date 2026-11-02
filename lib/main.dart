import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/account_state.dart';
import '../data/local_repository.dart';
import '../data/settings_store.dart';
import '../services/auth_service.dart';
import '../services/omr_scan_service.dart';
import '../services/scan_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise settings store (SharedPreferences)
  final settingsStore = await SettingsStore.create();

  // Initialise auth service and restore any persisted session.
  final authService = AuthService();
  await authService.init();

  runApp(
    MultiProvider(
      providers: [
        // Settings/locale — ChangeNotifier so language switches rebuild the app
        ChangeNotifierProvider<SettingsStore>.value(value: settingsStore),

        // Auth service — source of truth for login state and secret key
        ChangeNotifierProvider<AuthService>.value(value: authService),

        // Account state — wraps AuthService + SettingsStore for feature gates
        ChangeNotifierProvider<AccountState>(
          create: (_) => AccountState(settingsStore, authService),
        ),

        // Local data repository
        Provider<LocalRepository>(
          create: (_) => LocalRepository(),
        ),

        // Services — real OMR scan service using OpenCV pipeline
        Provider<ScanService>(
          create: (_) => OmrScanService(),
        ),
      ],
      child: const MasterJiApp(),
    ),
  );
}
